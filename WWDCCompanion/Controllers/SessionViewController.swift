import UIKit
import WebKit
import Mustache

class SessionViewController: UIViewController {
    private var webView: WKWebView!
    var session: Session!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView = WKWebView(frame: view.bounds)
        webView.translatesAutoresizingMaskIntoConstraints = true
        webView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal
        view.addSubview(webView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let transcriptParagraphs = session
            .transcript
            .characters
            .split(separator: "\n")
            .map { String($0) }
        
        let calloutFont = UIFont.preferredFont(forTextStyle: .callout)
        let bodyFont = UIFont.preferredFont(forTextStyle: .body)
        let title1Font = UIFont.preferredFont(forTextStyle: .title1)
        
        let template = try! Template(named: "session.html")
        let templateValue: [String : Any] = [
            "calloutFont": [
                "name": calloutFont.familyName,
                "size": calloutFont.pointSize],
            "bodyFont": [
                "name": bodyFont.familyName,
                "size": bodyFont.pointSize],
            "title1Font": [
                "name": title1Font.familyName,
                "size": title1Font.pointSize],
            "sessionImageURL": session.imageURL.absoluteString,
            "title": session.title,
            "focuses": session.focuses,
            "transcriptParagraphs": transcriptParagraphs,
            ]
        let html = try! template.render(templateValue)
        webView.loadHTMLString(html, baseURL: nil)
    }
}
