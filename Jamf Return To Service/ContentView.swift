//
//  ContentView.swift
//  Jamf Return To Service
//
//  Created by Richard Mallion on 05/09/2023.
//

import SwiftUI
import os.log

struct ContentView: View {
    @AppStorage("jamfURL") var jamfURL: String = ""
    @AppStorage("userName") var userName: String = ""
    @AppStorage("useAPIRoles") var useAPIRoles: Bool = false

    @State private var password = ""
    
    //Buttons
    @State private var disableRTSFButton = true

    //Alert
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    
    @State private var serialNumber = ""
    @State private var showActivity = false
    
    //Picker
    @State private var wifiMenuItems = [WiFiMenuItem(name: "No Wi-Fi Profiles", profileID: "0")]
    @State private var selectedWifiItem = "0"
    @State private var foundWiFiProfiles = false

    var body: some View {
        
        HStack(alignment: .center) {
            
            VStack(alignment: .trailing, spacing: 12.0) {
                Text("Wi-Fi Profile:")
                Text("Serial Number:")
            }
            
            VStack(alignment: .leading, spacing: 7.0) {
                Picker("", selection: $selectedWifiItem) {
                    ForEach(wifiMenuItems, id: \.profileID) {
                        Text($0.name)
                    }
                }
                TextField("" , text: $serialNumber)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: serialNumber) { newValue in
                        if !foundWiFiProfiles || serialNumber.isEmpty {
                            disableRTSFButton = true
                        } else {
                            disableRTSFButton = false
                        }
                    }
            }

        }
        .padding([.leading,.trailing])
        .alert(isPresented: self.$showAlert,
               content: {
            self.showCustomAlert()
        })
        .padding([.leading,.trailing, .bottom])
        .task {
            let defaults = UserDefaults.standard
            useAPIRoles = defaults.bool(forKey: "useAPIRoles")
            let jamfURL = defaults.string(forKey: "jamfURL") ?? ""
            if jamfURL.isEmpty {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
        }
        .onAppear {
            fetchPassword()
        }
        
        HStack(alignment: .center) {
            
            VStack(alignment: .leading, spacing: 7.0) {
                
            }
        }
        .padding([.leading,.trailing])
        
        HStack(alignment: .center) {
            Button("Find Wi-Fi Profiles") {
                Task {
                    fetchPassword()
                    await verifyWiFiProfile()
                }
            }
            
            Button("Return To Service") {
                Task {
                    fetchPassword()
                    await sendRTS()
                }
            }
            .disabled(disableRTSFButton)
            ProgressView()
                .scaleEffect(0.5)
                .opacity(showActivity ? 1 : 0)
        }
        
    }
    
    func fetchPassword() {
        let credentialsArray = Keychain().retrieve(service: "uk.co.mallion.jamf-return-to-service")
        if credentialsArray.count == 2 {
            //userName = credentialsArray[0]
            password = credentialsArray[1]
        }
        let defaults = UserDefaults.standard
        useAPIRoles = defaults.bool(forKey: "useAPIRoles")
        jamfURL = defaults.string(forKey: "jamfURL") ?? ""
        userName = defaults.string(forKey: "userName") ?? ""
    }
    
    func showCustomAlert() -> Alert {
        return Alert(
            title: Text(alertTitle),
            message: Text(alertMessage),
            dismissButton: .default(Text("OK"))
        )
    }
    
    func sendRTS() async {
        showActivity = true
        let jamfPro = JamfProAPI(username: userName, password: password)
        let (bearerToken, _) = await jamfPro.getToken(jssURL: jamfURL, base64Credentials: jamfPro.base64Credentials, useAPIRole: useAPIRoles)
        guard let bearerToken else {
            alertMessage = "Could not authenticate. Please check the url and authentication details"
            alertTitle = "Authentication Error"
            showAlert = true
            showActivity = false
            return
        }
        
        guard let jamfProVersion = await jamfPro.getJamfProVersion(jssURL: jamfURL, authToken: bearerToken) else {
            alertMessage = "Could not fetch Jamf Pro Version"
            alertTitle = "Error"
            showAlert = true
            showActivity = false
            return
        }
        if jamfProVersion < 10.50 {
            alertMessage = "Jamf Pro version 10.50 or higher is required"
            alertTitle = "Error"
            showAlert = true
            showActivity = false
            return
        }
        let (mobileConfig, response) = await jamfPro.fetchMobileConfig(jssURL: jamfURL, authToken: bearerToken, id: selectedWifiItem)
        
        guard let mobileConfig else { return }
        
        let (mobileID, idresponse) = await jamfPro.getMobileDevceID(jssURL: jamfURL, authToken: bearerToken, serialNumber: serialNumber)
        
        guard let mobileID else { return }
        
        let (managementid, manresponse) = await jamfPro.getMobileManagementID(jssURL: jamfURL, authToken: bearerToken, id: mobileID)
        guard let managementid else { return }

        let rtsresponse = await jamfPro.sendRTS(jssURL: jamfURL, authToken: bearerToken, wifi: mobileConfig.configurationProfile.general.payloads, managementid: managementid)
        
        guard let rtsresponse else { return }
        
        if rtsresponse == 201 {
            //Success
            alertMessage = "The return to service command was succesfulluy sent."
            alertTitle = "Return To Service"
            showAlert = true
            showActivity = false
        } else {
            //failure
            alertMessage = "The return to service command failed with error \(rtsresponse)"
            alertTitle = "Return To Service"
            showAlert = true
            showActivity = false
        }
    }
        
    func verifyWiFiProfile() async {
        showActivity = true
        
        let jamfPro = JamfProAPI(username: userName, password: password)
        let (bearerToken, _) = await jamfPro.getToken(jssURL: jamfURL, base64Credentials: jamfPro.base64Credentials, useAPIRole: useAPIRoles)
        
        guard let bearerToken else {
            alertMessage = "Could not authenticate. Please check the url and authentication details"
            alertTitle = "Authentication Error"
            showAlert = true
            showActivity = false
            return
        }
        
        let (allMobileConfigProfiles , allProfilesResponse) = await jamfPro.getAllMobileConfigProfiles(jssURL: jamfURL, authToken: bearerToken)

        guard let allMobileConfigProfiles, allMobileConfigProfiles.configurationProfiles.count > 0 else {
            alertMessage = "Could not locate any mobile config. Please verify the ID or name."
            alertTitle = "Wi-Fi Mobile Config Profile"
            showAlert = true
            showActivity = false
            return
        }
        
        wifiMenuItems = [WiFiMenuItem]()
        
        for profile in allMobileConfigProfiles.configurationProfiles {
            if await jamfPro.isWifiMobileConfigProfile(jssURL: jamfURL, authToken: bearerToken, id: profile.id) {
                wifiMenuItems.append(WiFiMenuItem(name: profile.name, profileID: String(profile.id)))
            }
        }
        if wifiMenuItems.count > 0 {
            selectedWifiItem = wifiMenuItems[0].profileID
            foundWiFiProfiles = true
        } else {
            wifiMenuItems = [WiFiMenuItem(name: "No Wi-Fi Profiles Found", profileID: "0")]
            selectedWifiItem = "0"
            foundWiFiProfiles = false
        }
        
        if !foundWiFiProfiles || serialNumber.isEmpty {
            disableRTSFButton = true
        } else {
            disableRTSFButton = false
        }
        
        showActivity = false
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
