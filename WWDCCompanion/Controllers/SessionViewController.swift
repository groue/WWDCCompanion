//
//  SessionViewController.swift
//  WWDCCompanion
//
//  Created by Gwendal Roué on 15/10/2016.
//  Copyright © 2016 Gwendal Roué. All rights reserved.
//

import UIKit
import WebKit
import Mustache

class SessionViewController: UIViewController {
    private var webView: WKWebView!
    var session: Session!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let config = WKWebViewConfiguration()
        config.allowsAirPlayForMediaPlayback = true
        config.allowsInlineMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = true
        webView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal
        view.addSubview(webView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let transcriptSentences = session
            .transcript
            .characters
            .split(separator: "\n")
            .map { String($0) }
        
        let template = try! Template(named: "session.html")
        let templateValue = Box([
            "sessionImageURL": session.imageURL.absoluteString,
            "title": session.title,
            "focuses": session.focuses,
            "transcriptSentences": transcriptSentences,
            ])
        let html = try! template.render(templateValue)
        webView.loadHTMLString(html, baseURL: nil)
    }
}
