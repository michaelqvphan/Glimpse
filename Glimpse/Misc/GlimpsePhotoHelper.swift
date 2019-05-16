//
//  GlimpsePhotoHelper.swift
//  Glimpse
//
//  Created by Michael Phan on 5/5/19.
//  Copyright © 2019 Michael Phan. All rights reserved.
//

import UIKit

class GlimpsePhotoHelper: NSObject {
    var completionHandler: ((UIImage) -> Void)?
    
    // Allows us to either take a photo or upload from photo library
    func presentActionSheet(from viewController: UIViewController) {
        
        let alertController = UIAlertController(title: nil, message: "Where do you to get the picture from?", preferredStyle: .actionSheet)
        
        // If a camera is present, the option should show up
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let takePhotoAction = UIAlertAction(title: "Take Photo", style: .default, handler: { [unowned self] action in
                self.presentImagePickerController(with: .camera, from: viewController)
            })
            
            alertController.addAction(takePhotoAction)
        }
        
        // Photo from photo library
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let uploadPhotoAction = UIAlertAction(title: "Upload From Library", style: .default, handler: { [unowned self] action in
                self.presentImagePickerController(with: .photoLibrary, from: viewController)
            })
            
            alertController.addAction(uploadPhotoAction)
        }
        
        // Allows us to cancel the action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        viewController.present(alertController, animated: true)
    }
    
    func presentImagePickerController(with sourceType: UIImagePickerController.SourceType, from viewController: UIViewController) {
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = sourceType
        imagePickerController.delegate = self
        
        viewController.present(imagePickerController, animated: true)
    }
}

extension GlimpsePhotoHelper: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            completionHandler?(selectedImage)
        }
        
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
