//
//  UIKit+MyChatApp.swift
//  MyChatApp
//
//  Created by Jinwoo Kim on 09/02/2019.
//  Copyright © 2019 jinuman. All rights reserved.
//

import UIKit

var imageCache = [String : UIImage]()

extension UIImageView {
    func loadImageUsingCache(with imageUrlString: String) {
        self.image = nil
        
        // check cache for image first
        if let cachedImage = imageCache[imageUrlString] {
            self.image = cachedImage
            return
        }
        
        // otherwise fire off a new download
        guard let url = URL(string: imageUrlString) else {
            return
        }
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            guard let imageData = data else { return }
            let photoImage = UIImage(data: imageData)
            
            imageCache[url.absoluteString] = photoImage
            
            DispatchQueue.main.async {
                self.image = photoImage
            }
        }
        
        task.resume()
    }
}

extension NSObjectProtocol {
    static var className: String {
        return "\(self)"
    }
    var className: String {
        return Self.className
    }
}

extension UIViewController {
    func deinitLog(objectName: String? = nil) {
        #if DEBUG
        print("\n===============================================")
        if let objectName = objectName {
            print("♻️ \(objectName) deinit ♻️")
        } else {
            print("♻️ \(self.className) deinit ♻️")
        }
        print("===============================================\n")
        #endif
    }
    
    static func toNavigationController(isHiddenBar: Bool = false) -> UINavigationController {
        let `self` = self.init()
        let navigationController = UINavigationController(rootViewController: self)
        navigationController.isNavigationBarHidden = isHiddenBar
        navigationController.interactivePopGestureRecognizer?.delegate = nil
        return navigationController
    }
}

extension UITableView {
    
    func setContentInsetWithScrollIndicatorsInset(contentInset: UIEdgeInsets) {
        self.contentInset = contentInset
        self.scrollIndicatorInsets = contentInset
    }
    
    public func registerNibName(_ name: String) {
        register(UINib(nibName: name, bundle: nil), forCellReuseIdentifier: name)
    }
    
    public func dequeueReusableCell<T: UITableViewCell>(
        cellType: T.Type,
        for indexPath: IndexPath)
        -> T
    {
        return dequeueReusableCell(withIdentifier: "\(T.self)", for: indexPath) as? T ?? T()
    }
    
    /**
     다수의 UITableViewCell들을 동시에 register 할 수 있도록 도와준다.
     
     - Parameters:
        - cellTypes: 다수의 UITableViewCell.Type들로 이루어진 Array
     */
    func register(_ cellTypes: [UITableViewCell.Type]) {
        for cellType in cellTypes {
            self.register(cellType, forCellReuseIdentifier: "\(cellType.self)")
        }
    }
}

extension UICollectionView {
    
    func registerNibName(_ name: String) {
        register(UINib(nibName: name, bundle: nil), forCellWithReuseIdentifier: name)
    }
    
    func dequeueReusableCell<T: UICollectionViewCell>(
        cellType: T.Type,
        for indexPath: IndexPath)
        -> T
    {
        return dequeueReusableCell(withReuseIdentifier: "\(T.self)",for: indexPath) as? T ?? T()
    }
    
    /**
     다수의 UICollectionViewCell들을 동시에 register 할 수 있도록 도와준다.
     
     - Parameters:
     - cellTypes: 다수의 UICollectionViewCell.Type들로 이루어진 Array
     */
    func register<T: UICollectionViewCell>(_ cellTypes: [T.Type]) {
        for cellType in cellTypes {
            self.register(cellType, forCellWithReuseIdentifier: "\(cellType.self)")
        }
    }
}

extension UIColor {
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat) {
        self.init(red: r/255, green: g/255, blue: b/255, alpha: 1)
    }
    
    static let loginBGColor = UIColor(r: 210, g: 110, b: 110)
    static let loginButtonColor = UIColor(r: 230, g: 130, b: 130)
    static let bubbleBlue = UIColor(r: 0, g: 137, b: 249)
}

extension UIView {
    
    func addToSuperview(_ superview: UIView?) { superview?.addSubview(self) }
    func addSubviews(_ subviews: [UIView?]) { subviews.forEach { $0?.addToSuperview(self) } }
    func addSubviews(_ subviews: [UIView]) { subviews.forEach { $0.addToSuperview(self) } }
    
