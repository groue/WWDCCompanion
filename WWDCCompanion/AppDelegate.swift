//
//  AppDelegate.swift
//  WWDCCompanion
//
//  Created by Gwendal Roué on 14/10/2016.
//  Copyright © 2016 Gwendal Roué. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        try! setupDatabase(application)
        WWDC2016.download()
        return true
    }
}

