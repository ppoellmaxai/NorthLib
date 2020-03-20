//
//  ImageExtensions.swift
//
//  Created by Norbert Thies on 28.02.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit

public extension UIImage {
  
  /// Get Jpeg data from Image with a quality of 50%
  var jpeg: Data? { return jpegData(compressionQuality: 0.5) }
  
  /// Save the image as jpeg data to a file
  func save(to: String) {
    if let data = self.jpeg {
      try! data.write(to: URL(fileURLWithPath: to), options: [])
    }
  }
  
  /// Initialize with animated gif Data
  static func animatedGif(_ data: Data, duration: Double = 2.0) -> UIImage? {
    guard let source =  CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
    var images = [UIImage]()
    let imageCount = CGImageSourceGetCount(source)
    for i in 0 ..< imageCount {
      if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
        images.append(UIImage(cgImage: image))
      }
    }
    return UIImage.animatedImage(with: images, duration: duration)
  }

} // UIImage
