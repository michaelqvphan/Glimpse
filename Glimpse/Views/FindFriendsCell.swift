//
//  FindFriendsCell.swift
//  Glimpse
//
//  Created by Michael Phan on 5/9/19.
//  Copyright © 2019 Michael Phan. All rights reserved.
//

import UIKit

protocol FindFriendsCellDelegate: class {
    func tappedFollowButton(_ followButton: UIButton, on cell: FindFriendsCell)
}

class FindFriendsCell: UITableViewCell {
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    
    weak var delegate: FindFriendsCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Adding some styling for the Friend Cells
        followButton.layer.borderColor = UIColor.lightGray.cgColor
        followButton.layer.borderWidth = 2
        followButton.layer.cornerRadius = 8
        followButton.clipsToBounds = true
        
        // Allowing toggle for if the follow button is clicked
        followButton.setTitle("Follow", for: .normal)
        followButton.setTitle("Following", for: .selected)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func followButtonTapped(_ sender: UIButton) {
        delegate?.tappedFollowButton(sender, on: self)
    }
}
