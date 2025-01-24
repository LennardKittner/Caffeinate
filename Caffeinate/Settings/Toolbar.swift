//
//  Toolbar.swift
//  Caffeinate
//
//  Created by Lennard on 26.10.22.
//

import SwiftUI

struct Toolbar: View {
    @EnvironmentObject private var configHandler :ConfigHandler
    let tabs :[String]
    
    var body: some View {
        Picker("", selection: $configHandler.curretnTab) {
            ForEach(Array(tabs.indices), id: \.self ) { i in
                Text(tabs[i]).tag(i)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .frame(width: 100)
    }
}

struct Toolbar_Previews: PreviewProvider {
    static var previews: some View {
        Toolbar(tabs: ["About", "Settings"])
            .environmentObject(ConfigHandler())
    }
}
