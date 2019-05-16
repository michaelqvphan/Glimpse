//
//  PostActionCell.swift
//  Glimpse
//
//  Created by Michael Phan on 5/15/19.
//  Copyright © 2019 Michael Phan. All rights reserved.
//

import UIKit

protocol PostActionCellDelegate: class {
    func tappedLikeButton(_ likeButton: UIButton, on cell: PostActionCell)
}

class PostActionCell: UITableViewCell {

    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var likeCountLabel: UILabel!
    @IBOutlet weak var postedTimeLabel: UILabel!
    
    weak var delegate: PostActionCellDelegate?
    
    static let height: CGFloat = 46
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    @IBAction func likeButton(_ sender: UIButton) {
        delegate?.tappedLikeButton(sender, on: self)
    }
}
