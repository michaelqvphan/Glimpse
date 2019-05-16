//
//  FindFriendsViewController.swift
//  Glimpse
//
//  Created by Michael Phan on 5/9/19.
//  Copyright © 2019 Michael Phan. All rights reserved.
//

import UIKit
import FirebaseAuth

//protocol FindFriendsViewDelegate: class {
//    func tappedSignOutButton(_ button: UIButton, on findFriendsButton: UINavigationItem)
//}

class FindFriendsViewController: UIViewController {
    
    @IBOutlet weak var friendTableView: UITableView!
    @IBOutlet weak var signOutButton: UIBarButtonItem!
    
//    weak var delegate: FindFriendsViewDelegate?
//    var firebaseAuthHandler: AuthStateDidChangeListenerHandle?
    
    var users = [User]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        friendTableView.tableFooterView = UIView()
        friendTableView.rowHeight = 75
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UserService.getAllUsers { [unowned self] (users) in
            self.users = users
            
            DispatchQueue.main.async {
                self.friendTableView.reloadData()
            }
        }
    }
    
    @IBAction func followButtonTapped(_ sender: UIButton) {
    }
    
//    @IBAction func signOutButtonTapped(_ sender: UIButton) {
//        delegate?.tappedSignOutButton(sender, on: signOutButton)
//    }
    
}

extension FindFriendsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FindFriendsCell") as! FindFriendsCell
        cell.delegate = self
        configure(cell: cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func configure(cell: FindFriendsCell, atIndexPath indexPath: IndexPath) {
        let user = users[indexPath.row]
        
        cell.usernameLabel.text = user.username
        cell.followButton.isSelected = user.isFollowed
    }
}


extension FindFriendsViewController: FindFriendsCellDelegate {
    func tappedFollowButton(_ followButton: UIButton, on cell: FindFriendsCell) {
        guard let indexPath = friendTableView.indexPath(for: cell) else { return }
        
        followButton.isUserInteractionEnabled = false
        let followee = users[indexPath.row]
        
        FollowService.setIsFollowing(!followee.isFollowed, fromCurrentUserTo: followee) { (success) in
            defer {
                followButton.isUserInteractionEnabled = true
            }
            
            guard success else { return }
            
            followee.isFollowed = !followee.isFollowed
            self.friendTableView.reloadRows(at: [indexPath], with: .none)
        }
    }
    
//    func tappedSignOutButton(_ button: UIButton, findFriendsButton: UINavigationItem) {
//
//        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
//
//        let signOutAction = UIAlertAction(title: "Sign Out", style: .default) { _ in
//            print("Logged Out User")
//        }
//
//        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
//
//        alertController.addAction(signOutAction)
//        alertController.addAction(cancelAction)
//
//        present(alertController, animated: true)
//    }
}