    @discardableResult
    func anchor(top: NSLayoutYAxisAnchor?, leading: NSLayoutXAxisAnchor?, bottom: NSLayoutYAxisAnchor?, trailing: NSLayoutXAxisAnchor?, padding: UIEdgeInsets = .zero, size: CGSize = .zero) -> AnchoredConstraints {
        
        translatesAutoresizingMaskIntoConstraints = false
        var anchoredConstraints = AnchoredConstraints()
        
        if let top = top {
            anchoredConstraints.top = topAnchor.constraint(equalTo: top, constant: padding.top)
        }
        
        if let leading = leading {
            anchoredConstraints.leading = leadingAnchor.constraint(equalTo: leading, constant: padding.left)
        }
        
        if let bottom = bottom {
            anchoredConstraints.bottom = bottomAnchor.constraint(equalTo: bottom, constant: -padding.bottom)
        }
        
        if let trailing = trailing {
            anchoredConstraints.trailing = trailingAnchor.constraint(equalTo: trailing, constant: -padding.right)
        }
        
        if size.width != 0 {
            anchoredConstraints.width = widthAnchor.constraint(equalToConstant: size.width)
        }
        
        if size.height != 0 {
            anchoredConstraints.height = heightAnchor.constraint(equalToConstant: size.height)
        }
        
        [anchoredConstraints.top, anchoredConstraints.leading, anchoredConstraints.bottom, anchoredConstraints.trailing, anchoredConstraints.width, anchoredConstraints.height].forEach{ $0?.isActive = true }
        
        return anchoredConstraints
    }
    
    func fillSuperview(padding: UIEdgeInsets = .zero) {
        translatesAutoresizingMaskIntoConstraints = false
        if let superviewTopAnchor = superview?.topAnchor {
            topAnchor.constraint(equalTo: superviewTopAnchor, constant: padding.top).isActive = true
        }
        
        if let superviewBottomAnchor = superview?.bottomAnchor {
            bottomAnchor.constraint(equalTo: superviewBottomAnchor, constant: -padding.bottom).isActive = true
        }
        
        if let superviewLeadingAnchor = superview?.leadingAnchor {
            leadingAnchor.constraint(equalTo: superviewLeadingAnchor, constant: padding.left).isActive = true
        }
        
        if let superviewTrailingAnchor = superview?.trailingAnchor {
            trailingAnchor.constraint(equalTo: superviewTrailingAnchor, constant: -padding.right).isActive = true
        }
    }
    
    func centerInSuperview(size: CGSize = .zero) {
        translatesAutoresizingMaskIntoConstraints = false
        if let superviewCenterXAnchor = superview?.centerXAnchor {
            centerXAnchor.constraint(equalTo: superviewCenterXAnchor).isActive = true
        }
        
        if let superviewCenterYAnchor = superview?.centerYAnchor {
            centerYAnchor.constraint(equalTo: superviewCenterYAnchor).isActive = true
        }
        
        if size.width != 0 {
            widthAnchor.constraint(equalToConstant: size.width).isActive = true
        }
        
        if size.height != 0 {
            heightAnchor.constraint(equalToConstant: size.height).isActive = true
        }
    }
    
    func centerXInSuperview() {
        translatesAutoresizingMaskIntoConstraints = false
        if let superViewCenterXAnchor = superview?.centerXAnchor {
            centerXAnchor.constraint(equalTo: superViewCenterXAnchor).isActive = true
        }
    }
    
    func centerYInSuperview() {
        translatesAutoresizingMaskIntoConstraints = false
        if let centerY = superview?.centerYAnchor {
            centerYAnchor.constraint(equalTo: centerY).isActive = true
        }
    }
    
    func constrainWidth(constant: CGFloat) {
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: constant).isActive = true
    }
    
    func constrainHeight(constant: CGFloat) {
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: constant).isActive = true
    }
}

struct AnchoredConstraints {
    var top, leading, bottom, trailing, width, height: NSLayoutConstraint?
}

extension CGSize {
    
    init(all: CGFloat) {
        self.init(width: all, height: all)
    }
    
}
