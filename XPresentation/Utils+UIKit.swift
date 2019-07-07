//
//  Utils+UIKit.swift
//  XPresentation
//
//  Created by kai wang on 2018/10/16.
//  Copyright © 2018 kai wang. All rights reserved.
//

import UIKit

/// make a window with a root VC for presentation
public final class PresentationWindow: UIWindow {
    
    private final class RootViewController: UIViewController {
        override var preferredStatusBarStyle: UIStatusBarStyle { return statusBarStyle }
        
        var statusBarStyle: UIStatusBarStyle = .default
        var presentationWindow: PresentationWindow?
        var present: (() -> Void)?
        
        override func loadView() {
            super.loadView()
            view.backgroundColor = .clear
        }
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            present?()
            present = nil
        }
    }
    
    deinit {
        // FIXME: if not async. iOS 10 will crash.
        DispatchQueue.main.async {
            UIApplication.shared.delegate?.window??.makeKeyAndVisible()
        }
    }
    
    public init(level: UIWindow.Level, preferredStatusBarStyle: UIStatusBarStyle) {
        super.init(frame: UIScreen.main.bounds)
        let root = RootViewController()
        root.statusBarStyle = preferredStatusBarStyle
        
        rootViewController = root
        windowLevel = level
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func sendEvent(_ event: UIEvent) {
        super.sendEvent(event)
        if !isKeyWindow {
            makeKeyAndVisible()
        }
    }
    
    
    /// present vc in another window.
    /// - Parameter vc: ViewController to be presented.
    /// - Parameter animated: should use animation.
    /// - Parameter completion: present completion callback.
    ///
    /// - Important: vc's modalPresentationStyle is default to **fullScreen**. Explicit set it if you want other.
    @discardableResult
    public func present(_ vc: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) -> UIWindow {
        defer {
            makeKeyAndVisible()
        }
        
        if !(objc_getAssociatedObject(self, &UIViewController.XPresentation_HasSetStyleKey) as? Bool ?? false) {
            vc.modalPresentationStyle = .fullScreen
        }
        
        // retain cycle will be resolved after dismiss
        (rootViewController as? RootViewController)?.present = {
            defer {
                self.rootViewController?.present(vc, animated: animated, completion: completion)
            }
            
            //
            final class Trigger: NSObject {
                static var associatedKey = "XPresentation.Trigger.Key"
                var completion: (() -> Void)?
                deinit {
                    completion?()
                }
            }
            
            (self.rootViewController as? RootViewController)?.presentationWindow = self
            let trigger = Trigger()
            trigger.completion = {[weak self] in
                (self?.rootViewController as? RootViewController)?.presentationWindow = nil
            }
            objc_setAssociatedObject(vc, &Trigger.associatedKey, trigger, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        return self
    }
}

extension UIViewController {
    fileprivate static var XPresentation_HasSetStyleKey = "XPresentation.HasSetStyle.Key";
    // swizzle in oc load
    @objc private func XPresentation_setModalPresentationStyle(_ style: UIModalPresentationStyle) {
        XPresentation_setModalPresentationStyle(style)
        objc_setAssociatedObject(self, &UIViewController.XPresentation_HasSetStyleKey, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
