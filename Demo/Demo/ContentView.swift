//
//  ContentView.swift
//  Demo
//
//  Created by kaizei on 2019/7/15.
//  Copyright © 2019 yimi.kaizei. All rights reserved.
//

import SwiftUI
import XPresentation

struct ContentView : View {
    var body: some View {
        Button("Hello World") {
            if let scene = UIApplication.shared.connectedScenes.randomElement() as? UIWindowScene {
                let page = UIViewController()
                page.view.backgroundColor = .orange
                PresentationWindow(windowScene: scene, level: .statusBar).present(page)
            }
        }
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
