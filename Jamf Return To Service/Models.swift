//
//  Models.swift
//  Jamf Return To Service
//
//  Created by Richard Mallion on 05/09/2023.
//

import Foundation

// MARK: - MobileConfigProfile
struct MobileConfigProfile: Codable {
    let configurationProfile: ConfigurationProfile

    enum CodingKeys: String, CodingKey {
        case configurationProfile = "configuration_profile"
    }
}

// MARK: - ConfigurationProfile
struct ConfigurationProfile: Codable {
    let general: GeneralPayload

    enum CodingKeys: String, CodingKey {
        case general
    }
}

// MARK: - GeneralPayload
struct GeneralPayload: Codable {
    let id: Int
    let name: String
    let payloads: String

    enum CodingKeys: String, CodingKey {
        case id, name
        case payloads
    }
}


// MARK: - Jamf Pro Version
struct JamfProVersion: Codable {
    let version: String

    enum CodingKeys: String, CodingKey {
        case version
    }
}


// MARK: - Mobile Record
struct Mobile: Codable {
    let mobile_device: MobileDetail
}

// MARK: - Computer Model
struct MobileDetail: Codable {
    let general: MobileGeneral

    enum CodingKeys: String, CodingKey {
        case general
    }
}

struct MobileGeneral: Codable {
    let id: Int
    enum CodingKeys: String, CodingKey {
        case id
    }
}



struct MobileManagementDetail: Codable {
    let id: String
    let serialNumber: String
    let managementId: String
    enum CodingKeys: String, CodingKey {
        case id
        case serialNumber
        case managementId
    }
}
