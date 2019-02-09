//
//  ViewController.swift
//  MyChatApp
//
//  Created by Jinwoo Kim on 09/02/2019.
//  Copyright © 2019 jinuman. All rights reserved.
//

import UIKit

class MainViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "로그아웃", style: .plain, target: self, action: #selector(handleLogout))
    }
    
    @objc func handleLogout() {
        let loginVC = LoginViewController()
        present(loginVC, animated: true, completion: nil)
    }

}

