//
//  JamfProApi.swift
//  Jamf Return To Service
//
//  Created by Richard Mallion on 05/09/2023.
//

import Foundation
import os.log

struct JamfProAPI {
    
    
    var username: String
    var password: String
    
    var base64Credentials: String {
        return "\(username):\(password)"
            .data(using: String.Encoding.utf8)!
            .base64EncodedString()
    }

    
    func isWifiMobileConfigProfile(jssURL: String, authToken: String, id: Int ) async -> Bool  {
        Logger.rts.info("Checking config profile id \(id, privacy: .public) for Wi-Fi payload")
        
        guard var jamfmobileEndpoint = URLComponents(string: jssURL) else {
            return false
        }
        
        jamfmobileEndpoint.path="/JSSResource/mobiledeviceconfigurationprofiles/id/\(id)/subset/General"

        guard let url = jamfmobileEndpoint.url else {
            return false
        }
        
        var mobileConfigRequest = URLRequest(url: url)
        mobileConfigRequest.httpMethod = "GET"
        mobileConfigRequest.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        mobileConfigRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        guard let (data, response) = try? await URLSession.shared.data(for: mobileConfigRequest)
        else {
            return false
        }
        
        let httpResponse = response as? HTTPURLResponse
        if let response = httpResponse?.statusCode {
            Logger.rts.info("Response code for fetching  mobile config profile: \(response, privacy: .public)")
        }
        do {
            let mobileConfigProfile = try JSONDecoder().decode(MobileConfigProfile.self, from: data)
            if mobileConfigProfile.configurationProfile.general.payloads.lowercased().contains("com.apple.wifi.managed") {
                Logger.rts.info("Profile \(id, privacy: .public) does have a wi-fi payload")

                return true
            } else {
                Logger.rts.info("Profile \(id, privacy: .public) does not have a wi-fi payload")
                return false
            }
        } catch _ {
            Logger.rts.error("Could not decode mobile config profile")
            return false
        }
    }

    
    func getAllMobileConfigProfiles(jssURL: String, authToken: String) async -> (AllMobileConfigProfiles?, Int?)  {
        Logger.rts.info("About to fetch all Mobile Config Profiles")
        guard var jamfcomputerEndpoint = URLComponents(string: jssURL) else {
            return (nil,nil)
        }
        jamfcomputerEndpoint.path="/JSSResource/mobiledeviceconfigurationprofiles"

        guard let url = jamfcomputerEndpoint.url else {
            return (nil,nil)
        }
        
        var mobileConfigRequest = URLRequest(url: url)
        mobileConfigRequest.httpMethod = "GET"
        mobileConfigRequest.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        mobileConfigRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        guard let (data, response) = try? await URLSession.shared.data(for: mobileConfigRequest)
        else {
            return (nil,nil)
        }
        
        let httpResponse = response as? HTTPURLResponse
        if let response = httpResponse?.statusCode {
            Logger.rts.info("Response code for fetching all mobile config profiles: \(response, privacy: .public)")
        }
        do {
            let allMobileConfigProfiles = try JSONDecoder().decode(AllMobileConfigProfiles.self, from: data)
            Logger.rts.info("\(allMobileConfigProfiles.configurationProfiles.count, privacy: .public) mobile config profiles where found")
            return ( allMobileConfigProfiles, httpResponse?.statusCode)
        } catch _ {
            Logger.rts.error("Could not decode mobile config profile")
            return (nil , nil)
        }
    }

    
    func getMobileDevceID(jssURL: String, authToken: String, serialNumber: String) async -> (Int?,Int?) {
        Logger.rts.info("About to fetch the mobile id for \(serialNumber)")

        guard var jamfMobileEndpoint = URLComponents(string: jssURL) else {
            return (nil, nil)
        }
        
        jamfMobileEndpoint.path="/JSSResource/mobiledevices/serialnumber/\(serialNumber)"

        guard let url = jamfMobileEndpoint.url else {
            return (nil, nil)
        }

        
        var mobileRequest = URLRequest(url: url)
        mobileRequest.httpMethod = "GET"
        mobileRequest.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        mobileRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        Logger.rts.info("Fetching Mobile ID for \(serialNumber)")
        guard let (data, response) = try? await URLSession.shared.data(for: mobileRequest)
        else {
            return (nil, nil)
        }
        let httpResponse = response as? HTTPURLResponse
        if let response = httpResponse?.statusCode {
            Logger.rts.info("Response code for fetching mobile id: \(response, privacy: .public)")
        }
        do {
            let mobile = try JSONDecoder().decode(Mobile.self, from: data)
            Logger.rts.info("Mobile ID found: \(mobile.mobile_device.general.id, privacy: .public)")
            return (mobile.mobile_device.general.id, httpResponse?.statusCode)
        } catch _ {
            Logger.rts.error("No Mobile ID found")
            return (nil, httpResponse?.statusCode)
        }
    }
    
    
    
    
    
