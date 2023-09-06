//
//  Jamf_Return_To_ServiceApp.swift
//  Jamf Return To Service
//
//  Created by Richard Mallion on 05/09/2023.
//

import SwiftUI

@main
struct Jamf_Return_To_ServiceApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(
                    minWidth: 500, maxWidth: 500,
                    minHeight: 150, maxHeight: 150)

        }
        .windowResizability(.contentSize)
        
        Settings {
            SettingsView()
                .frame(
                    minWidth: 500, maxWidth: 500,
                    minHeight: 175, maxHeight: 175)
        }
        
    }
}
