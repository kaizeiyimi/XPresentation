//
//  Utils+Animations.swift
//  XPresentation
//
//  Created by kai wang on 2018/10/15.
//  Copyright © 2018 kai wang. All rights reserved.
//

import UIKit

extension Presentation {
    /// Basic animation control. write your own animation if needed.
    public final class BasicAnimation: NSObject, UIViewControllerAnimatedTransitioning {
        
        public enum Action {
            case present((UIViewControllerContextTransitioning) -> Void)
            case dismiss
        }
        
        private let action: Action
        private let duration: TimeInterval
        private let animations: (_ context: UIViewControllerContextTransitioning) -> Void
        
        public init(action: Action, duration: TimeInterval, animations: @escaping (_ context: UIViewControllerContextTransitioning) -> Void) {
            self.action = action
            self.duration = duration
            self.animations = animations
            super.init()
        }
        
        public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
            return duration
        }
        
        public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
            switch action {
            case .present(let layout):
                layout(transitionContext)
            case .dismiss:
                break
            }
            
            animations(transitionContext)
        }
    }

}

// provides two basic animation wrapper
extension Presentation.BasicAnimation {
    public static func spring(action: Action, duration: TimeInterval = 0.3, usingSpringWithDamping: CGFloat = 0.997, initialSpringVelocity: CGFloat = 0.2, options: UIView.AnimationOptions = [],
                              animator: Presentation.Animations.Animator) -> Presentation.BasicAnimation {
        return Presentation.BasicAnimation(action: action, duration: duration) { context in
            animator.prepare(context)
            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: usingSpringWithDamping, initialSpringVelocity: initialSpringVelocity, options: options, animations: {
                animator.animate(context)
            }, completion: { finished in
                context.completeTransition(finished)
            })
        }
    }
    
    public static func normal(action: Action, duration: TimeInterval = 0.25, options: UIView.AnimationOptions = [],
                              animator: Presentation.Animations.Animator) -> Presentation.BasicAnimation {
        return Presentation.BasicAnimation(action: action, duration: duration) { context in
            animator.prepare(context)
            UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
                animator.animate(context)
            }, completion: { finished in
                context.completeTransition(finished)
            })
        }
    }
}


extension Presentation {
    public enum Animations {
        public typealias Animator = (prepare: (_ context: UIViewControllerContextTransitioning) -> Void, animate: (_ context: UIViewControllerContextTransitioning) -> Void)
        
        public enum FlipDirection {
            case top, right, bottom, left
        }
        
        public static func flipIn(direction: FlipDirection) -> Animator {
            var frame: CGRect = .zero
            return (
                prepare: { context in
                    guard let toView = context.view(forKey: .to) else { return }
                    frame = toView.frame
                    switch direction {
                    case .top: toView.center.y -= frame.maxY
                    case .right: toView.center.x += context.containerView.bounds.width - frame.minX
                    case .bottom: toView.center.y += context.containerView.bounds.height - frame.minY
                    case .left: toView.center.x -= frame.maxX
                    }
                },
                animate: { context in
                    guard let toView = context.view(forKey: .to) else { return }
                    switch direction {
                    case .top: toView.center.y += frame.maxY
                    case .right: toView.center.x -= context.containerView.bounds.width - frame.minX
                    case .bottom: toView.center.y -= context.containerView.bounds.height - frame.minY
                    case .left: toView.center.x += frame.maxX
                    }
                }
            )
        }
        
        public static func flipOut(direction: FlipDirection) -> Animator {
            return (
                prepare: {_ in},
                animate: { context in
                    guard let fromView = context.view(forKey: .from) else { return }
                    let frame = fromView.frame
                    switch direction {
                    case .top: fromView.center.y -= frame.maxY
                    case .right: fromView.center.x += context.containerView.bounds.width - frame.minX
                    case .bottom: fromView.center.y += context.containerView.bounds.height - frame.minY
                    case .left: fromView.center.x -= frame.maxX
                    }
                }
            )
        }
        
        public static func zoomIn(scale: CGFloat = 0.8, alpha: CGFloat = 0) -> Animator {
            var originTransform: CGAffineTransform = .identity
            var originAlpha: CGFloat = 1
            return (
                prepare: { context in
                    guard let toView = context.view(forKey: .to) else { return }
                    (originTransform, originAlpha) = (toView.transform, toView.alpha)
                    toView.transform = toView.transform.concatenating(CGAffineTransform(scaleX: scale, y: scale))
                    toView.alpha = toView.alpha * alpha
                },
                animate: { context in
                    guard let toView = context.view(forKey: .to) else { return }
                    toView.transform = originTransform
                    toView.alpha = originAlpha
                }
            )
        }
        
        public static func zoomOut(scale: CGFloat = 0.8, alpha: CGFloat = 0) -> Animator {
            return (
                prepare: {_ in},
                animate: { context in
                    guard let fromView = context.view(forKey: .from) else { return }
                    fromView.transform = fromView.transform.concatenating(CGAffineTransform(scaleX: scale, y: scale))
                    fromView.alpha = fromView.alpha * alpha
                }
            )
        }
        
        public static func fadeIn(centerYDiff diff: CGFloat = 50) -> Animator {
            var originAlpha: CGFloat = 1
            return (
                prepare: { context in
                    guard let toView = context.view(forKey: .to) else { return }
                    originAlpha = toView.alpha
                    toView.alpha = 0
                    toView.frame.origin.y += diff
                },
                animate: { context in
                    guard let toView = context.view(forKey: .to) else { return }
                    toView.alpha = originAlpha
                    toView.frame.origin.y -= diff
                }
            )
        }
        
        public static func fadeOut(centerYDiff diff: CGFloat = 50) -> Animator {
            return (
                prepare: {_ in},
                animate: { context in
                    guard let fromView = context.view(forKey: .from) else { return }
                    fromView.center.y += diff
                    fromView.alpha = 0
                }
            )
        }
    }
}
