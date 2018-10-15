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
    }

    @IBAction func onTap() {
        let page = UIViewController()
        page.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "关闭", style: .plain, target: self, action: #selector(back))
        let nav = UINavigationController(rootViewController: page)
        
        // config presentation
        
        
        //
        present(nav, animated: true, completion: nil)
    }

    @objc private func back() {
        dismiss(animated: true, completion: nil)
    }
}

