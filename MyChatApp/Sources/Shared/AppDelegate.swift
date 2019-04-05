//
//  AppDelegate.swift
//  MyChatApp
//
//  Created by Jinwoo Kim on 09/02/2019.
//  Copyright © 2019 jinuman. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var enableAllOrientation = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        let rootVC = MessagesController()
        if let window = window {
            window.rootViewController = UINavigationController(rootViewController: rootVC)
            window.makeKeyAndVisible()
        }
        
        customizeNavigationBar()
        
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if enableAllOrientation == true {
            return .allButUpsideDown
        }
        return .portrait
    }
    
    private func customizeNavigationBar() {
        if let navController = window?.rootViewController as? UINavigationController {
            navController.navigationBar.prefersLargeTitles = false
            navController.navigationBar.isTranslucent = true
            navController.navigationBar.barStyle = UIBarStyle.default
            navController.navigationBar.tintColor = UIColor.black    // BarButton color
            navController.navigationBar.barTintColor = .white
        }
    }
}

