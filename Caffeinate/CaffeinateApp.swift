//
//  CaffeinateApp.swift
//  Caffeinate
//
//  Created by Lennard on 26.10.22.
//

import SwiftUI

@main
struct CaffeinateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
        
    var body: some Scene {
        Settings{
            EmptyView()
        }
    }
}
