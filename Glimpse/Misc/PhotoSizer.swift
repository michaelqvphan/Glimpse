//
//  UIImage+Size.swift
//  Glimpse
//
//  Created by Michael Phan on 5/8/19.
//  Copyright © 2019 Michael Phan. All rights reserved.
//

import UIKit

// Helps size the photo 
extension UIImage {
    var aspectHeight: CGFloat {
        let heightRatio = size.height / 736
        let widthRatio = size.width / 414
        let aspectRatio = fmax(heightRatio, widthRatio)
        
        return size.height/aspectRatio
    }
}

