import GRDBCustomSQLite

class Session : Record {
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
    let videoURL: URL
    let presentationURL: URL?
    
    var focuses: String {
        var focuses: [String] = []
        if iOS { focuses.append("iOS") }
        if macOS { focuses.append("macOS") }
        if tvOS { focuses.append("tvOS") }
        if watchOS { focuses.append("watchOS") }
        return focuses.joined(separator: ", ")

    }
    
    init(year: Int, number: Int, collection: String, title: String, description: String, transcript: String, iOS: Bool, macOS: Bool, tvOS: Bool, watchOS: Bool, sessionURL: URL, imageURL: URL, videoURL: URL, presentationURL: URL?) {
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
    
    override class var databaseTableName: String { return "sessions" }
    
    required init(row: Row) {
        year = row.value(named: "year")
        number = row.value(named: "number")
        collection = row.value(named: "collection")
        title = row.value(named: "title")
        description = row.value(named: "description")
        transcript = row.value(named: "transcript")
        iOS = row.value(named: "iOS")
        macOS = row.value(named: "macOS")
        tvOS = row.value(named: "tvOS")
        watchOS = row.value(named: "watchOS")
        sessionURL = row.value(named: "sessionURL")
        imageURL = row.value(named: "imageURL")
        videoURL = row.value(named: "videoURL")
        presentationURL = row.value(named: "presentationURL")
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
