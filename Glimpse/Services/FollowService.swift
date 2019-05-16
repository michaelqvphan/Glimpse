//
//  FollowService.swift
//  Glimpse
//
//  Created by Michael Phan on 5/15/19.
//  Copyright © 2019 Michael Phan. All rights reserved.
//

import Foundation
import FirebaseDatabase

struct FollowService {
    
    private static func followUser(_ user: User, forCurrentUserWithSuccess success: @escaping (Bool) -> Void) {
        let currentUID = User.current.uid
        let followData = ["followers/\(user.uid)/\(currentUID)" : true,
                          "following/\(currentUID)/\(user.uid)" : true]
        
        let reference = Database.database().reference()
        reference.updateChildValues(followData) { (error, _) in
            if let error = error {
                assertionFailure(error.localizedDescription)
                success(false)
            }
            
            UserService.posts(for: user) { (posts) in
                let postKeys = posts.compactMap { $0.key }
                
                var followData = [String: Any] ()
                let timelinePostDict = ["poster_uid": user.uid]
                postKeys.forEach { followData["timeline/\(currentUID)/\($0)"] = timelinePostDict }
                
                reference.updateChildValues(followData, withCompletionBlock: { (error, ref) in
                    if let error = error {
                        assertionFailure(error.localizedDescription)
                    }
                    
                    success(error == nil)
                })
            }
        }
    }
    
    // Sets the child data for NSNull() to get rid of data.
    private static func unfollowUser(_ user: User, forCurrentUserWithSuccess success: @escaping (Bool) -> Void) {
        let currentUID = User.current.uid
        let followData = ["followers/\(user.uid)/\(currentUID)" : NSNull(),
                          "following/\(currentUID)/\(user.uid)" : NSNull()]
        
        let reference = Database.database().reference()
        reference.updateChildValues(followData) { (error, reference) in
            if let error = error {
                assertionFailure(error.localizedDescription)
            }
            
            UserService.posts(for: user) { (posts) in
                let postKeys = posts.compactMap { $0.key }
                
                var unfollowData = [String: Any] ()
                postKeys.forEach { unfollowData["timeline/\(currentUID)/\($0)"] = NSNull() }
                
                reference.updateChildValues(unfollowData, withCompletionBlock: { (error, ref) in
                    if let error = error {
                        assertionFailure(error.localizedDescription)
                    }
                    
                    success(error == nil)
                })
            }
        }
    }
    
    static func setIsFollowing(_ isFollowing: Bool, fromCurrentUserTo followee: User, success: @escaping (Bool) -> Void) {
        if isFollowing {
            followUser(followee, forCurrentUserWithSuccess: success)
        } else {
            unfollowUser(followee, forCurrentUserWithSuccess: success)
        }
    }
    
    static func isUserFollowed(_ user: User, byCurrentUserWithCompletion completion: @escaping (Bool) -> Void) {
        let currentUID = User.current.uid
        let reference = Database.database().reference().child("followers").child(user.uid)
        
        reference.queryEqual(toValue: nil, childKey: currentUID).observeSingleEvent(of: .value, with: {(snapshot)  in
            if let _ = snapshot.value as? [String: Bool ] {
                completion(true)
            }
            else {
                completion(false)
            }
        })
    }
}
