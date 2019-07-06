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
        var statusBarStyle: UIStatusBarStyle = .default
        override var preferredStatusBarStyle: UIStatusBarStyle { return statusBarStyle }
        var presentationWindow: PresentationWindow?
        
        override func loadView() {
            super.loadView()
            view.backgroundColor = .clear
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
    
    @discardableResult
    public func present(_ vc: UIViewController, async: Bool = true, animated: Bool = true, completion: (() -> Void)? = nil) -> UIWindow {
        makeKeyAndVisible()
        
        let present = {
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
        
        if async {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1/60) { present() }
        } else {
            present()
        }
        
        return self
    }
    
    /**
     Nav should setup rootViewController before present.
     Nav's rootViewController should be transparent, typically `UIViewController()` is fine.
     */
    @discardableResult
    public func presentTransparentRootNav<Nav: UINavigationController>(
        _ nav: Nav,
        delegation: (Nav, PresentationNavDelegate) -> Void = { $0.delegate = $1 },
        push vc: UIViewController,
        async: Bool = true, animated: Bool = true, completion: (() -> Void)? = nil) -> UIWindow {
        
        assert(nav.viewControllers.count == 1, "must setup rootViewController before present NavigationController!")
        let root = nav.viewControllers.first!
        
        // adjust root
        root.view.backgroundColor = UIColor(white: 0, alpha: 0.1)
        root.view.alpha = 0
        
        // config nav
        let defaultDelegate = PresentationNavDelegate()
        defaultDelegate.pushCompletion = completion
        delegation(nav, defaultDelegate)
        objc_setAssociatedObject(nav, &PresentationNavDelegate.Key, defaultDelegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // finally, do present without animation & push
        present(nav, async: async, animated: false, completion: {[weak nav] in
            nav?.pushViewController(vc, animated: animated)
        })
        
        return self
    }
}


public final class PresentationNavDelegate: NSObject, UINavigationControllerDelegate {
    static var Key = "Presentation.NavigationControllerDelegate.key"
    
    public weak var outerDelegate: UINavigationControllerDelegate?
    
    fileprivate var pushCompletion: (() -> Void)?
    private var didPush = false
    private var distinct: [String: Bool] = [:]
    //
    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        guard !(distinct[#function] ?? false) else { return }
        distinct[#function] = true
        defer { distinct[#function] = false }
        outerDelegate?.navigationController?(navigationController, willShow: viewController, animated: animated)
        
        guard let root = navigationController.viewControllers.first else { return }
        guard let coo = navigationController.transitionCoordinator, animated else { return }
        
        let transitionView = navigationController.navigationBar
        if viewController === root {
            if didPush {
                root.view.alpha = 1
                coo.animate(
                    alongsideTransition: { _ -> Void in
                        transitionView.transform = CGAffineTransform(translationX: transitionView.frame.width, y: 0)
                        root.view.alpha = 0
                },
                    completion: { context -> Void in
                        if context.isCancelled {
                            transitionView.transform = .identity
                            root.view.alpha = 1
                        }
                })
            } else {
                transitionView.transform = CGAffineTransform(translationX: transitionView.frame.width, y: 0)
                root.view.alpha = 0
            }
        } else if navigationController.viewControllers.count == 2, !didPush {
            coo.animate(
                alongsideTransition: { _ -> Void in
                    transitionView.transform = .identity
                    root.view.alpha = 1
            },
                completion: { context -> Void in
                    if context.isCancelled {
                        transitionView.transform = CGAffineTransform(translationX: transitionView.frame.width, y: 0)
                        root.view.alpha = 0
                    }
            })
        }
    }
    
    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        guard !(distinct[#function] ?? false) else { return }
        distinct[#function] = true
        defer { distinct[#function] = false }
        outerDelegate?.navigationController?(navigationController, didShow: viewController, animated: animated)
        
        guard let root = navigationController.viewControllers.first else { return }
        if didPush && viewController === root {
            navigationController.dismiss(animated: false, completion: nil)
        }
        if !didPush && viewController !== root {
            didPush = true
            pushCompletion?()
            pushCompletion = nil
        }
    }
    
    //
    private let UINavigationControllerDelegateSelectors: Set<Selector> = {
        var count: UInt32 = 0
        let protocolMethods = protocol_copyMethodDescriptionList(UINavigationControllerDelegate.self, false, true, &count)
        let selectors = UnsafeMutableBufferPointer(start: protocolMethods, count: Int(count))
            .compactMap{ $0.name }
        free(protocolMethods)
        return Set<Selector>(selectors)
    }()
    
    public override func responds(to aSelector: Selector!) -> Bool {
        switch aSelector {
        case #selector(UINavigationControllerDelegate.navigationController(_:willShow:animated:)),
             #selector(UINavigationControllerDelegate.navigationController(_:didShow:animated:)):
            return true
        default:
            
            return UINavigationControllerDelegateSelectors.contains(aSelector) ? (outerDelegate?.responds(to: aSelector) ?? false) : super.responds(to: aSelector)
        }
    }
    
    public override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return UINavigationControllerDelegateSelectors.contains(aSelector) ? outerDelegate : super.forwardingTarget(for: aSelector)
    }
}
