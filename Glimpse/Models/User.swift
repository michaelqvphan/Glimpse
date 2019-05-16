//
//  User.swift
//  Glimpse
//
//  Created by Michael Phan on 5/3/19.
//  Copyright © 2019 Michael Phan. All rights reserved.
//

import Foundation
import FirebaseDatabase.FIRDataSnapshot

// My user Model
// User needs to be encodable and decodable
class User: Codable {
    let uid: String
    let username: String
    
    var isFollowed = false
    
    private static var _current: User?
    
    init( uid: String, username: String ) {
        self.uid = uid
        self.username = username
    }
    
    // Adding a failable initializer
    init?( snapshot: DataSnapshot ) {
        guard let userDict = snapshot.value as? [String: Any],
            let username = userDict["username"] as? String else {
                return nil
            }
        
        self.uid = snapshot.key
        self.username = username
        
        print(self)
    }
    
    // Checks for current user
    static var current: User {
        guard let currentUser = _current else {
            fatalError("Error: User does not exists")
        }
        
        return currentUser
    }
    
    
    // Setting the current User who's signed in
    static func setCurrent(_ user: User, writeToUserDefaults: Bool = false) {
        
        if writeToUserDefaults {
            if let data = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(data, forKey: Constants.UserDefaults.currentUser)
            }
        }
        
        _current = user
    }
}

