//
//  Post.swift
//  Glimpse
//
//  Created by Michael Phan on 5/3/19.
//  Copyright © 2019 Michael Phan. All rights reserved.
//

import UIKit
import FirebaseDatabase.FIRDataSnapshot


// My Post model
class Post {
    var key: String?
    var likeCount: Int
    let poster: User
    let imageURL: String
    let imageHeight: CGFloat
    let postDate: Date
    
    var isLiked = false
    
    var valueDict: [String: Any] {
        let createdAgo = postDate.timeIntervalSince1970
        
        let userDict = ["uid" : poster.uid,
                        "username" : poster.username]
        
        return ["image_url" : imageURL,
                "image_height" : imageHeight,
                "created_at" : createdAgo,
                "like_count" : likeCount,
                "poster" : userDict]
    }
    
    init(imageURL: String, imageHeight: CGFloat) {
        self.imageURL = imageURL
        self.imageHeight = imageHeight
        self.postDate = Date()
        self.likeCount = 0
        self.poster = User.current
    }
    
    init?(snapshot: DataSnapshot) {
        guard let valueDict = snapshot.value as? [String: Any],
            let imageURL = valueDict["image_url"] as? String,
            let imageHeight = valueDict["image_height"] as? CGFloat,
            let postDate = valueDict["created_at"] as? TimeInterval,
            let likeCount = valueDict["like_count"] as? Int,
            let userDict = valueDict["poster"] as? [String : Any],
            let uid = userDict["uid"] as? String,
            let username = userDict["username"] as? String
            else { return nil }
        
        self.key = snapshot.key
        self.imageURL = imageURL
        self.imageHeight = imageHeight
        self.postDate = Date(timeIntervalSince1970: postDate)
        self.likeCount = likeCount
        self.poster = User(uid: uid, username: username)
    }
}
