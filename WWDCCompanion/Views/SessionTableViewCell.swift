//
//  SessionTableViewCell.swift
//  WWDCCompanion
//
//  Created by Gwendal Roué on 15/10/2016.
//  Copyright © 2016 Gwendal Roué. All rights reserved.
//

import UIKit

class SessionTableViewCell: UITableViewCell {
    @IBOutlet private weak var sessionImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var focusesLabel: UILabel!
    
    var sessionImageURL: URL? {
        didSet {
            sessionImageView.image = nil
            if let url = sessionImageURL {
                ImageCache.default.loadImage(from: url) { [weak self] image in
                    if self?.sessionImageURL == url {
                        self?.sessionImageView.image = image
                    }
                }
            }
        }
    }
}
