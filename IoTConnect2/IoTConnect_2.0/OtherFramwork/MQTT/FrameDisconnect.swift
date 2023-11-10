//
//  FrameDisconnect.swift
//  CocoaMQTT
//


import Foundation


/// MQTT Disconnect packet
struct FrameDisconnect: Frame {
    
    var fixedHeader: UInt8 = FrameType.disconnect.rawValue
    
    init() { /* Nothing to do */ }
}

extension FrameDisconnect {

    func variableHeader() -> [UInt8] { return [] }
    
    func payload() -> [UInt8] { return [] }
}

extension FrameDisconnect: CustomStringConvertible {
    var description: String {
        return "DISCONNECT"
    }
}
