//
//  Presentation.swift
//
//  Created by kaizei on 16/10/18.
//  Copyright © 2016年 kaizei. All rights reserved.
//

import UIKit


public typealias AnimationBlock = (_ container: UIView, _ presenting: UIView?, _ presented: UIView, _ animator: PresentationAnimator) -> Void
public typealias LayoutBlock = (_ container: UIView, _ presented: UIView) -> Void


extension UIViewController {
    
    private struct AssociatedKeys {
        static var transitioningDelegateKey = "Presentation.TransitioningDelegateHolder.key"
    }
    
    /// make receiver ready to be presented. if **present** is nil, animation duration is ignored. so as **dismiss**.
    public func configPresentation(config: PresentationConfig = PresentationConfig(),
                                   layout: @escaping LayoutBlock,
                                   present: AnimationBlock?,
                                   dismiss: AnimationBlock?) {
        var config = config
        if present == nil {
            config.presentAnimationConfig.duration = 0
        }
        if dismiss == nil {
            config.dismissAnimationConfig.duration = 0
        }
        
        let delegate = TransitioningDelegate(config: config, layout: layout, present: present, dismiss: dismiss)
        modalPresentationStyle = .custom
        transitioningDelegate = delegate
        objc_setAssociatedObject(self, &AssociatedKeys.transitioningDelegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    /// popover
    public func configPopover(sourceView: UIView, sourceRect: CGRect? = nil, arrowDirection: UIPopoverArrowDirection = .any) {
        class Delegate: NSObject, UIPopoverPresentationControllerDelegate {
            struct Keys {
                static var delegateKey = "PresentationUtil.configPopover.delegate.key"
            }
            func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
                return .none
            }
        }
        modalPresentationStyle = .popover
        popoverPresentationController?.sourceView = sourceView
        popoverPresentationController?.sourceRect = sourceRect ?? sourceView.bounds
        popoverPresentationController?.permittedArrowDirections = arrowDirection
        
        let delegate = Delegate()
        if popoverPresentationController != nil {
            objc_setAssociatedObject(popoverPresentationController!, Delegate.Keys.delegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        popoverPresentationController?.delegate = delegate
    }
}


/**
 config the Presentation process including **present** animation, **dismiss** animation and dimming.
 
 animation uses **Spring** animation. can config **duration**, **damping**, **velocity** and **animationOptions**.
 */
public struct PresentationConfig {
    
    public struct AnimationConfig {
        public var duration: TimeInterval
        public var damping: CGFloat
        public var velocity: CGFloat
        public var animationOptions: UIView.AnimationOptions
        
        /// for optional param setup
        public init(duration: TimeInterval = 0.3, damping: CGFloat = 0.997, velocity: CGFloat = 0.2, animationOptions: UIView.AnimationOptions = .curveEaseInOut) {
            (self.duration, self.damping, self.velocity, self.animationOptions) = (duration, damping, velocity, animationOptions)
        }
    }
    
    public init(){}
    
    public var presentAnimationConfig = AnimationConfig()
    public var dismissAnimationConfig = AnimationConfig()
    
    public var dimmingColor = UIColor.black.withAlphaComponent(0.6)
    public var dismissOnTapDimmingView = true
    public var removePresenterView = false
    
}

/**
 controls how animations of **present** and **dismiss** performs. animation params are set in **PresentationConfig**.
 
 ```
 { container, presented, animator in
    presented.alpha = 0
    animator.animate({
        presented.alpha = 1
    }, completion: nil)
 }
 ```
 */
public final class PresentationAnimator {
    
    fileprivate var animations: (() -> Void)?
    fileprivate var completion: ((Bool) -> Void)?
    
    public func animate(animations: @escaping () -> Void, completion: ((Bool) -> Void)?) {
        self.animations = animations
        self.completion = completion
    }
    
}


// MARK: - Private Impl

private final class TransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    var config: PresentationConfig!
    var layout: LayoutBlock!
    var present: AnimationBlock?
    var dismiss: AnimationBlock?
    
    init(config: PresentationConfig, layout: @escaping LayoutBlock, present: AnimationBlock?, dismiss: AnimationBlock?) {
        (self.config, self.layout, self.present, self.dismiss) = (config, layout, present, dismiss)
        super.init()
    }
    
    // MARK: Transitioning delegate
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return AnimationController(config: config.presentAnimationConfig, action: .present(layout: layout), animations: present)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return AnimationController(config: config.dismissAnimationConfig, action: .dismiss, animations: dismiss)
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let controller = PresentationController(presentedViewController: presented, presenting: presenting)
        controller.config = config
        return controller
    }
    
}

private final class PresentationController: UIPresentationController {
    
    var config: PresentationConfig!
    let dimmingView = UIControl()
    
    @objc private func onTapDimmingView(_ sender: AnyObject) {
        if config.dismissOnTapDimmingView {
            presentingViewController.dismiss(animated: true, completion: nil)
        }
    }
    
    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        guard let coordinator = presentingViewController.transitionCoordinator, let container = containerView else { return }
        
        dimmingView.backgroundColor = config.dimmingColor
        dimmingView.frame = container.bounds
        dimmingView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        dimmingView.addTarget(self, action: #selector(self.onTapDimmingView), for: .touchUpInside)
        dimmingView.alpha = 0
        container.addSubview(dimmingView)
        
        coordinator.animate(alongsideTransition: { context in
            self.dimmingView.alpha = 1
            }, completion: { context in
                if context.isCancelled {
                    self.dimmingView.removeFromSuperview()
                }
        })
    }
    
    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        guard let coordinator = presentingViewController.transitionCoordinator else { return }
        
        coordinator.animate(alongsideTransition: { context in
            self.dimmingView.alpha = 0
            }, completion: { context in
                if !context.isCancelled {
                    self.dimmingView.removeFromSuperview()
                }
        })
    }
    
    override var shouldRemovePresentersView: Bool {
        return config.removePresenterView
    }
    
}

// MARK: - AnimationController
private final class AnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    enum Action {
        case present(layout: LayoutBlock)
        case dismiss
    }
    
    let config: PresentationConfig.AnimationConfig
    let action: Action
    let animations: AnimationBlock?
    
    init(config: PresentationConfig.AnimationConfig, action: Action, animations: AnimationBlock?) {
        self.config = config
        self.action = action
        self.animations = animations
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return config.duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView
        let presenting: UIView?, presented: UIView
        switch action {
        case .present(let layout):
            guard let toView = transitionContext.view(forKey: UITransitionContextViewKey.to) else { return }
            presenting = transitionContext.view(forKey: UITransitionContextViewKey.from)
            presented = toView
            container.addSubview(presented)
            layout(container, presented)
            container.layoutIfNeeded()
        case .dismiss:
            guard let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from) else { return }
            presenting = transitionContext.view(forKey: UITransitionContextViewKey.to)
            presented = fromView
            if let toView = presenting {
                toView.frame = container.bounds
                container.insertSubview(toView, at: 0)
            }
        }
        
        let animator = PresentationAnimator()
        animations?(container, presenting, presented, animator)
        
        UIView.animate(withDuration: config.duration, delay: 0, usingSpringWithDamping: config.damping, initialSpringVelocity: config.velocity, options: config.animationOptions, animations: {
            animator.animations?()
            }, completion: { finish in
                animator.completion?(finish)
                transitionContext.completeTransition(finish)
        })
    }
    
}
