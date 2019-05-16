//
//  HomeViewController.swift
//  Glimpse
//
//  Created by Michael Phan on 5/8/19.
//  Copyright © 2019 Michael Phan. All rights reserved.
//

import UIKit
import Kingfisher

class HomeViewController: UIViewController {

    @IBOutlet var homeTableView: UITableView!
    
    var posts = [Post]()
    
    // Creating a data formatter to help with the time stamp of the photos posted
    let timeStampCreator: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        return dateFormatter
    }()
    
    // Creating an object that will us to refresh the page
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTableView()
        reloadTimeline()
    }

    // Exposing this method to Objective C
    @objc func reloadTimeline() {
        UserService.getTimeline { (posts) in
            self.posts = posts
            
            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
            }
            
            self.homeTableView.reloadData()
        }
    }
    
    func configureTableView() {
        homeTableView.tableFooterView = UIView()
        homeTableView.separatorStyle = .none
        
        // Allows us to drag down from the top to refresh
        refreshControl.addTarget(self, action: #selector(reloadTimeline), for: .valueChanged)
        homeTableView.addSubview(refreshControl)
    }

}

// Consist mainly of 3 sections: Header cell, Image cell, Action cell
extension HomeViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
}


// Setting the data for the three sections
extension HomeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            return PostHeaderCell.height
            
        case 1:
            let post = posts[indexPath.section]
            print(post.imageHeight)
            return post.imageHeight
            
        case 2:
            return PostActionCell.height
            
        default:
            fatalError()
        }
    }
    
    // Getting the approiate information for each section
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = posts[indexPath.section]
        
        switch indexPath.row {
        case 0:
            let cell = homeTableView.dequeueReusableCell(withIdentifier: "PostHeaderCell") as! PostHeaderCell
            cell.usernameLabel.text = post.poster.username
            
            return cell
            
        case 1:
            let cell = homeTableView.dequeueReusableCell(withIdentifier: "PostImageCell") as! PostImageCell
            let imageURL = URL(string: post.imageURL)
            cell.postImageView.kf.setImage(with: imageURL)
            
            return cell
            
        case 2:
            let cell = homeTableView.dequeueReusableCell(withIdentifier: "PostActionCell") as! PostActionCell
            cell.delegate = self
            configureCell(cell, with: post)
            return cell
            
        default:
            fatalError("Error: unexpected indexPath.")
        }
    }
    
    func configureCell(_ cell: PostActionCell, with post: Post) {
        cell.postedTimeLabel.text = timeStampCreator.string(from: post.postDate)
        cell.likeButton.isSelected = post.isLiked
        cell.likeCountLabel.text = "\(post.likeCount) likes"
    }
}

// Allows us to use the Like Button to change the value from the database
extension HomeViewController: PostActionCellDelegate {
    func tappedLikeButton(_ likeButton: UIButton, on cell: PostActionCell) {
        
        guard let indexPath = homeTableView.indexPath(for: cell) else { return }
        
        likeButton.isUserInteractionEnabled = false
        let post = posts[indexPath.section]
        
        LikeService.setLike(!post.isLiked, for: post) { (success) in
            defer {
                likeButton.isUserInteractionEnabled = true
            }
            
            guard success else { return }
            
            if !post.isLiked {
                post.likeCount += 1
            }
            else {
                post.likeCount -= 1
            }
            
            post.isLiked = !post.isLiked
            
            guard let cell = self.homeTableView.cellForRow(at: indexPath) as? PostActionCell else {
                return
            }
            
            DispatchQueue.main.async {
                self.configureCell(cell, with: post)
            }
        }
    }
}
