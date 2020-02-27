//
//  AppDelegate.swift
//  MyChatApp
//
//  Created by Jinwoo Kim on 09/02/2019.
//  Copyright © 2019 jinuman. All rights reserved.
//

import UIKit

import SwiftyBeaver
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: - Properties

    var window: UIWindow?
    
    var isEnableAllOrientation: Bool = false
    
    // MARK: - Life cycle
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?)
        -> Bool
    {
        FirebaseApp.configure()
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        
        if let window = window {
            window.rootViewController =
                UINavigationController(rootViewController: MessagesController())
            window.makeKeyAndVisible()
        }
        
        self.customizeNavigationBar()
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?)
        -> UIInterfaceOrientationMask
    {
        if self.isEnableAllOrientation == true {
            return .allButUpsideDown
        }
        return .portrait
    }
    
    // MARK: - Methods
    
    private func customizeNavigationBar() {
        if let navigationController = self.window?.rootViewController as? UINavigationController {
            navigationController.navigationBar.prefersLargeTitles = false
            navigationController.navigationBar.isTranslucent = true
            navigationController.navigationBar.barStyle = UIBarStyle.default
            navigationController.navigationBar.tintColor = UIColor.black    // BarButton color
            navigationController.navigationBar.barTintColor = .white
        }
    }
}
