//
//  LikeService.swift
//  Glimpse
//
//  Created by Michael Phan on 5/15/19.
//  Copyright © 2019 Michael Phan. All rights reserved.
//

import Foundation
import FirebaseDatabase

struct LikeService{
    
    //Creating a like
    static func create(for post: Post, success: @escaping (Bool) -> Void) {
        guard let key = post.key else {
            return success(false)
        }
        
        let currentUID = User.current.uid
        
        // Linking up the users who liked their post
        let likesReference = Database.database().reference().child("postLikes").child(key).child(currentUID)
        likesReference.setValue(true) { (error, _) in
            if let error = error {
                assertionFailure(error.localizedDescription)
                return success(false)
            }
            
            // Allows us to increment the like count of the specific post
            let likeCountReference = Database.database().reference().child("posts").child(post.poster.uid).child(key).child("like_count")
            likeCountReference.runTransactionBlock({ (mutableData) -> TransactionResult in
                let currentCount = mutableData.value as? Int ?? 0
                
                mutableData.value = currentCount + 1
                
                return TransactionResult.success(withValue: mutableData)
            }, andCompletionBlock: { (error, _, _) in
                if let error = error {
                    assertionFailure(error.localizedDescription)
                    success(false)
                }
                else {
                    success(true)
                }
            })
        }
    }
    
    // Deleting a like
    static func delete(for post: Post, success: @escaping (Bool) -> Void) {
        guard let key = post.key else {
            return success(false)
        }
        
        let currentUID = User.current.uid
        
        let likesReference = Database.database().reference().child("postLikes").child(key).child(currentUID)
        
        // Setting the like to nil will delete it off the database
        likesReference.setValue(nil) { (error, _) in
            if let error = error {
                assertionFailure(error.localizedDescription)
                return success(false)
            }
            
            // Allows us to decrement the like count
            let likeCountReference = Database.database().reference().child("posts").child(key).child("likeCount")
            likeCountReference.runTransactionBlock({ (mutableData) -> TransactionResult in
                let currentCount = mutableData.value as? Int ?? 0
                
                mutableData.value = currentCount - 1
                
                return TransactionResult.success(withValue: mutableData)
            }, andCompletionBlock: { (error, _, _) in
                if let error = error {
                    assertionFailure(error.localizedDescription)
                    success(false)
                }
                else {
                    success(true)
                }
            })
        }
    }
    
    
    static func isPostLiked(_ post: Post, byCurrentUserWithCompletion completion: @escaping (Bool) -> Void) {
        guard let postKey = post.key else {
            assertionFailure("Error")
            return completion(false)
        }
        
        let likesRefenece = Database.database().reference().child("postLikes").child(postKey)
        likesRefenece.queryEqual(toValue: nil, childKey: User.current.uid).observeSingleEvent(of: .value, with: { (snapshot) in
            if let _ = snapshot.value as? [String : Bool] {
                completion(true)
            }
            else {
                completion(false)
            }
        })
    }
    
    static func setLike(_ isLiked: Bool, for post: Post, success: @escaping (Bool) -> Void) {
        if isLiked {
            create(for: post, success: success)
        }
        else {
            delete(for: post, success: success)
        }
    }
}
