//
//  Utils+UIKit.swift
//  XPresentation
//
//  Created by kai wang on 2018/10/16.
//  Copyright © 2018 kai wang. All rights reserved.
//

import UIKit

public final class PresentationContainerViewController: UIViewController {
    
    private let presentedView: UIView
    
    public init(view: UIView) {
        presentedView = view
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func loadView() {
        view = presentedView
    }
    
}


/// make a window with a root VC for presentation
public final class PresentationWindow: UIWindow {
    
    private final class RootViewController: UIViewController {
        var statusBarStyle: UIStatusBarStyle = .default
        override var preferredStatusBarStyle: UIStatusBarStyle { return statusBarStyle }
        
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
    
    public init(level: UIWindow.Level, root: UIViewController) {
        super.init(frame: UIScreen.main.bounds)
        rootViewController = root
        windowLevel = level
    }
    
    public convenience init(level: UIWindow.Level, preferredStatusBarStyle: UIStatusBarStyle) {
        let root = RootViewController()
        root.statusBarStyle = preferredStatusBarStyle
        self.init(level: level, root: root)
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
        return present(async: async, action: { root in
            root.present(vc, animated: animated, completion: completion)
        })
    }
    
    @discardableResult
    public func present(async: Bool = true, action: @escaping (_ root: UIViewController) -> Void) -> UIWindow {
        guard let root = rootViewController else {
            assertionFailure("presentation window must have a root view controller!")
            return self
        }
        
        makeKeyAndVisible()
        if async {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1/60) {
                _ = self
                action(root)
            }
        } else {
            action(root)
        }
        return self
    }
    
    @discardableResult
    public func presentTransparentRootNav(_ nav: UINavigationController? = nil,
                                          root: UIViewController,
                                          push vc: UIViewController,
                                          async: Bool = true, animated: Bool = true, completion: (() -> Void)? = nil) -> UIWindow {
        return presentTransparentRootNav(nav, root: root, push: {nav, root in nav.pushViewController(vc, animated: animated)}, async: async, completion: completion)
    }
    
    @discardableResult
    public func presentTransparentRootNav(_ nav: UINavigationController? = nil,
                                          root: UIViewController,
                                          push action: @escaping (UINavigationController, UIViewController) -> Void,
                                          async: Bool = true, completion: (() -> Void)? = nil) -> UIWindow {
        final class Delegate: NSObject, UINavigationControllerDelegate {
            static var Key = "Presentation.NavigationControllerDelegate.key"
            
            private weak var outerDelegate: UINavigationControllerDelegate?
            private var didPush = false
            private var pushCompletion: (() -> Void)?
            
            init(_ delegate: UINavigationControllerDelegate?, pushCompletion: (() -> Void)?) {
                self.outerDelegate = delegate
            }
            
            private var distinct: [String: Bool] = [:]
            //
            func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
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
            
            func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
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
            
            override func responds(to aSelector: Selector!) -> Bool {
                switch aSelector {
                case #selector(UINavigationControllerDelegate.navigationController(_:willShow:animated:)),
                     #selector(UINavigationControllerDelegate.navigationController(_:didShow:animated:)):
                    return true
                default:
                    
                    return UINavigationControllerDelegateSelectors.contains(aSelector) ? (outerDelegate?.responds(to: aSelector) ?? false) : super.responds(to: aSelector)
                }
            }
            
            override func forwardingTarget(for aSelector: Selector!) -> Any? {
                return UINavigationControllerDelegateSelectors.contains(aSelector) ? outerDelegate : super.forwardingTarget(for: aSelector)
            }
        }
        
        // adjust root
        root.view.backgroundColor = UIColor(white: 0, alpha: 0.1)
        root.view.alpha = 0
        
        // config nav
        let nav = nav ?? UINavigationController()
        nav.viewControllers = [root]
        let delegate = Delegate(nav.delegate, pushCompletion: completion)
        nav.delegate = delegate
        objc_setAssociatedObject(nav, &Delegate.Key, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // finally, do present without animation & push
        present(async: async) {
            $0.present(nav, animated: false) {
                action(nav, root)
            }
        }
        
        return self
    }
}
