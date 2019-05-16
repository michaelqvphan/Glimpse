//
//  StorageReference+Post.swift
//  Glimpse
//
//  Created by Michael Phan on 5/7/19.
//  Copyright © 2019 Michael Phan. All rights reserved.
//

import Foundation
import FirebaseStorage

 // Helps format how the images are stored in the DB
extension StorageReference {
    static let dataFormater = ISO8601DateFormatter()
    
    static func newPostImageReference() -> StorageReference {
        let uid = User.current.uid
        let timestamp = dataFormater.string(from: Date())
        
        return Storage.storage().reference().child("images/posts/\(uid)/\(timestamp).jpg")
    }
}
