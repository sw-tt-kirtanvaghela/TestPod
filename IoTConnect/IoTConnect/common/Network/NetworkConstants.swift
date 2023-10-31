//
//  NetworkConstants.swift
//  IoTConnect
//
//  Created by Devesh Mevada on 8/23/21.
//

import Foundation

public enum Environment: String {
    case DEV = "DEV"
    case STAGE = "STAGE"
    case POC = "poc"
    case QA = "QA"
    case PROD = "PROD"
    case AVNETPOC = "AVNETPOC"
}

class EnvironmentSelector {
    class var environment: Environment {
        return .QA
    }
}

struct HTTPScheme {
    static let secure = "https"
    static let notSecure = "http"
}

struct HTTPHeaderKeys {
    static let contentType = "Content-Type"
    static let accept = "Accept"
    static let contentLength = "Content-Length"
}

struct HTTPHeaderValues {
    static let json = "application/json"
}

struct ApiConstants {
    static var BASE_URL: String {
        switch EnvironmentSelector.environment {
        default: return "discovery.iotconnect.io"
        }
    }
    
    static var DISCOVERY_PATH: String {
        switch EnvironmentSelector.environment {
        default: return "/api/sdk/cpid/"
        }
    }
    
    static var SYNC_PATH: String {
        switch EnvironmentSelector.environment {
        default: return "sync"
        }
    }
}
