//
//  Presentation.swift
//  XPresentation
//
//  Created by kai wang on 2018/10/15.
//  Copyright © 2018 kaizei. All rights reserved.
//

import UIKit


public enum Presentation {
    public struct Config {
        public var presentAnimation: UIViewControllerAnimatedTransitioning?
        public var dismissAnimation: UIViewControllerAnimatedTransitioning?
        public var controller: (_ presented: UIViewController, _ presenting: UIViewController?, _ source: UIViewController) -> UIPresentationController?
    }
}


// MARK: - UIViewController Presentation Config
extension UIViewController {
    
    /// presentation
    public func configPresentation(_ handler: (inout Presentation.Config) -> Void) {
        final class Delegate: NSObject, UIViewControllerTransitioningDelegate {
            static var key = "XPresentation.TransitioningDelegate.key"
            
            private let config: Presentation.Config
            
            init(config: Presentation.Config) {
                self.config = config
                super.init()
            }
            
            func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
                return config.presentAnimation
            }
            
            func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
                return config.dismissAnimation
            }
            
            func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
                return config.controller(presented, presenting, source)
            }
        }
        
        var config = Presentation.Config(presentAnimation: nil,
                                         dismissAnimation: nil,
                                         controller: Presentation.systemPresentationController())
        handler(&config)
        
        let delegate = Delegate(config: config)
        modalPresentationStyle = .custom
        transitioningDelegate = delegate
        objc_setAssociatedObject(self, &Delegate.key, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    /**
     popover.
     
     - parameters:
        - preferredContentSize: if nil, will use `systemLayoutSizeFitting` to calculate size. if .zero will not set size(means dicided by system).
     */
    public func configPopover(preferredContentSize: CGSize? = .zero, sourceView: UIView, sourceRect: CGRect? = nil, arrowDirection: UIPopoverArrowDirection = .any) {
        class Delegate: NSObject, UIPopoverPresentationControllerDelegate {
            static var key = "XPresentation.PopoverDelegate.key"
            
            func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
                return .none
            }
        }
        
        modalPresentationStyle = .popover
        switch preferredContentSize {
        case nil:
            self.preferredContentSize = view.systemLayoutSizeFitting(.zero, withHorizontalFittingPriority: .fittingSizeLevel, verticalFittingPriority: .fittingSizeLevel)
            
        case let .some(size) where size != .zero:
            self.preferredContentSize = size
            
        default:
            break
        }
        
        popoverPresentationController?.sourceView = sourceView
        popoverPresentationController?.sourceRect = sourceRect ?? sourceView.bounds
        popoverPresentationController?.permittedArrowDirections = arrowDirection
        
        let delegate = Delegate()
        if let controller = popoverPresentationController {
            objc_setAssociatedObject(controller, &Delegate.key, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        popoverPresentationController?.delegate = delegate
    }
}
