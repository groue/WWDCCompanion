//
//  ImageCache.swift
//  WWDCCompanion
//
//  Created by Gwendal Roué on 15/10/2016.
//  Copyright © 2016 Gwendal Roué. All rights reserved.
//

import UIKit

class ImageCache {
    static let `default` = ImageCache()
    
    private let session = URLSession(configuration: .default)
    private let cache = NSCache<NSURL, UIImage>()
    
    func cachedImage(for url: URL) -> UIImage? {
        return cache.object(forKey: url as NSURL)
    }
    
    func loadImage(from url: URL, completion: @escaping (UIImage) -> ()) {
        if let image = cache.object(forKey: url as NSURL) {
            completion(image)
            return
        }
        
        let task = session.dataTask(with: url) { [weak self] (data, response, error) in
            if let image = data.flatMap({ UIImage(data: $0) }) {
                DispatchQueue.main.async {
                    self?.cache.setObject(image, forKey: url as NSURL)
                    completion(image)
                }
            }
        }
        task.resume()
    }
}
