//
//  ViewController.swift
//  XPresentationDemo
//
//  Created by kai wang on 2018/10/15.
//  Copyright © 2018 kai wang. All rights reserved.
//

import UIKit
import XPresentation

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "test", style: .plain, target: nil, action: nil)
    }

    @IBAction func onTap(sender: UIButton) {
        let page = PresentedPage()
        
        // present
//        let nav = UINavigationController(rootViewController: page)
//        nav.modalPresentationCapturesStatusBarAppearance = true
//        nav.view.layer.masksToBounds = true
//        nav.view.layer.cornerRadius = 8

        // config presentation
//        nav.configPresentation { config in
//            config.presentAnimation = Presentation.BasicAnimation.spring(
//                action: .present(Presentation.Layouts.center(width: .percent(0.75), height: .value(300))),
//                animator: Presentation.Animations.fadeIn())
//            config.dismissAnimation = Presentation.BasicAnimation.normal(
//                action: .dismiss,
//                animator: Presentation.Animations.fadeOut())
//            config.controller = Presentation.basicPresentationController(dismissOnTapDimmingView: true)
//        }
        
//        present(page, animated: true, completion: nil)
        
        PresentationWindow(level: UIWindow.Level(1999), preferredStatusBarStyle: .lightContent).present(page, animated: true)

        // popover
//        let width = page.view.widthAnchor.constraint(equalToConstant: 200)
//        width.priority = UILayoutPriority(999)
//        width.isActive = true
        
//        let height = page.view.heightAnchor.constraint(equalToConstant: 100)
//        height.priority = UILayoutPriority(999)
//        height.isActive = true
        
//        page.configPopover(preferredContentSize: CGSize(width: 200, height: 100), sourceView: sender, arrowDirection: .up)
//        present(page, animated: true, completion: nil)
    }
}


class PresentedPage: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        extendedLayoutIncludesOpaqueBars = true
        view.backgroundColor = UIColor.orange
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "关闭", style: .plain, target: self, action: #selector(back))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "change", style: .plain, target: self, action: #selector(change))
        
        let label = UILabel()
        label.text = "adfasdf aldkfjalkj aldfjalsdkfj adlfjaklsdfjvc wefrasdlkf"
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = .purple
        view.addSubview(label)
        label.topAnchor.constraint(equalTo: view.topAnchor, constant: 10).isActive = true
        label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10).isActive = true

    }
    
    deinit {
        print("presentd page deinit")
    }
    
    @objc private func back() {
//        dismiss(animated: true, completion: nil)
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func change() {
        preferredContentSize = CGSize(width: 250, height: 200)
    }
}
