//
//  FrameUnsubscribe.swift
//  CocoaMQTT
//


import Foundation


/// MQTT UNSUBSCRIBE packet
struct FrameUnsubscribe: Frame {
    
    var fixedHeader: UInt8 = FrameType.unsubscribe.rawValue
    
    // --- Attributes
    
    var msgid: UInt16
    
    var topics: [String]
    
    // --- Attribetes end
    
    init(msgid: UInt16, topics: [String]) {
        self.msgid = msgid
        self.topics = topics
        
        qos = CocoaMQTTQoS.qos1
    }
}

extension FrameUnsubscribe {
    
    func variableHeader() -> [UInt8] { return msgid.hlBytes }
    
    func payload() -> [UInt8] {
        
        var payload = [UInt8]()
        
        for t in topics {
            payload += t.bytesWithLength
        }
        
        return payload
    }
}

extension FrameUnsubscribe: CustomStringConvertible {
    var description: String {
        return "UNSUBSCRIBE(id: \(msgid), topics: \(topics))"
    }
}
