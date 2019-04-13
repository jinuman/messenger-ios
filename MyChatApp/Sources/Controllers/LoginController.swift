//
//  LoginController.swift
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
class LoginController: UIViewController {
    
    // MARK:- Properties
    let messagesController: MessagesController = {
        let vc = MessagesController()
        return vc
    }()
    
    weak var delegate: MessagesControllerDelegate?

    // MARK:- Screen properties
    private let profileImageButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(#imageLiteral(resourceName: "plus_photo").withRenderingMode(.automatic), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(handleSelectProfileImage), for: .touchUpInside)
        return button
    }()
    
    private let loginRegisterSegmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Login", "Register"])
        sc.translatesAutoresizingMaskIntoConstraints = false
        sc.tintColor = .white
        sc.selectedSegmentIndex = 1
        sc.addTarget(self, action: #selector(handleLoginRegisterChange), for: .valueChanged)
        return sc
    }()
    
    let inputsContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        return view
    }()
    
    let nameTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Name"
        return textField
    }()
    
    let nameSeparatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        return view
    }()
    
    let emailTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Email"
        return textField
    }()
    
    let emailSeparatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        return view
    }()
    
    let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Password"
        textField.isSecureTextEntry = true
        return textField
    }()
    
    lazy var loginRegisterButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .loginButtonColor
        button.setTitle("Register", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        
        button.addTarget(self, action: #selector(handleLoginRegister), for: .touchUpInside)
        return button
    }()
    
    // MARK:- Variable HeightAnchors
    private var inputsContainerViewHeightAnchor: NSLayoutConstraint?
    private var nameTextFieldHeightAnchor: NSLayoutConstraint?
    private var emailTextFieldHeightAnchor: NSLayoutConstraint?
    private var passwordTextFieldHeightAnchor: NSLayoutConstraint?
    
    // MARK:- View Life cycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .bgColor
        
        [profileImageButton, loginRegisterSegmentedControl, inputsContainerView, loginRegisterButton].forEach {
            view.addSubview($0)
        }
        
        setupProfileImageButton()
        setupLoginRegisterSegmentedControl()
        setupInputsContainerView()
        setupRegisterButton()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK:- Event Handling methods
    @objc private func handleLoginRegisterChange() {
        let index = loginRegisterSegmentedControl.selectedSegmentIndex
        let isLogin = index == 0
        
        let title = loginRegisterSegmentedControl.titleForSegment(at: index)
        loginRegisterButton.setTitle(title, for: .normal)
        profileImageButton.isHidden = isLogin ? true : false
        
        // Change height of inputsContainerView.
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
    }
    
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
    
    @objc private func handleLogin() {
        guard
            let email = emailTextField.text,
            let password = passwordTextField.text
            else {
                print("@@ Login: Form is not valid")
                return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            if let error = error {
                print("@@ signIn: \(error.localizedDescription)")
                return
            }
            if result?.user != nil {
                print("!! Login Success !!")
            }
            
            self.delegate?.fetchUserAndSetupNavBarTitle()
            
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK:- Setting up layout methods
    // Constraints need x, y, width, height
    private func setupProfileImageButton() {
        profileImageButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        profileImageButton.bottomAnchor.constraint(equalTo: loginRegisterSegmentedControl.topAnchor, constant: -12).isActive = true
        profileImageButton.widthAnchor.constraint(equalToConstant: 150).isActive = true
        profileImageButton.heightAnchor.constraint(equalTo: profileImageButton.widthAnchor, multiplier: 1).isActive = true
    }
    
    private func setupLoginRegisterSegmentedControl() {
        loginRegisterSegmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginRegisterSegmentedControl.bottomAnchor.constraint(equalTo: inputsContainerView.topAnchor, constant: -12).isActive = true
        loginRegisterSegmentedControl.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        loginRegisterSegmentedControl.heightAnchor.constraint(equalToConstant: 36).isActive = true
    }
    
    private func setupInputsContainerView() {
        inputsContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        inputsContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        inputsContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -24).isActive = true
        inputsContainerViewHeightAnchor = inputsContainerView.heightAnchor.constraint(equalToConstant: 150)
        inputsContainerViewHeightAnchor?.isActive = true
        
        inputsContainerView.addSubview(nameTextField)
        inputsContainerView.addSubview(nameSeparatorView)
        inputsContainerView.addSubview(emailTextField)
        inputsContainerView.addSubview(emailSeparatorView)
        inputsContainerView.addSubview(passwordTextField)
        
        nameTextField.leadingAnchor.constraint(equalTo: inputsContainerView.leadingAnchor, constant: 12).isActive = true
        nameTextField.topAnchor.constraint(equalTo: inputsContainerView.topAnchor).isActive = true
        nameTextField.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor, constant: -24).isActive = true
        nameTextFieldHeightAnchor = nameTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/3)
        nameTextFieldHeightAnchor?.isActive = true
        
        nameSeparatorView.leadingAnchor.constraint(equalTo: inputsContainerView.leadingAnchor).isActive = true
        nameSeparatorView.topAnchor.constraint(equalTo: nameTextField.bottomAnchor).isActive = true
        nameSeparatorView.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        nameSeparatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        emailTextField.leadingAnchor.constraint(equalTo: inputsContainerView.leadingAnchor, constant: 12).isActive = true
        emailTextField.topAnchor.constraint(equalTo: nameTextField.bottomAnchor).isActive = true
        emailTextField.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor, constant: -24).isActive = true
        emailTextFieldHeightAnchor = emailTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/3)
        emailTextFieldHeightAnchor?.isActive = true
        
        emailSeparatorView.leadingAnchor.constraint(equalTo: inputsContainerView.leadingAnchor).isActive = true
        emailSeparatorView.topAnchor.constraint(equalTo: emailTextField.bottomAnchor).isActive = true
        emailSeparatorView.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        emailSeparatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        passwordTextField.leadingAnchor.constraint(equalTo: inputsContainerView.leadingAnchor, constant: 12).isActive = true
        passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor).isActive = true
        passwordTextField.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor, constant: -24).isActive = true
        passwordTextFieldHeightAnchor = passwordTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/3)
        passwordTextFieldHeightAnchor?.isActive = true
    }
    
    private func setupRegisterButton() {
        loginRegisterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginRegisterButton.topAnchor.constraint(equalTo: inputsContainerView.bottomAnchor, constant: 12).isActive = true
        loginRegisterButton.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        loginRegisterButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
}

