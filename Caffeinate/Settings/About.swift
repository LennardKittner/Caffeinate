//
//  About.swift
//  Caffeinate
//
//  Created by Lennard on 26.10.22.
//

import SwiftUI

struct About: View {
    let version: String? = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Caffeinate")
                .font(.largeTitle)
                .bold()
                .padding(.bottom, 10)
            Spacer()
                .frame(height: 10)
            Text("Version: \(version ?? "1.0")")
                .font(.subheadline)
            Text("Author: Lennard Kittner")
                .font(.subheadline)
            Button(action: {
                let url = URL(string: "https://github.com/Lennard599")!
                NSWorkspace.shared.open(url)
            }) {
                Text("My GitHub")
                    .font(.subheadline)
            }
            .buttonStyle(.link)
            .padding(.top, 5)
        }
        .padding(.leading, -150.0)
    }
}

struct About_Previews: PreviewProvider {
    static var previews: some View {
        About()
            .frame(width: 450, height: 150)
    }
}
