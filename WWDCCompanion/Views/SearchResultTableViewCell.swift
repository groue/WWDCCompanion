//
//  SessionTableViewCell.swift
//  WWDCCompanion
//
//  Created by Gwendal Roué on 15/10/2016.
//  Copyright © 2016 Gwendal Roué. All rights reserved.
//

import UIKit

class SearchResultTableViewCell: UITableViewCell {
    @IBOutlet private weak var sessionImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var focusesLabel: UILabel!
    @IBOutlet weak var snippetLabel: UILabel!
    
    var sessionImageURL: URL? {
        didSet {
            guard let url = sessionImageURL else {
                sessionImageView.image = nil
                return
            }
            
            if let image = ImageCache.default.cachedImage(for: url) {
                sessionImageView.image = image
            } else {
                sessionImageView.image = nil
                ImageCache.default.loadImage(from: url) { [weak self] image in
                    if self?.sessionImageURL == url {
                        self?.sessionImageView.image = image
                    }
                }
            }
        }
    }
}
