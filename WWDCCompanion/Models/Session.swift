import GRDBCustomSQLite

class Session: Record {
    let year: Int
    let number: Int
    let collection: String
    let title: String
    let description: String
    let transcript: String
    let iOS: Bool
    let macOS: Bool
    let tvOS: Bool
    let watchOS: Bool
    let sessionURL: URL
    let imageURL: URL
    let videoURL: URL?
    let presentationURL: URL?
    
    var focuses: String {
        var focuses: [String] = []
        if iOS { focuses.append("iOS") }
        if macOS { focuses.append("macOS") }
        if tvOS { focuses.append("tvOS") }
        if watchOS { focuses.append("watchOS") }
        return focuses.joined(separator: ", ")

    }
    
    init(year: Int, number: Int, collection: String, title: String, description: String, transcript: String, iOS: Bool, macOS: Bool, tvOS: Bool, watchOS: Bool, sessionURL: URL, imageURL: URL, videoURL: URL?, presentationURL: URL?) {
        self.year = year
        self.number = number
        self.collection = collection
        self.title = title
        self.description = description
        self.transcript = transcript
        self.iOS = iOS
        self.macOS = macOS
        self.tvOS = tvOS
        self.watchOS = watchOS
        self.sessionURL = sessionURL
        self.imageURL = imageURL
        self.videoURL = videoURL
        self.presentationURL = presentationURL
        super.init()
    }
    
    // MARK: - Record
    
    override class var databaseTableName: String { return "session" }
    
    required init(row: Row) {
        year = row["year"]
        number = row["number"]
        collection = row["collection"]
        title = row["title"]
        description = row["description"]
        transcript = row["transcript"]
        iOS = row["iOS"]
        macOS = row["macOS"]
        tvOS = row["tvOS"]
        watchOS = row["watchOS"]
        sessionURL = row["sessionURL"]
        imageURL = row["imageURL"]
        videoURL = row["videoURL"]
        presentationURL = row["presentationURL"]
        super.init(row: row)
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container["year"] = year
        container["number"] = number
        container["collection"] = collection
        container["title"] = title
        container["description"] = description
        container["transcript"] = transcript
        container["iOS"] = iOS
        container["macOS"] = macOS
        container["watchOS"] = watchOS
        container["tvOS"] = tvOS
        container["sessionURL"] = sessionURL
        container["imageURL"] = imageURL
        container["videoURL"] = videoURL
        container["presentationURL"] = presentationURL
    }
}
