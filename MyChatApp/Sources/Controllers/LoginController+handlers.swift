//
//  LoginController+handlers.swift
//  MyChatApp
//
//  Created by Jinwoo Kim on 15/02/2019.
//  Copyright © 2019 jinuman. All rights reserved.
//

import UIKit
import Firebase

extension LoginController {
    @objc func handleSelectProfileImageView() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
    
    @objc func handleRegister() {
        // Form check.
        guard
            let email = emailTextField.text,
            let password = passwordTextField.text,
            let name = nameTextField.text
            else {
                print("@@ Register email or password form is not valid..")
                return
        }
        
        // Now Form is correct..Then..create user
        Auth.auth().createUser(withEmail: email, password: password) { [weak self](result: AuthDataResult?, error) in
            guard let self = self else {
                return
            }
            
            if error != nil {
                print("@@ createUser: \(error?.localizedDescription ?? "")")
            }
            
            if result?.user != nil {
                print("!! Auth user success !!")
            }
            
            guard let uid = result?.user.uid else {
                return
            }
            
            // Successfully authenticated user.
            let imageName = UUID().uuidString
            
            let storageRef = Storage.storage().reference().child("profile_images").child("\(imageName).png")
            guard let uploadData = self.profileImageView.image?.jpegData(compressionQuality: 0.1) else {
                return
            }
            // first upload images to storage..
            storageRef.putData(uploadData, metadata: nil, completion: { [weak self] (metadata, error) in
                if error != nil {
                    print("@@ putData: \(error?.localizedDescription ?? "")")
                    return
                }
                // url 생성
                storageRef.downloadURL(completion: { (url, error) in
                    if error != nil { 
                        print("@@ downloadURL: \(error?.localizedDescription ?? "")")
                        return
                    }
                    guard let urlString = url?.absoluteString else {
                        return
                    }
                    // values 생성
                    let values = ["profileImageUrl": urlString, "name": name, "email": email]
                    self?.registerUserIntoDatabaseWithUid(uid: uid, values: values)
                })
                
            })
        }
    }
    
    fileprivate func registerUserIntoDatabaseWithUid(uid: String, values: [String: Any]) {
        let ref: DatabaseReference = Database.database().reference()
        let usersReference = ref.child("users").child(uid)
        usersReference.updateChildValues(values, withCompletionBlock: { [weak self] (err, ref) in
            if let err = err {
                print("@@ Register -> updateChildValues: \(err.localizedDescription)")
                return
            } else {
                print("!! Register Success !!")
            }
            
            // If register success.. then setup navbar with registered user..
            
            // Don't need full of this call..
//            self?.messagesController?.fetchUserAndSetupNavBarTitle()
            // Instead
//            self?.messagesController?.navigationItem.title = values["name"] as? String
            guard let user = User(dictionary: values) else {
                return
            }
            self?.delegate?.setupNavBarWithUser(user: user)
            
            self?.dismiss(animated: true, completion: nil)
        })
    }
   
}

// MARK:- Regarding imagePicker
extension LoginController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info[.editedImage] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        if let selectedImage = selectedImageFromPicker {
            profileImageView.image = selectedImage
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
