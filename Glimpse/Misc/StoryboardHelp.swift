//
//  Storyboard+Utility.swift
//  Glimpse
//
//  Created by Michael Phan on 5/8/19.
//  Copyright © 2019 Michael Phan. All rights reserved.
//

import UIKit


// Used to help switching to the login and main storyboard
extension UIStoryboard {
    enum GlimpseType: String {
        case main
        case login
        
        var filename: String {
            return rawValue.capitalized
        }
    }
    
    convenience init(type: GlimpseType, bundle: Bundle? = nil) {
        self.init(name: type.filename, bundle: bundle)
    }
    
    static func initialViewController(for type: GlimpseType) -> UIViewController {
        let storybord = UIStoryboard(type: type)
        guard let initialViewController = storybord.instantiateInitialViewController() else {
            fatalError("Could not load initial view controller")
        }
        
        return initialViewController
    }
}
