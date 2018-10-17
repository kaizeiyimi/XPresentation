//
//  Utils+PresentationController.swift
//  XPresentation
//
//  Created by kai wang on 2018/10/16.
//  Copyright © 2018 kai wang. All rights reserved.
//

import UIKit

extension Presentation {
    /// provides a basic free controller. write your own if needed.
    public static func basicPresentationController(removePresentersView: Bool = false, dismissOnTapDimmingView: Bool = false, dimmingColor: UIColor = UIColor(white: 0, alpha: 0.6))
        -> (_ presented: UIViewController, _ presenting: UIViewController?, _ source: UIViewController) -> UIPresentationController? {
            return { presented, presenting, _ in
                let controller = PresentationController(presentedViewController: presented, presenting: presenting)
                controller.setup(removePresentersView: removePresentersView, dismissOnTapDimmingView: dismissOnTapDimmingView, dimmingColor: dimmingColor)
                return controller
            }
    }
    
    public static func systemPresentationController()
        -> (_ presented: UIViewController, _ presenting: UIViewController?, _ source: UIViewController) -> UIPresentationController? {
            return {_,_,_ in nil}
    }
}

// MARK: - PresentationController
private final class PresentationController: UIPresentationController {
    private lazy var dimmingView: UIView = {
        let control = UIControl()
        control.backgroundColor = self.dimmingColor
        control.addTarget(self, action: #selector(self.onTapDimmingView), for: .touchUpInside)
        return control
    }()
    
    private var removePresentersView: Bool!
    private var dismissOnTapDimmingView: Bool!
    private var dimmingColor: UIColor!
    
    func setup(removePresentersView: Bool, dismissOnTapDimmingView: Bool, dimmingColor: UIColor) {
        self.removePresentersView = removePresentersView
        self.dismissOnTapDimmingView = dismissOnTapDimmingView
        self.dimmingColor = dimmingColor
    }
    
    @objc private func onTapDimmingView(_ sender: AnyObject) {
        if dismissOnTapDimmingView {
            presentingViewController.dismiss(animated: true, completion: nil)
        }
    }
    
    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        guard let coordinator = presentingViewController.transitionCoordinator, let container = containerView else { return }
        
        dimmingView.frame = container.bounds
        dimmingView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        container.addSubview(dimmingView)
        
        self.dimmingView.alpha = 0
        coordinator.animateAlongsideTransition(in: self.dimmingView, animation: { context in
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
        return removePresentersView
    }
}