    func getMobileManagementID(jssURL: String, authToken: String, id: Int) async -> (String?,Int?) {
        Logger.rts.info("About to fetch ManagementID for mobile id \(id)")
        guard var jamfMobileEndpoint = URLComponents(string: jssURL) else {
            return (nil, nil)
        }
        jamfMobileEndpoint.path="/api/v2/mobile-devices/\(id)"
        guard let url = jamfMobileEndpoint.url else {
            return (nil, nil)
        }

        var managementidRequest = URLRequest(url: url)
        managementidRequest.httpMethod = "GET"
        managementidRequest.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        managementidRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        Logger.rts.info("Fetching Management ID")
        guard let (data, response) = try? await URLSession.shared.data(for: managementidRequest)
        else {
            return (nil, nil)
        }
        let httpResponse = response as? HTTPURLResponse
        if let response = httpResponse?.statusCode {
            Logger.rts.info("Response code for fetching management id: \(response, privacy: .public)")
        }
        do {
            let mobile = try JSONDecoder().decode(MobileManagementDetail.self, from: data)
            Logger.rts.info("Management ID found: \(mobile.managementId, privacy: .public)")
            return (mobile.managementId, httpResponse?.statusCode)
        } catch _ {
            Logger.rts.error("No Management ID found")
            return (nil, httpResponse?.statusCode)
        }
    }

    
    
    func sendRTS(jssURL: String, authToken: String, wifi: String, managementid: String) async -> Int? {
        Logger.rts.info("About to send Return to service command to")
        let stringData = wifi.data(using: .utf8)!
        let base64EncodedString = stringData.base64EncodedString()

        guard var jamfMobileEndpoint = URLComponents(string: jssURL) else {
            return nil
        }
        jamfMobileEndpoint.path="/api/preview/mdm/commands"
        guard let url = jamfMobileEndpoint.url else {
            return nil
        }

        var rtsRequest = URLRequest(url: url)
        rtsRequest.httpMethod = "POST"
        rtsRequest.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        rtsRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        Logger.rts.info("Sending RTS")

        let json = """
        {
          "clientData": [
            {
              "managementId": "\(managementid)"
            }
          ],
          "commandData": {
            "commandType": "ERASE_DEVICE",
            "returnToService": {
                "enabled": true,
                 "wifiProfileData": "\(base64EncodedString)"
            }
          }
        }
        """
        
        let data = Data(json.utf8)

        rtsRequest.httpBody = data
        guard let (data, response) = try? await URLSession.shared.data(for: rtsRequest)
        else {
            return nil
        }
        let httpResponse = response as? HTTPURLResponse
        if let response = httpResponse?.statusCode {
            Logger.rts.info("Response code for sending Return To Service: \(response, privacy: .public)")
            return response
        }

        return nil
    }
    
    func getJamfProVersion(jssURL: String, authToken: String) async -> Double? {
        Logger.rts.info("About to fetch the Jamf Pro version")
        guard var jamfcomputerEndpoint = URLComponents(string: jssURL) else {
            return nil
        }
        jamfcomputerEndpoint.path="/api/v1/jamf-pro-version"
        guard let url = jamfcomputerEndpoint.url else {
            return nil
        }
        var jamfProVersionRequest = URLRequest(url: url)
        jamfProVersionRequest.httpMethod = "GET"
        jamfProVersionRequest.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        jamfProVersionRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        guard let (data, response) = try? await URLSession.shared.data(for: jamfProVersionRequest)
        else {
            return nil
        }
        
        let httpResponse = response as? HTTPURLResponse
        if let response = httpResponse?.statusCode {
            Logger.rts.info("Response code for fetching jamf pro version: \(response, privacy: .public)")
        }
        do {
            let jamfproVersion = try JSONDecoder().decode(JamfProVersion.self, from: data)
            let versionString = jamfproVersion.version
            if !versionString.isEmpty {
                let tmpArray = versionString.components(separatedBy: ".")
                if tmpArray.count > 2 {
                    var realJamfVersion = Double(tmpArray[0]) ?? 0
                    realJamfVersion = realJamfVersion +   (Double(tmpArray[1]) ?? 0) / 100
                    Logger.rts.info("Jamf pro version: \(realJamfVersion, privacy: .public)")
                    return realJamfVersion
                } else {
                    return nil
                }

            } else {
                return nil
            }
            
        } catch _ {
            Logger.rts.error("Could not decode jamf pro version")
            return nil
        }

    }
    
