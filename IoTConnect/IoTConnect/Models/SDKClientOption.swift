//
//  SDKClientOption.swift
//  IoTConnect
//
//  Created by Devesh Mevada on 8/20/21.
//

import Foundation

public struct SDKClientOption {
    
    //For SSL CA signed and SelfSigned authorized device only
    public var SSL = SSLOption()
    
    //For Offline Storage only
    public var OfflineStorage = OfflineStorageOption()
    
    //For Developer only
    public var discoveryUrl: String?
    public var debug: Bool = false
    
    //MARK: - Method - SDK-Initialiase
    public init () {}
}
