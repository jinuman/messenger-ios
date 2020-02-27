//
//  HasKeyboard.swift
//  MyMessenger
//
//  Created by Jinwoo Kim on 2020/02/27.
//  Copyright © 2020 jinuman. All rights reserved.
//

import UIKit

protocol HasKeyboard: class {
    
    func addKeyboardAppearanceNotification()
    func removeKeyboardNotification()
    func handleKeyboardAppearance(_ notification: Notification)
    
}

extension HasKeyboard where Self: UIViewController {
    func removeKeyboardNotification() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
}
