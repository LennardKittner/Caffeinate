//
//  ToolBarView.swift
//  Caffeinate
//
//  Created by Lennard on 26.10.22.
//

import SwiftUI

struct TabView: View {
    @EnvironmentObject private var configHandler :ConfigHandler

    var body: some View {
        Section {
            if configHandler.curretnTab == 0 {
                About()
            } else if configHandler.curretnTab == 1 {
                SettingsView()
                    .environmentObject(configHandler)
            }
        }
        .frame(width: 450, height: 150)
   }
}

struct TabView_Previews: PreviewProvider {
    static var previews: some View {
        TabView()
            .environmentObject(ConfigHandler())
    }
}
