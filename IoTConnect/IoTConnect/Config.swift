//
//  Config.swift
//  IoTConnect

import Foundation



struct SDKURL {
    static let discoveryHost = "https://discovery.iotconnect.io"
    
    static func discovery(_ strDiscoveryURL:String, _ cpId:String, _ lang:String, _ ver:String, _ env:String) -> String {
        return String(format: "\(strDiscoveryURL)/api/sdk/cpid/\(cpId)/lang/\(lang)/ver/\(ver)/env/\(env)")
    }
}

struct SDKConstants {
    static let DevelopmentSDKYN = true //...For release SDK, this flag need to make false
    static let Language = "M_ios"
    static let Version = "2.0"
    static let protocolMQTT = "mqtt"
    static let protocolHTTP = "http"
    static let protocolAMQP = "amqp"
    static let FrequencyDSC = 10.0
    static let IsDebug = "isDebug"
    static let DiscoveryUrl = "discoveryUrl"
    static let Certificate = "Certificate"
    static let Password = "Password"
    static let SSLPassword = ""
    static let OSAvailSpaceInMb = 0
    static let OSFileCount = 1
    static let OSDisabled = false
    static let holdOfflineDataTime = 10.0
    static let TwinPropertyPubTopic = "$iothub/twin/PATCH/properties/reported/?$rid=1"
    static let TwinPropertySubTopic = "$iothub/twin/PATCH/properties/desired/#"
    static let TwinResponsePubTopic = "$iothub/twin/GET/?$rid=0"
    static let TwinResponseSubTopic = "$iothub/twin/res/#"
    static let AggrigacaseteType = ["min": 1, "max": 2, "sum": 4, "avg": 8, "count": 16, "lv": 32]
}

struct CommandType {
    static let CORE_COMMAND = "0x01"
    static let FIRMWARE_UPDATE = "0x02"
    static let ATTRIBUTE_INFO_UPDATE = "0x10"
    static let SETTING_INFO_UPDATE = "0x11"
    static let PASSWORD_INFO_UPDATE = "0x12"
    static let DEVICE_INFO_UPDATE = "0x13"
    static let RULE_INFO_UPDATE = "0x15"
    static let DEVICE_CONNECTION_STATUS = "0x16"
    static let DATA_FREQUENCY_UPDATE = "0x17"
    static let STOP_SDK_CONNECTION = "0x99"
}

struct DataType {
    static let DTNumber = 0
    static let DTString = 1
    static let DTObject = 2
    static let DTFloat  = 3
}

struct AuthType {
    static let KEY = 1
    static let CA_SIGNED = 2
    static let CA_SELF_SIGNED = 3
}

struct MessageType {
    static let rpt = 0
    static let flt = 1
    static let rptEdge = 2
    static let ruleMatchedEdge = 3
    static let log = 4
    static let ack = 5
    static let ota = 6
    static let custom = 7
    static let ping = 8
    static let deviceCreated = 9
    static let deviceStatus = 10
}

struct DeviceSync {
    struct Request {
        static let cpId = "cpId"
        static let uniqueId = "uniqueId"
        static let option = "option"
        static let attribute = "attribute"
        static let setting = "setting"
        static let protocolKey = "protocol"
        static let device = "device"
        static let sdkConfig = "sdkConfig"
        static let rule = "rule"
    }
    struct Response {
        static let OK = 0
        static let DEVICE_NOT_REGISTERED = 1
        static let AUTO_REGISTER = 2
        static let DEVICE_NOT_FOUND = 3
        static let DEVICE_INACTIVE = 4
        static let OBJECT_MOVED = 5
        static let CPID_NOT_FOUND = 6
    }
}

