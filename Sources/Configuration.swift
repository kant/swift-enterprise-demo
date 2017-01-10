//
//  Configuration.swift
//  monitoring-auto-scaling-demo
//
//  Created by Jim Avery on 1/6/17.
//
//

import Foundation
import AlertNotifications
import SwiftyJSON
import LoggerAPI
import CloudFoundryEnv

public struct Configuration {
    let configurationFile = "cloud_config.json"
    let appEnv: AppEnv
    
    init() throws {
        let path = Configuration.getAbsolutePath(relativePath: "/\(configurationFile)", useFallback: false)
        
        guard let finalPath = path else {
            Log.warning("Could not find '\(configurationFile)'.")
            appEnv = try CloudFoundryEnv.getAppEnv()
            return
        }
        
        let url = URL(fileURLWithPath: finalPath)
        let configData = try Data(contentsOf: url)
        let configJson = JSON(data: configData)
        appEnv = try CloudFoundryEnv.getAppEnv(options: configJson)
        Log.info("Using configuration values from '\(configurationFile)'.")
    }
    
    func getAlertNotificationSDKProps() throws -> ServiceCredentials {
        if let alertCredentials = appEnv.getService(spec: "monitoring-auto-scaling-demo")?.credentials {
            if let url = alertCredentials["url"].string,
                let name = alertCredentials["name"].string,
                let password = alertCredentials["password"].string {
                let credentials = ServiceCredentials(url: url, name: name, password: password)
                return credentials
            }
        }
        throw AlertNotificationError.credentialsError("Failed to obtain database service and/or its credentials.")
    }
    
    private static func getAbsolutePath(relativePath: String, useFallback: Bool) -> String? {
        let initialPath = #file
        let components = initialPath.characters.split(separator: "/").map(String.init)
        let notLastTwo = components[0..<components.count - 2]
        var filePath = "/" + notLastTwo.joined(separator: "/") + relativePath
        
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: filePath) {
            return filePath
        } else if useFallback {
            let currentPath = fileManager.currentDirectoryPath
            filePath = currentPath + relativePath
            if fileManager.fileExists(atPath: filePath) {
                return filePath
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}
