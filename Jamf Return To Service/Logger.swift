//
//  Logger.swift
//  Jamf Return To Service
//
//  Created by Richard Mallion on 05/09/2023.
//

import Foundation
import os.log

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!

    //Categories
    static let rts = Logger(subsystem: subsystem, category: "rts")  // added lnh
}
