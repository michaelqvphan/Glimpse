//
//  CreateUsernameViewController.swift
//  Glimpse
//
//  Created by Michael Phan on 5/6/19.
//  Copyright © 2019 Michael Phan. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class CreateUsernameViewController: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    // Creating our username and sending it to the DB
    @IBAction func nextButtonTapped(_ sender: UIButton) {
        
        guard let firebaseUser = Auth.auth().currentUser,
            let username = usernameTextField.text,
            !username.isEmpty else { return }
        
        UserService.create(firebaseUser, username: username) { (user) in
            guard let user = user else { return }
            
            User.setCurrent(user, writeToUserDefaults: true)
            
            // Once username is created, push us to the main storyboard
            let initialViewController = UIStoryboard.initialViewController(for: .main)
            self.view.window?.rootViewController = initialViewController
            self.view.window?.makeKeyAndVisible()
        }
    }
}
