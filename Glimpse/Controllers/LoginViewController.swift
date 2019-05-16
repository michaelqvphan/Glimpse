//
//  LoginViewController.swift
//  Glimpse
//
//  Created by Michael Phan on 5/4/19.
//  Copyright © 2019 Michael Phan. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseUI

// Makes sure to distinguish from a user who has been authenticated and a use from our database
typealias FIRUser = FirebaseAuth.User


class LoginViewController: UIViewController {

    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.bringSubviewToFront(loginButton)
    }
    
    // Sends us the Firebase login page
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        guard let authUI = FUIAuth.defaultAuthUI() else { return }
        
        authUI.delegate = self
        
        // Creating providers to for options of logging in
        let providers : [FUIAuthProvider] = [FUIEmailAuth()]
        authUI.providers = providers
        
        let authViewController = authUI.authViewController()
        self.present(authViewController, animated: true)
    }
}

extension LoginViewController: FUIAuthDelegate {
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        if let error = error {
            assertionFailure("Error signing in: \(error.localizedDescription)")
            return
        }
        
        guard let user = authDataResult?.user else { return }
        
        UserService.show(forUID: user.uid) { (user) in
            
            if let user = user {
                
                // Handling existing users
                User.setCurrent(user, writeToUserDefaults: true)
                            
                let initialViewController = UIStoryboard.initialViewController(for: .main)
                self.view.window?.rootViewController = initialViewController
                self.view.window?.makeKeyAndVisible()
            }
            else {
                
                // Handling new users
                self.performSegue(withIdentifier: "toCreateUsername", sender: self)
            }
        }
    }
}
