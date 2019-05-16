//
//  UserService.swift
//  Glimpse
//
//  Created by Michael Phan on 5/14/19.
//  Copyright © 2019 Michael Phan. All rights reserved.
//

import Foundation
import FirebaseAuth.FIRUser
import FirebaseDatabase

struct UserService {
    
    // Creating a Username for the user and putting it into the database
    static func create(_ firUser: FIRUser, username: String, completeion: @escaping (User?) -> Void ) {
        let userAttributes = ["username": username]
        
        let reference = Database.database().reference().child("users").child(firUser.uid)
        reference.setValue(userAttributes) { (error, reference) in
            if let error = error {
                assertionFailure(error.localizedDescription)
                return completeion(nil)
            }
            
            reference.observeSingleEvent(of: .value, with: { (snapshot) in
                let user = User(snapshot: snapshot)
                completeion(user)
            })
        }
    }
    
    // Returning the user from the database
    static func show(forUID uid: String, completion: @escaping (User?) -> Void ) {
        let reference = Database.database().reference().child("users").child(uid)

        reference.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let user = User(snapshot: snapshot) else {
                return completion(nil)
            }
            
            completion(user)
        })
    }
    
    // Grab all the posts made by a user
    static func posts(for user: User, completion: @escaping ([Post]) -> Void) {
        let reference = Database.database().reference().child("posts").child(user.uid)
        
        reference.observeSingleEvent(of: .value) { (snapshot) in
            guard let snapshot = snapshot.children.allObjects as? [DataSnapshot] else {
                return completion([])
            }
            
            
            // Using dispath groups to wait for all the asynchronous code to complete
            let dispatchGroup = DispatchGroup()
            
            let posts : [Post] = snapshot.reversed().compactMap() {
                guard let post = Post(snapshot: $0) else { return nil }
                
                dispatchGroup.enter()
                
                LikeService.isPostLiked(post) { (isLiked) in
                    post.isLiked = isLiked
                    
                    dispatchGroup.leave()
                }
                
                return post
            }
            
            dispatchGroup.notify(queue: .main, execute: {
                completion(posts)
            })
        }
    }
    
    static func getAllUsers(completion: @escaping ([User]) -> Void) {
        let currentUser = User.current
        // 1
        let reference = Database.database().reference().child("users")
        
        reference.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let snapshot = snapshot.children.allObjects as? [DataSnapshot]
                else { return completion([]) }
            
            let users = snapshot.compactMap(User.init).filter { $0.uid != currentUser.uid }
            
            let dispatchGroup = DispatchGroup()
            users.forEach { (user) in
                dispatchGroup.enter()
                
                FollowService.isUserFollowed(user) { (isFollowed) in
                    user.isFollowed = isFollowed
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main, execute: {
                completion(users)
            })
        })
    }
    
    // Grabbing all the followers of a specific user
    static func getFollowers(for user: User, completion: @escaping ([String]) -> Void) {
        let followersReference = Database.database().reference().child("followers").child(user.uid)
        
        followersReference.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let followersDict = snapshot.value as? [String: Bool] else { return completion([]) }
            
            let followersKeys = Array(followersDict.keys)
            completion(followersKeys)
        })
    }
    
    static func getTimeline(completion: @escaping ([Post]) -> Void) {
        let currentUser = User.current
        
        let timelineReference = Database.database().reference().child("timeline").child(currentUser.uid)
        timelineReference.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let snapshot = snapshot.children.allObjects as? [DataSnapshot]
                else { return completion([]) }
            
            let dispatchGroup = DispatchGroup()
            
            var posts = [Post]()
            
            for postSnap in snapshot {
                guard let postDict = postSnap.value as? [String : Any],
                    let posterUID = postDict["poster_uid"] as? String
                    else { continue }
                
                dispatchGroup.enter()
                
                PostService.getPost(forKey: postSnap.key, posterUID: posterUID) { (post) in
                    if let post = post {
                        posts.append(post)
                    }
                    
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main, execute: {
                completion(posts.reversed())
            })
        })
    }
}
