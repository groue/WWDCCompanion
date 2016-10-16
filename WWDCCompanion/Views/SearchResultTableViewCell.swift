import UIKit

class SearchResultTableViewCell: UITableViewCell {
    @IBOutlet private weak var sessionImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var focusesLabel: UILabel!
    @IBOutlet weak var snippetLabel: UILabel!
    
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
