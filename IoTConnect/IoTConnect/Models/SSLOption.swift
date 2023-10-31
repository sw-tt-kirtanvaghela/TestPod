//
//  SSLOption.swift
//  IoTConnect
//
//  Created by Devesh Mevada on 8/20/21.
//

import Foundation

public struct SSLOption {
    public var Certificate: String?
    public var Password: String = SDKConstants.SSLPassword
}
