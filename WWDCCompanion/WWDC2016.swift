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
    
}

struct WWDC2016 {
    static func download() -> Progress {
        let session = URLSession(configuration: .default)
        let progress = Progress()
        
        let listURL = URL(string: "https://developer.apple.com/videos/wwdc2016/")!
        let listTask = session.dataTask(with: listURL) { (data, response, error) in
            guard let data = data else { fatalError("TODO") }
            guard error == nil else { fatalError("TODO") }
            let page = SessionListPage(data: data, baseURL: listURL)
            do {
                let collections = try page.collections()
                progress.totalUnitCount = collections.map { $0.sessions.count }.reduce(0, +)
                for parsedCollection in try page.collections() {
                    for parsedSessionFromListPage in parsedCollection.sessions {
                        let sessionURL = parsedSessionFromListPage.sessionURL
                        guard let number = Int(sessionURL.lastPathComponent) else { fatalError("TODO") }
                        let sessionTask = session.dataTask(with: sessionURL) { (data, response, error) in
                            guard let data = data else { fatalError("TODO") }
                            guard error == nil else { fatalError("TODO") }
                            let page = SessionPage(data: data, baseURL: sessionURL)
                            do {
                                let parsedSessionFromSessionPage = try page.session()
                                try dbQueue.inDatabase { db in
                                    try Session(
                                        year: 2016,
                                        number: number,
                                        collection: parsedCollection.collection,
                                        title: parsedSessionFromSessionPage.title,
                                        description: parsedSessionFromSessionPage.description,
                                        transcript: parsedSessionFromSessionPage.description,
                                        iOS: parsedSessionFromListPage.iOS,
                                        macOS: parsedSessionFromListPage.macOS,
                                        watchOS: parsedSessionFromListPage.watchOS,
                                        tvOS: parsedSessionFromListPage.tvOS,
                                        sessionURL: parsedSessionFromListPage.sessionURL,
                                        videoURL: parsedSessionFromSessionPage.videoURL,
                                        presentationURL: parsedSessionFromSessionPage.presentationURL).save(db)
                                }
                                progress.completedUnitCount += 1
                            } catch { fatalError("TODO") }
                        }
                        sessionTask.resume()
                    }
                }
            } catch { fatalError("TODO") }
        }
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
        let sessionURL: URL
        let macOS: Bool
        let iOS: Bool
        let watchOS: Bool
        let tvOS: Bool
    }
    
    let data: Data
    let baseURL: URL

    func collections() throws -> [ParsedCollection] {
        return try HTMLDocument(data: data)
            .css("li.collection-focus-group")
            .map { collectionElem in
                guard let collection = collectionElem.firstChild(css: "span.font-bold")?.textPresence else { throw ScrapingError() }
                let sessions = try collectionElem.css("li.collection-item section.col-70").map { sessionElem -> ParsedSession in
                    guard let anchorElem = sessionElem.firstChild(css: "a"),
                        let urlString = anchorElem.attributes["href"],
                        let sessionURL = URL(string: urlString, relativeTo: baseURL) else { throw ScrapingError() }
                    guard let focusesElem = sessionElem.firstChild(css: "ul.video-tags li.focus span") else { throw ScrapingError() }
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
                        sessionURL: sessionURL,
                        macOS: focuses.contains("macos"),
                        iOS: focuses.contains("ios"),
                        watchOS: focuses.contains("watchos"),
                        tvOS: focuses.contains("tvos"))
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
        let videoURL: URL
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
        guard !transcript.isEmpty else { throw ScrapingError() }
        var videoURL: URL? = nil
        var presentationURL: URL? = nil
        for resourceElem in supplementsElem.css("li.resources ul.links > li") {
            let resourceKind = resourceElem.attributes["class"]
            switch resourceKind {
            case "video"?:
                guard let anchorElem = resourceElem.firstChild(css: "a"),
                    let urlString = anchorElem.attributes["href"],
                    let URL = URL(string: urlString, relativeTo: baseURL) else { throw ScrapingError() }
                videoURL = URL
            case "document"?:
                guard let anchorElem = resourceElem.firstChild(css: "a"),
                    let urlString = anchorElem.attributes["href"],
                    let URL = URL(string: urlString, relativeTo: baseURL) else { throw ScrapingError() }
                presentationURL = URL
            default:
                break
            }
        }
        guard videoURL != nil else { throw ScrapingError() }
        
        return ParsedSession(
            title: title,
            description: description,
            transcript: transcript,
            videoURL: videoURL!,
            presentationURL: presentationURL)
    }
}
