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
    let watchOS: Bool
    let tvOS: Bool
    let sessionURL: URL
    let videoURL: URL
    let presentationURL: URL?
    
    init(year: Int, number: Int, collection: String, title: String, description: String, transcript: String, iOS: Bool, macOS: Bool, watchOS: Bool, tvOS: Bool, sessionURL: URL, videoURL: URL, presentationURL: URL?) {
        self.year = year
        self.number = number
        self.collection = collection
        self.title = title
        self.description = description
        self.transcript = transcript
        self.iOS = iOS
        self.macOS = macOS
        self.watchOS = watchOS
        self.tvOS = tvOS
        self.sessionURL = sessionURL
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
        watchOS = row.value(named: "watchOS")
        tvOS = row.value(named: "tvOS")
        sessionURL = row.value(named: "sessionURL")
        videoURL = row.value(named: "videoURL")
        presentationURL = row.value(named: "presentationURL")
        super.init(row: row)
    }
    
    override var persistentDictionary: [String : DatabaseValueConvertible?] {
        return [
            "year": year,
            "number": number,
            "collection": collection,
            "title": title,
            "description": description,
            "transcript": transcript,
            "iOS": iOS,
            "macOS": macOS,
            "watchOS": watchOS,
            "tvOS": tvOS,
            "sessionURL": sessionURL,
            "videoURL": videoURL,
            "presentationURL": presentationURL,
        ]
    }
}
