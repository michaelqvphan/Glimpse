//
//  MainTabBarController.swift
//  Glimpse
//
//  Created by Michael Phan on 5/3/19.
//  Copyright © 2019 Michael Phan. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    // Creating our photo helper instance
    let photoHelper = GlimpsePhotoHelper()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        photoHelper.completionHandler = { image in
            PostService.create(for: image)
        }
        
        delegate = self
        
        // Makes it so the tabs we aren't in are black
        tabBar.unselectedItemTintColor = .lightGray
    }

}

extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        // User the photo helper is the middle button is pressed
        if viewController.tabBarItem.tag == 1 {
            photoHelper.presentActionSheet(from: self)
            return false
        }
        else {
            return true
        }
    }
}
