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

struct WWDC2016 {
    static func download() {
        let session = URLSession(configuration: .default)
        
        let listURL = URL(string: "https://developer.apple.com/videos/wwdc2016/")!
        let listTask = session.dataTask(with: listURL) { (data, response, error) in
            guard let data = data else {
                fatalError("TODO")
            }
            
            guard error == nil else {
                fatalError("TODO")
            }
            
            do {
                let doc = try HTMLDocument(data: data)
                for collectionElem in doc.css("li.collection-focus-group") {
                    guard let collection = collectionElem
                        .firstChild(css: "span.font-bold")?
                        .textPresence else
                    {
                        fatalError("TODO")
                    }
                    for sessionElem in collectionElem.css("li.collection-item section.col-70") {
                        guard let anchorElem = sessionElem.firstChild(css: "a") else {
                            fatalError("TODO")
                        }
                        guard let urlString = anchorElem.attributes["href"], let url = URL(string: urlString, relativeTo: listURL) else {
                            fatalError("TODO")
                        }
                        guard let title = anchorElem.firstChild(css: "h5")?.textPresence else {
                            fatalError("TODO")
                        }
                        print("\(collection): \(title): \(url.absoluteString)")
                    }
                }
            } catch {
                fatalError("TODO")
            }
        }
        listTask.resume()
    }
}