// MARK:- Register 부분

extension LoginController {
    
    // MARK:- Event handling methods
    @objc func handleSelectProfileImage() {
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
            
            let storageRef = Storage.storage().reference().child("profile_images").child(imageName)
            guard let uploadData = self.profileImageButton.imageView?.image?.jpegData(compressionQuality: 0.05) else {
                return
            }
            // first upload images to storage..
            storageRef.putData(uploadData, metadata: nil, completion: { [weak self] (metadata, error) in
                if let error = error {
                    print("@@ Profile image upload error: \(error.localizedDescription)")
                    return
                }
                // url 생성
                storageRef.downloadURL(completion: { (url, err) in
                    if let err = err {
                        print("@@ download url error: \(err.localizedDescription)")
                        return
                    }
                    guard let imageUrl = url?.absoluteString else { return }
                    // values 생성
                    let values = [
                        "profileImageUrl" : imageUrl,
                        "name" : name,
                        "email" : email
                    ]
                    self?.registerUserIntoDatabaseWithUid(uid: uid, values: values)
                })
            })
        }
    }
    
    fileprivate func registerUserIntoDatabaseWithUid(uid: String, values: [String: Any]) {
        let usersRef = Database.database().reference().child("users").child(uid)
        usersRef.updateChildValues(values, withCompletionBlock: { [weak self] (err, ref) in
            guard
                let self = self,
                let name = values["name"] as? String else {
                    return
            }
            if let err = err {
                print("@@ Register -> updateChildValues: \(err.localizedDescription)")
                return
            } else {
                print("!! Register Success !!")
            }
            // Should refresh main UI with current user.
            
            // Don't need full of this call..
            //            self?.messagesController?.fetchUserAndSetupNavBarTitle()
            // Instead
            self.delegate?.setupNavBar(with: name)
            //            self.messagesController.navigationItem.title = values["name"] as? String
            //            guard let user = User(dictionary: values) else {
            //                return
            //            }
            //            self.delegate?.setupNavBarWithUser(user: user)
            
            self.dismiss(animated: true, completion: nil)
        })
    }
    
}

// MARK:- Extension regarding UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension LoginController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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

