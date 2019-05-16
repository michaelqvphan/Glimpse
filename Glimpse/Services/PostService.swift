//
//  PostService.swift
//  Glimpse
//
//  Created by Michael Phan on 5/15/19.
//  Copyright © 2019 Michael Phan. All rights reserved.
//

import UIKit
import FirebaseStorage
import FirebaseDatabase

struct PostService {
    
    // Uploading an image to the database
    static func create(for image: UIImage) {
        
        let imageRef = StorageReference.newPostImageReference()
        
        StorageService().uploadImage(image, at: imageRef) { (downloadURL) in
            guard let downloadURL = downloadURL else { return }
            
            let urlString = downloadURL.absoluteString
            let aspectHeight = image.aspectHeight
            create(forURLString: urlString, aspectHeight: aspectHeight)
        }
    }
    
    // To create a new post object in the database
    private static func create(forURLString urlString: String, aspectHeight: CGFloat) {
        
        let currentUser = User.current
        let post = Post(imageURL: urlString, imageHeight: aspectHeight)
        
        let rootReference = Database.database().reference()
        let postReference = rootReference.child("posts").child(currentUser.uid).childByAutoId()
        let postKey = postReference.key
        
        UserService.getFollowers(for: currentUser) { (followerUIDs) in
            let timelinePostDict = ["poster_uid": currentUser.uid]
            
            var updatedData: [String: Any] = ["timeline/\(currentUser.uid)/\(postKey!)" : timelinePostDict]
            
            for uid in followerUIDs {
                updatedData["timeline/\(uid)/\(postKey!)"] = timelinePostDict
            }
            
            let postDict = post.valueDict
            
            updatedData["posts/\(currentUser.uid)/\(postKey!)"] = postDict
            rootReference.updateChildValues(updatedData)
        }
    }
    
    static func getPost(forKey postKey: String, posterUID: String, completion: @escaping (Post?) -> Void) {
        let reference = Database.database().reference().child("posts").child(posterUID).child(postKey)
        
        reference.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let post = Post(snapshot: snapshot) else {
                return completion(nil)
            }
            
            LikeService.isPostLiked(post) { (isLiked) in
                post.isLiked = isLiked
                completion(post)
            }
        })
    }
}
