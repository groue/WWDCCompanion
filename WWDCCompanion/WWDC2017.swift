import Foundation
import Fuzi

extension XMLElement {
    var textPresence: String? {
        let text = childNodes(ofTypes: [.Text])
            .map({ $0.rawXML })
            .joined(separator: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if text.characters.count > 0 {
            return text
        } else {
            return nil
        }
    }
}

struct ScrapingError : Error {
    var localizedDescription: String {
        return NSLocalizedString("Scraping Error", comment: "")
    }
}

struct WWDC2017 {
    static func download(completion: @escaping (Error?) -> ()) -> Progress {
        let session = URLSession(configuration: .default)
        let progress = Progress()
        var dataTasks: [URLSessionDataTask] = []
        progress.cancellationHandler = {
            for task in dataTasks {
                task.cancel()
            }
        }
        
        let listURL = URL(string: "https://developer.apple.com/videos/wwdc2017/")!
        let listTask = session.dataTask(with: listURL) { (data, response, error) in
            guard let data = data else {
                progress.cancel()
                DispatchQueue.main.async {
                    completion(error!)
                }
                return
            }
            let page = SessionListPage(data: data, baseURL: listURL)
            do {
                let collections = try page.collections()
                progress.totalUnitCount = Int64(collections.map { $0.sessions.count }.reduce(0, +))
                for parsedCollection in try page.collections() {
                    for parsedSessionFromListPage in parsedCollection.sessions {
                        let sessionURL = parsedSessionFromListPage.sessionURL
                        let sessionTask = session.dataTask(with: sessionURL) { (data, response, error) in
                            guard let data = data else {
                                progress.cancel()
                                DispatchQueue.main.async {
                                    completion(error!)
                                }
                                return
                            }
                            let page = SessionPage(data: data, baseURL: sessionURL)
                            do {
                                let parsedSessionFromSessionPage = try page.session()
                                try dbQueue.inDatabase { db in
                                    let session = Session(
                                        year: 2017,
                                        number: parsedSessionFromListPage.number,
                                        collection: parsedCollection.collection,
                                        title: parsedSessionFromSessionPage.title,
                                        description: parsedSessionFromSessionPage.description,
                                        transcript: parsedSessionFromSessionPage.transcript,
                                        iOS: parsedSessionFromListPage.iOS,
                                        macOS: parsedSessionFromListPage.macOS,
                                        tvOS: parsedSessionFromListPage.tvOS,
                                        watchOS: parsedSessionFromListPage.watchOS,
                                        sessionURL: parsedSessionFromListPage.sessionURL,
                                        imageURL: parsedSessionFromListPage.imageURL,
                                        videoURL: parsedSessionFromSessionPage.videoURL,
                                        presentationURL: parsedSessionFromSessionPage.presentationURL)
                                    try session.save(db)
                                }
                                progress.completedUnitCount += 1
                                if progress.completedUnitCount == progress.totalUnitCount {
                                    DispatchQueue.main.async {
                                        completion(nil)
                                    }
                                }
                            } catch {
                                progress.cancel()
                                DispatchQueue.main.async {
                                    completion(error)
                                }
                            }
                        }
                        dataTasks.append(sessionTask)
                        sessionTask.resume()
                    }
                }
            } catch {
                progress.cancel()
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
        dataTasks.append(listTask)
        listTask.resume()
        return progress
    }
}

private struct SessionListPage {
    struct ParsedCollection {
        let collection: String
        let sessions: [ParsedSession]
    }
    
    struct ParsedSession {
        let number: Int
        let sessionURL: URL
        let imageURL: URL
        let iOS: Bool
        let macOS: Bool
        let tvOS: Bool
        let watchOS: Bool
    }
    
    let data: Data
    let baseURL: URL

    func collections() throws -> [ParsedCollection] {
        return try HTMLDocument(data: data)
            .css("li.collection-focus-group")
            .map { collectionElem in
                guard let collection = collectionElem.firstChild(css: "span.font-bold")?.textPresence else { throw ScrapingError() }
                let sessions = try collectionElem.css("li.collection-item").map { sessionElem -> ParsedSession in
                    guard let anchorElem = sessionElem.firstChild(css: "section.col-70 a"),
                        let urlString = anchorElem.attributes["href"],
                        let sessionURL = URL(string: urlString, relativeTo: baseURL) else { throw ScrapingError() }
                    guard let number = Int(sessionURL.lastPathComponent) else { throw ScrapingError() }
                    guard let imageElem = sessionElem.firstChild(css: "section.col-30 img"),
                        let imageURLString = imageElem.attributes["src"],
                        let imageURL = URL(string: imageURLString, relativeTo: baseURL) else { throw ScrapingError() }
                    guard let focusesElem = sessionElem.firstChild(css: "section.col-70 ul.video-tags li.focus span") else { throw ScrapingError() }
                    let focuses: [String]
                    if let focusText = focusesElem.textPresence {
                        focuses = focusText.characters
                            .split(separator: ",")
                            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                            .map { $0.lowercased() }
                    } else {
                        focuses = []
                    }
                    
                    return ParsedSession(
                        number: number,
                        sessionURL: sessionURL,
                        imageURL: imageURL,
                        iOS: focuses.contains("ios"),
                        macOS: focuses.contains("macos"),
                        tvOS: focuses.contains("tvos"),
                        watchOS: focuses.contains("watchos"))
                }
                return ParsedCollection(collection: collection, sessions: sessions)
        }
    }
}

private struct SessionPage {
    
    struct ParsedSession {
        let title: String
        let description: String
        let transcript: String
        let videoURL: URL?
        let presentationURL: URL?
    }
    
    let data: Data
    let baseURL: URL
    
    func session() throws -> ParsedSession {
        let doc = try HTMLDocument(data: data)
        guard let supplementsElem = doc.firstChild(css: "ul.supplements") else { throw ScrapingError() }
        guard let detailsElem = supplementsElem.firstChild(css: "li.details") else { throw ScrapingError() }
        guard let title = detailsElem.firstChild(css: "h1")?.textPresence else { throw ScrapingError() }
        guard let description = detailsElem.firstChild(css: "p")?.textPresence else { throw ScrapingError() }
        guard let transcriptElem = supplementsElem.firstChild(css: "li.transcript") else { throw ScrapingError() }
        let transcript = transcriptElem
            .css("p")
            .map { paragraphElem in
                paragraphElem.css("span").flatMap { $0.textPresence }.joined(separator: " ")
            }
            .joined(separator: "\n\n")
        var videoURL: URL? = nil
        var presentationURL: URL? = nil
        for resourceElem in supplementsElem.css("li.supplement ul.links > li") {
            let resourceKind = resourceElem.attributes["class"]
            switch resourceKind {
            case "download"?:
                if let anchorElem = resourceElem.firstChild(css: "a"),
                    let urlString = anchorElem.attributes["href"],
                    let URL = URL(string: urlString, relativeTo: baseURL)
                {
                    videoURL = URL
                }
            case "document"?:
                if let anchorElem = resourceElem.firstChild(css: "a"),
                    let urlString = anchorElem.attributes["href"],
                    let URL = URL(string: urlString, relativeTo: baseURL)
                {
                    presentationURL = URL
                }
            default:
                break
            }
        }
        
        return ParsedSession(
            title: title,
            description: description,
            transcript: transcript,
            videoURL: videoURL,
            presentationURL: presentationURL)
    }
}
