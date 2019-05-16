//
//  Services.swift
//  
//
//  Created by Michael Phan on 5/16/19.
//

import Foundation
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth.FIRUser

struct StorageService {
    func uploadImage(_ image: UIImage, at reference: StorageReference, completion: @escaping (URL?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.1)
            else {
                return completion(nil)
        }
        
        reference.putData(imageData, metadata: nil, completion: { (metadata, error) in
            if let error = error {
                assertionFailure(error.localizedDescription)
                return completion(nil)
            }
            
            reference.downloadURL(completion: { (url, error) in
                if let error = error {
                    assertionFailure(error.localizedDescription)
                    return completion(nil)
                }
                completion(url)
            })
        })
    }
}

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


