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
    @AppStorage("wifiDetails") var wifiDetails: String = ""

    @State private var password = ""
    
    @State private var disableVerifyWiFiButton = true
    @State private var disableRTSFButton = true

    
    
    
    //Alert
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    @State private var serialNumber = ""
    @State private var showActivity = false
    
    
    var body: some View {
        
        HStack(alignment: .center) {
            
            VStack(alignment: .trailing, spacing: 12.0) {
                Text("ID or Name of Wi-Fi Profile:")
                Text("Serial Number:")
            }
            VStack(alignment: .leading, spacing: 7.0) {
                TextField("" , text: $wifiDetails, onEditingChanged: { (changed) in

                })
                .textFieldStyle(.roundedBorder)
                .onChange(of: wifiDetails) { newValue in
                    if wifiDetails.isEmpty {
                        disableVerifyWiFiButton = true
                        disableRTSFButton = true
                    } else {
                        disableVerifyWiFiButton = false
                        disableRTSFButton = false
                    }
                }
                
                TextField("" , text: $serialNumber)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: serialNumber) { newValue in
                        if wifiDetails.isEmpty && serialNumber.isEmpty {
                            disableVerifyWiFiButton = true
                            disableRTSFButton = true
                        } else {
                            disableVerifyWiFiButton = false
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
        HStack(alignment: .center) {
            
            VStack(alignment: .leading, spacing: 7.0) {
                
            }
        }
        .padding([.leading,.trailing])
        .task {
            let defaults = UserDefaults.standard
            useAPIRoles = defaults.bool(forKey: "useAPIRoles")
            let jamfURL = defaults.string(forKey: "jamfURL") ?? ""
            if jamfURL.isEmpty {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
        }
        .onAppear {
            //            if savePassword  {
            fetchPassword()
            let defaults = UserDefaults.standard
            wifiDetails = defaults.string(forKey: "wifiDetails") ?? ""
            if !wifiDetails.isEmpty {
                disableVerifyWiFiButton = false
            }
        }
        
        HStack(alignment: .center) {
            Button("Verify Wi-Fil Profile") {
                Task {
                    fetchPassword()
                    await verifyWiFiProfile()
                }
            }
            .disabled(disableVerifyWiFiButton)
            
            Button("Return To Service") {
                Task {
                    fetchPassword()
                    await sendRTS()
                    //                    fetchPassword()
                    //                    await fetchLAPSPassword()
                }
            }
            .disabled(disableRTSFButton)
            //.disabled(fetchPassewordButtonDisabled)
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
        let (mobileConfig, response) = await jamfPro.fetchMobileConfig(jssURL: jamfURL, authToken: bearerToken, name: wifiDetails)
        
        guard let mobileConfig else { return }
        
        let (mobileID, idresponse) = await jamfPro.getMobileID(jssURL: jamfURL, authToken: bearerToken, serialNumber: serialNumber)
        
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
        let jamfPro = JamfProAPI(username: userName, password: password)
        let (bearerToken, _) = await jamfPro.getToken(jssURL: jamfURL, base64Credentials: jamfPro.base64Credentials, useAPIRole: useAPIRoles)


        guard let bearerToken else {
            alertMessage = "Could not authenticate. Please check the url and authentication details"
            alertTitle = "Authentication Error"
            showAlert = true
            showActivity = false
            return
        }

        let (mobileConfig, response) = await jamfPro.fetchMobileConfig(jssURL: jamfURL, authToken: bearerToken, name: wifiDetails)
        
        guard let mobileConfig else {
            alertMessage = "Could not locate the mobile config. Please verify the ID or name."
            alertTitle = "Wi-Fi Mobile Config Profile"
            showAlert = true
            showActivity = false
            return
        }
        guard let response, response == 200 else {
            alertMessage = "Could not locate the mobile config. Please verify the ID or name."
            alertTitle = "Wi-Fi Mobile Config Profile"
            showAlert = true
            showActivity = false
            return
        }
        
        if !mobileConfig.configurationProfile.general.payloads.lowercased().contains("com.apple.wifi.managed") {
            alertMessage = "The mobile config does not seem to contain a valid Wi-Fi payload."
            alertTitle = "Wi-Fi Mobile Config Profile"
            showAlert = true
            showActivity = false
            return
        }
        
        alertMessage = "The mobile config seems valid."
        alertTitle = "Wi-Fi Mobile Config Profile"
        showAlert = true
        showActivity = false

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
