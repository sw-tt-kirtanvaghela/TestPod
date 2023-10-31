//
//  OfflineStorageOption.swift
//  IoTConnect
//
//  Created by Devesh Mevada on 8/20/21.
//

import Foundation

public struct OfflineStorageOption {
    public var AvailSpaceInMb: Int = SDKConstants.OSAvailSpaceInMb
    public var FileCount: Int = SDKConstants.OSFileCount
    public var Disabled: Bool = SDKConstants.OSDisabled
}
