//
//  Settings.swift
//  Caffeinate
//
//  Created by Lennard on 26.10.22.
//

import SwiftUI
import Combine


struct SettingsView: View {
    @EnvironmentObject private var configHandler :ConfigHandler
    @State private var error = [false, false, false]
    
    var body: some View {
        VStack(alignment: .leading) {
//            HStack {
//                Text("Hard mode:")
//                    .padding(.trailing, 35)
//                Toggle(isOn: ) {
//
//                }
//                .toggleStyle(CheckboxToggleStyle())
//            }
            if !configHandler.macOS13 {
                Text("Start at login is only available on MacOS 13 and later. You can manually add the app to the login items in the system preferences.")
                    .foregroundColor(.red)
                    //.frame(width: 350)
            }
            HStack {
                Text("Start at login:")
                Toggle(isOn: $configHandler.conf.atLogin) {
                    
                }
                .toggleStyle(CheckboxToggleStyle())
                .onChange(of: configHandler.conf.atLogin, perform: {b in
                    configHandler.applyAtLognin()
                })
                .disabled(!configHandler.macOS13)
            }
            Button(action: {configHandler.quitApp()}) {
                Text("Quit")
            }
        }
        .padding(.leading, configHandler.macOS13 ? -145 : 0)
        .padding(.top, -50)
    }


}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(ConfigHandler())
            .frame(width: 450, height: 150)
    }
}
