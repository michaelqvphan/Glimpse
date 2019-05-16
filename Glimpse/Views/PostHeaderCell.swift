//
//  PostHeaderCell.swift
//  Glimpse
//
//  Created by Michael Phan on 5/8/19.
//  Copyright © 2019 Michael Phan. All rights reserved.
//

import UIKit

class PostHeaderCell: UITableViewCell {
    
    @IBOutlet weak var usernameLabel: UILabel!
    
    static let height: CGFloat = 54
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    @IBAction func optionsButtonTapped(_ sender: UIButton) {
    }
    

}
