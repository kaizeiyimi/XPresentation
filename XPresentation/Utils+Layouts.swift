//
//  Utils.swift
//  XPresentation
//
//  Created by kai wang on 2018/10/15.
//  Copyright © 2018 kaizei. All rights reserved.
//

import UIKit

// MARK: - Layout. uses AutoLayout
extension Presentation {
    /// some helper layout methods. all uses AutoLayout. write your own if needed.
    public enum Layouts {
        
        /// describes how to make **width** and **height** constraint.
        public enum Dimension {
            case value(CGFloat)
            case percent(CGFloat)
        }
        
        public static func makeSimpleLayout(_ handler: @escaping (_ container: UIView, _ presented: UIView) -> Void) -> (UIViewControllerContextTransitioning) -> Void {
            return { transitionContext in
                guard let toView = transitionContext.view(forKey: UITransitionContextViewKey.to) else { return }
                transitionContext.containerView.addSubview(toView)
                handler(transitionContext.containerView, toView)
            }
        }
        
        public static func center(width: Dimension?, height: Dimension?, offset: UIOffset = .zero) -> (UIViewControllerContextTransitioning) -> Void {
            return makeSimpleLayout { container, presented in
                presented.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint(item: presented, attribute: .centerX, relatedBy: .equal, toItem: container, attribute: .centerX, multiplier: 1, constant: offset.horizontal).isActive = true
                NSLayoutConstraint(item: presented, attribute: .centerY, relatedBy: .equal, toItem: container, attribute: .centerY, multiplier: 1, constant: offset.vertical).isActive = true
                Layouts.makeSize(container: container, presented: presented, width: width, height: height)
            }
        }
        
        public static func top(width: Dimension?, height: Dimension?, offset: UIOffset = .zero) -> (UIViewControllerContextTransitioning) -> Void {
            return makeSimpleLayout { container, presented in
                presented.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint(item: presented, attribute: .centerX, relatedBy: .equal, toItem: container, attribute: .centerX, multiplier: 1, constant: offset.horizontal).isActive = true
                NSLayoutConstraint(item: presented, attribute: .top, relatedBy: .equal, toItem: container, attribute: .top, multiplier: 1, constant: offset.vertical).isActive = true
                Layouts.makeSize(container: container, presented: presented, width: width, height: height)
            }
        }
        
        public static func bottom(width: Dimension?, height: Dimension?, offset: UIOffset = .zero) -> (UIViewControllerContextTransitioning) -> Void {
            return makeSimpleLayout { container, presented in
                presented.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint(item: presented, attribute: .centerX, relatedBy: .equal, toItem: container, attribute: .centerX, multiplier: 1, constant: offset.horizontal).isActive = true
                NSLayoutConstraint(item: presented, attribute: .bottom, relatedBy: .equal, toItem: container, attribute: .bottom, multiplier: 1, constant: offset.vertical).isActive = true
                Layouts.makeSize(container: container, presented: presented, width: width, height: height)
            }
        }
        
        static private func makeSize(container: UIView, presented: UIView, width: Dimension?, height: Dimension?) {
            func addConstraint(dimension: Dimension, attribute: NSLayoutConstraint.Attribute) {
                switch dimension {
                case .value(let constant):
                    NSLayoutConstraint(item: presented, attribute: attribute, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: constant).isActive = true
                case .percent(let percent):
                    NSLayoutConstraint(item: presented, attribute: attribute, relatedBy: .equal, toItem: container, attribute: attribute, multiplier: percent, constant: 0).isActive = true
                }
            }
            
            if let width = width {
                addConstraint(dimension: width, attribute: .width)
            }
            
            if let height = height {
                addConstraint(dimension: height, attribute: .height)
            }
        }
    }

}