    func fetchMobileConfig(jssURL: String, authToken: String, id: String) async -> (MobileConfigProfile?,Int?)  {
        Logger.rts.info("About to fetch Mobile Config for \(id, privacy: .public)")
        guard var jamfcomputerEndpoint = URLComponents(string: jssURL) else {
            return (nil, nil)
        }

        jamfcomputerEndpoint.path="/JSSResource/mobiledeviceconfigurationprofiles/id/\(id)"

        guard let url = jamfcomputerEndpoint.url else {
            return (nil, nil)
        }
        
        var mobileConfigRequest = URLRequest(url: url)
        mobileConfigRequest.httpMethod = "GET"
        mobileConfigRequest.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        mobileConfigRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        guard let (data, response) = try? await URLSession.shared.data(for: mobileConfigRequest)
        else {
            return (nil, nil)
        }
        
        let httpResponse = response as? HTTPURLResponse
        if let response = httpResponse?.statusCode {
            Logger.rts.info("Response code for fetching mobile config: \(response, privacy: .public)")
        }
        do {
            let mobileConfig = try JSONDecoder().decode(MobileConfigProfile.self, from: data)
            Logger.rts.info("Mobile config profile received")
            return (mobileConfig, httpResponse?.statusCode)
        } catch _ {
            Logger.rts.error("Could not decode mobile config profile")
            return (nil, httpResponse?.statusCode)
        }
    }

    
 

    func getToken(jssURL: String, base64Credentials: String , useAPIRole: Bool) async -> (String?,Int?) {
        Logger.rts.info("About to fetch Authentication Token")
        guard var jamfAuthEndpoint = URLComponents(string: jssURL) else {
            return (nil, nil)
        }
        
        if useAPIRole {
            jamfAuthEndpoint.path="/api/oauth/token"
        } else {
            jamfAuthEndpoint.path="/api/v1/auth/token"
        }
        

        guard let url = jamfAuthEndpoint.url else {
            return (nil, nil)
        }
        
        let parameters = [
            "client_id": username,
            "grant_type": "client_credentials",
            "client_secret": password
        ]


        var authRequest = URLRequest(url: url)
        authRequest.httpMethod = "POST"
        if useAPIRole {
            authRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            let postData = parameters.map { key, value in
                return "\(key)=\(value)"
            }.joined(separator: "&")
            authRequest.httpBody = postData.data(using: .utf8)
        } else {
            authRequest.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        }
        
        Logger.rts.info("Fetching Authentication Token")
        guard let (data, response) = try? await URLSession.shared.data(for: authRequest)
        else {
            return (nil, nil)
        }
        
        let httpResponse = response as? HTTPURLResponse
        
        if let response = httpResponse?.statusCode {
            Logger.rts.info("Response code for authentication: \(response, privacy: .public)")
        }
        
        do {
            
            if useAPIRole {
                let jssToken = try JSONDecoder().decode(JamfOAuth.self, from: data)
                Logger.rts.info("Authentication token received")
                return (jssToken.access_token, httpResponse?.statusCode)
            } else {
                let jssToken = try JSONDecoder().decode(JamfAuth.self, from: data)
                Logger.rts.info("Authentication token received")
                return (jssToken.token, httpResponse?.statusCode)
            }
        } catch _ {
            Logger.rts.error("No authentication token received")
            return (nil, httpResponse?.statusCode)
        }
    }
    



    
}

// MARK: - LAPS Password
struct LAPSPassword: Codable {
    let password: String
}

// MARK: - Jamf Pro LAPS Settings
struct LAPSSettings: Codable {
    let autoDeployEnabled: Bool
    let passwordRotationTime: Int
    let autoRotateEnabled: Bool //Added for v2
    let autoRotateExpirationTime: Int //Used to be autoExpirationTime under v1
}




// MARK: - Jamf Pro Auth Model
struct JamfAuth: Decodable {
    let token: String
    let expires: String
    enum CodingKeys: String, CodingKey {
        case token
        case expires
    }
}

// MARK: - Jamf Pro Auth Model - API Role
struct JamfOAuth: Decodable {
    let access_token: String
    let expires_in: Int
    enum CodingKeys: String, CodingKey {
        case access_token
        case expires_in
    }
}


// MARK: - Computer Record
struct Computer: Codable {
    let computer: ComputerDetail
}

// MARK: - Computer Model
struct ComputerDetail: Codable {
    let general: General

    enum CodingKeys: String, CodingKey {
        case general
    }
}

struct General: Codable {
    let id: Int
    enum CodingKeys: String, CodingKey {
        case id
    }
}


// MARK: - ComputerManagementId
struct ComputerManagementId: Decodable {
    let id: String
    let general: GeneralManagementId
    enum CodingKeys: String, CodingKey {
        case id
        case general
    }

}

struct GeneralManagementId: Codable {
    let managementId: String
    enum CodingKeys: String, CodingKey {
        case managementId
    }

}

