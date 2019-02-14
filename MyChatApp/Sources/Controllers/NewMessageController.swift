//
//  NewMessageController.swift
//  MyChatApp
//
//  Created by Jinwoo Kim on 13/02/2019.
//  Copyright © 2019 jinuman. All rights reserved.
//

import UIKit
import Firebase

class NewMessageController: UITableViewController {

    private let cellId = "cellId"
    
    private var users = [User]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.plain,
                                                           target: self, action: #selector(handleCancel))
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        fetchUser()
    }
    
    private func fetchUser() {
        Database.database().reference().child("users").observe(DataEventType.childAdded) { [weak self] (snapshot: DataSnapshot) in
            
            guard
                let dictionary = snapshot.value as? [String: Any],
                let user = User(dictionary: dictionary) else { return }
            
            self?.users.append(user)
            
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }

    @objc private func handleCancel() {
        dismiss(animated: true, completion: nil
        )
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // need dequeue cells for memory efficiency
//        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellId)
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        
        let user = users[indexPath.row]
        
        cell.textLabel?.text = user.name
        cell.detailTextLabel?.text = user.email
        
        return cell
    }
    
}

class UserCell: UITableViewCell {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
