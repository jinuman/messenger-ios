//
//  LoginRegisterController.swift
//  MyChatApp
//
//  Created by Jinwoo Kim on 09/02/2019.
//  Copyright © 2019 jinuman. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

// Show Login & Register view
class LoginRegisterController: UIViewController {
    
    // MARK:- Properties
    weak var delegate: MessagesControllerDelegate?

    // MARK:- Screen properties
    private let profileImageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "plus_photo").withRenderingMode(.automatic), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(handleAddProfileImage), for: .touchUpInside)
        return button
    }()
    
    private let loginRegisterSegmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Login", "Register"])
        sc.tintColor = .white
        sc.selectedSegmentIndex = 1
        sc.addTarget(self, action: #selector(changeLoginRegisterSegment), for: .valueChanged)
        return sc
    }()
    
    private let inputsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        return view
    }()
    
    private let nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Name"
        return textField
    }()
    
    private let nameSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        return view
    }()
    
    private let emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Email"
        return textField
    }()
    
    private let emailSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        return view
    }()
    
    private let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Password"
        textField.isSecureTextEntry = true
        return textField
    }()
    
    private lazy var loginRegisterButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.system)
        button.backgroundColor = .loginButtonColor
        button.setTitle("Register", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        
        button.addTarget(self, action: #selector(handleLoginRegister), for: .touchUpInside)
        return button
    }()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK:- Variable Constraint HeightAnchors
    private var inputsContainerViewHeightAnchor: NSLayoutConstraint?
    private var nameTextFieldHeightAnchor: NSLayoutConstraint?
    private var emailTextFieldHeightAnchor: NSLayoutConstraint?
    private var passwordTextFieldHeightAnchor: NSLayoutConstraint?
    
    // MARK:- Life cycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .loginBGColor
        setupScreenLayouts()
    }
    
    deinit {
        print("# LoginRegister \(#function)")
    }
    
    // MARK:- Handling methods
    @objc private func handleLoginRegister() {
        switch loginRegisterSegmentedControl.selectedSegmentIndex {
        case 0:
            handleLogin()
        case 1:
            handleRegister()
        default:
            break
        }
    }
    
    // MARK:- Handling methods - Register
    @objc func handleAddProfileImage() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    @objc fileprivate func handleRegister() {
        guard
            let email = emailTextField.text,
            let password = passwordTextField.text,
            let name = nameTextField.text else { return }
        
        // user uid 생성
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] (result: AuthDataResult?, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("@@ createUser: \(error.localizedDescription)")
                return
            }
            print("~ Successfully created user. ")
            
            guard
                let uid = result?.user.uid,
                let uploadData = self.profileImageButton.imageView?.image?.jpegData(compressionQuality: 0.05) else { return }
            
            let imageName = UUID().uuidString
            let storageRef = Storage.storage().reference().child("profile_images").child(imageName)
           
            // Put imageData to storage
            storageRef.putData(uploadData, metadata: nil, completion: { [weak self] (metadata, error) in
                if let error = error {
                    print("@@ Profile image putData error: \(error.localizedDescription)")
                    return
                }
                // url 생성
                storageRef.downloadURL { (url, err) in
                    if let err = err {
                        print(err.localizedDescription)
                        return
                    }
                    guard
                        let self = self,
                        let imageUrl = url?.absoluteString else { return }
                    
                    let values = [
                        "profileImageUrl" : imageUrl,
                        "name" : name,
                        "email" : email
                    ]
                    self.registerUserIntoDatabase(with: uid, values: values)
                }
            })
        }
    }
    
    fileprivate func registerUserIntoDatabase(with uid: String, values: [String: Any]) {
        Database.database().reference().child("users").child(uid).updateChildValues(values) { [weak self] (err, ref) in
            if let err = err {
                print(err.localizedDescription)
                return
            }
            
            guard let self = self else { return }
            
            self.delegate?.fetchUserAndSetupNavBarTitle()
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK:- Handling methods - Login
    @objc private func handleLogin() {
        guard
            let email = emailTextField.text,
            let password = passwordTextField.text else { return }
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (result, error) in
            if let error = error {
                print("@@ singIn: \(error.localizedDescription)")
                return
            }
            guard let self = self else { return }
            print("~ Successfully Login.")
            
            self.delegate?.fetchUserAndSetupNavBarTitle()
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK:- Regarding screen layout method
    fileprivate func setupScreenLayouts() {
        [profileImageButton, loginRegisterSegmentedControl, inputsContainerView, loginRegisterButton].forEach {
            view.addSubview($0)
        }
        
        let guide = view.safeAreaLayoutGuide
        profileImageButton.centerXInSuperview()
        profileImageButton.anchor(top: nil,
                                  leading: nil,
                                  bottom: loginRegisterSegmentedControl.topAnchor,
                                  trailing: nil,
                                  padding: UIEdgeInsets(top: 0, left: 0, bottom: 12, right: 0),
                                  size: CGSize(width: 150, height: 150))
        
        loginRegisterSegmentedControl.centerXInSuperview()
        loginRegisterSegmentedControl.anchor(top: nil,
                                             leading: nil,
                                             bottom: inputsContainerView.topAnchor,
                                             trailing: nil,
                                             padding: UIEdgeInsets(top: 0, left: 0, bottom: 12, right: 0),
                                             size: CGSize(width: 0, height: 36))
        loginRegisterSegmentedControl.widthAnchor.constraint(equalTo: guide.widthAnchor, constant: -24).isActive = true
        
        inputsContainerView.centerInSuperview()
        inputsContainerView.widthAnchor.constraint(equalTo: loginRegisterSegmentedControl.widthAnchor).isActive = true
        inputsContainerViewHeightAnchor = inputsContainerView.heightAnchor.constraint(equalToConstant: 150)
        inputsContainerViewHeightAnchor?.isActive = true
        
        [nameTextField, nameSeparatorView, emailTextField, emailSeparatorView, passwordTextField].forEach {
            inputsContainerView.addSubview($0)
        }
        
        nameTextField.anchor(top: inputsContainerView.topAnchor,
                             leading: inputsContainerView.leadingAnchor,
                             bottom: nil,
                             trailing: inputsContainerView.trailingAnchor,
                             padding: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12))
        nameTextFieldHeightAnchor = nameTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/3)
        nameTextFieldHeightAnchor?.isActive = true
        
        nameSeparatorView.anchor(top: nameTextField.bottomAnchor,
                                 leading: inputsContainerView.leadingAnchor,
                                 bottom: nil,
                                 trailing: inputsContainerView.trailingAnchor,
                                 padding: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12))
        nameSeparatorView.constrainHeight(constant: 1)
        
        emailTextField.anchor(top: nameTextField.bottomAnchor,
                              leading: inputsContainerView.leadingAnchor,
                              bottom: nil,
                              trailing: inputsContainerView.trailingAnchor,
                              padding: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12))
        emailTextFieldHeightAnchor = emailTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/3)
        emailTextFieldHeightAnchor?.isActive = true
        
        emailSeparatorView.anchor(top: emailTextField.bottomAnchor,
                                  leading: inputsContainerView.leadingAnchor,
                                  bottom: nil,
                                  trailing: inputsContainerView.trailingAnchor,
                                  padding: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12))
        emailSeparatorView.constrainHeight(constant: 1)
        
        passwordTextField.anchor(top: emailTextField.bottomAnchor,
                                 leading: inputsContainerView.leadingAnchor,
                                 bottom: nil,
                                 trailing: inputsContainerView.trailingAnchor,
                                 padding: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12))
        passwordTextFieldHeightAnchor = passwordTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/3)
        passwordTextFieldHeightAnchor?.isActive = true
        
        loginRegisterButton.centerXInSuperview()
        loginRegisterButton.anchor(top: inputsContainerView.bottomAnchor,
                                   leading: nil,
                                   bottom: nil,
                                   trailing: nil,
                                   padding: UIEdgeInsets(top: 12, left: 0, bottom: 0, right: 0))
        loginRegisterButton.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        loginRegisterButton.constrainHeight(constant: 50)
    }
    
    @objc private func changeLoginRegisterSegment() {
        let index = loginRegisterSegmentedControl.selectedSegmentIndex
        let isLogin = index == 0
        
        let title = loginRegisterSegmentedControl.titleForSegment(at: index)
        loginRegisterButton.setTitle(title, for: .normal)
        profileImageButton.isHidden = isLogin ? true : false
        
        // login : 2줄, register : 3줄
        inputsContainerViewHeightAnchor?.constant = isLogin ? 100 : 150
        
        // Change height of name, email, password TextField
        nameTextFieldHeightAnchor?.isActive = false
        nameTextFieldHeightAnchor = nameTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor,
                                                                          multiplier: isLogin
                                                                            ? 0
                                                                            : 1/3)
        nameTextFieldHeightAnchor?.isActive = true
        
        emailTextFieldHeightAnchor?.isActive = false
        emailTextFieldHeightAnchor = emailTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor,
                                                                            multiplier: isLogin
                                                                                ? 1/2
                                                                                : 1/3)
        emailTextFieldHeightAnchor?.isActive = true
        
        passwordTextFieldHeightAnchor?.isActive = false
        passwordTextFieldHeightAnchor = passwordTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor,
                                                                                  multiplier: isLogin
                                                                                    ? 1/2
                                                                                    : 1/3)
        passwordTextFieldHeightAnchor?.isActive = true
        
        nameTextField.text = nil
        emailTextField.text = nil
        passwordTextField.text = nil
    }
}

// MARK:- Regarding Image Picker
extension LoginRegisterController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info[.editedImage] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        guard let selectedImage = selectedImageFromPicker else { return }
        
        profileImageButton.setImage(selectedImage.withRenderingMode(.alwaysOriginal), for: .normal)
        profileImageButton.imageView?.contentMode = .scaleAspectFill
        profileImageButton.layer.cornerRadius = profileImageButton.frame.width / 2
        profileImageButton.clipsToBounds = true
        profileImageButton.layer.borderColor = UIColor.gray.cgColor
        profileImageButton.layer.borderWidth = 1
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

