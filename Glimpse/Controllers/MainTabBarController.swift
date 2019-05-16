//
//  MainTabBarController.swift
//  Glimpse
//
//  Created by Michael Phan on 5/15/19.
//  Copyright © 2019 Michael Phan. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        tabBar.unselectedItemTintColor = .black
    }

}

extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        return true
    }
}
