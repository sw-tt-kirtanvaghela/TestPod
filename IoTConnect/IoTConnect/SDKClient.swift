//
//  IoTConnectSDK.swift
//  IoTConnect

import Foundation

public typealias GetDeviceCallBackBlock = (Any?) -> ()
public typealias GetTwinUpdateCallBackBlock = (Any?) -> ()

public class SDKClient {
    // Singleton SDK object
    public static let shared = SDKClient()
    
//    fileprivate var iotConnectManager: IoTConnectManager!// = IoTConnectManager.sharedInstance
    fileprivate var iotConnectManager:IoTConnectManager?
    private var blockHandlerDeviceCallBack : GetDeviceCallBackBlock?
    private var blockHandlerTwinUpdateCallBack : GetTwinUpdateCallBackBlock?
    
    /**
     Initialize configuration for IoTConnect SDK
     
     - Author:
     Devesh Mevada
     
     - parameters:
     - config: Setup IoTConnectConfig
     
     - returns:
     Returns nothing
     */
    public func initialize(config: IoTConnectConfig) {
        iotConnectManager = IoTConnectManager(cpId: config.cpId, uniqueId: config.uniqueId, env: config.env.rawValue, sdkOptions: config.sdkOptions, deviceCallback: { (message) in
            if self.blockHandlerDeviceCallBack != nil {
                self.blockHandlerDeviceCallBack!(message)
            }
        }, twinUpdateCallback: { (twinMessage) in
            if self.blockHandlerTwinUpdateCallBack != nil {
                self.blockHandlerTwinUpdateCallBack!(twinMessage)
            }
        })
    }
    
    /**
     Used for sending data from Device to Cloud
     
     - Author:
     Devesh Mevada
     
     - parameters:
     - data: Provide data in [[String:Any]] format
     
     - returns:
     Returns nothing
     */
    public func sendData(data: [[String:Any]]) {
        iotConnectManager?.sendData(data: data)
    }
    
    /**
     Used for sending log from device to cloud
     
     - Author:
     Devesh Mevada
     
     - parameters:
     - data: send log in [String: Any] format
     
     - returns:
     Returns nothing
     */
    public func sendLog(data: [String: Any]?) {
        iotConnectManager?.sendLog(data: data)
    }
    
    /**
     Send acknowledgement signal
     
     - Author:
     Devesh Mevada
     
     - parameters:
     - data: send data in [[String:Any]] format
     - msgType: send msgType from anyone of this
     
     - returns:
     Returns nothing
     */
    public func sendAck(data: [[String:Any]], msgType: String) {
        iotConnectManager?.sendAck(data: data, msgType: msgType)
    }
    
    /**
     Get all twins
     
     - Author:
     Devesh Mevada
     
     - returns:
     Returns nothing
     */
    public func getAllTwins() {
        iotConnectManager?.getAllTwins()
    }
    
    /**
     Updated twins
     
     - Author:
     Devesh Mevada
     
     - parameters:
     - key: key in String format
     - value: value as any
     
     - returns:
     Returns nothing
     */
    public func updateTwin(key: String, value: Any) {
        iotConnectManager?.updateTwin(key: key, value: value)
    }
    
    /**
     Dispose description
     
     - Author:
     Devesh Mevada
     
     - parameters:
     - sdkconnection: description
     
     - returns:
     Returns nothing
     */
    public func dispose(sdkconnection: String = "") {
        iotConnectManager?.dispose(sdkconnection: sdkconnection)
    }
    
    /**
     Get attaributs
     
     - Author:
     Devesh Mevada
     
     - parameters:
     - callBack:
     
     - returns:
     Returns nothing
     */
    public func getAttributes(callBack: @escaping (Bool, [[String:Any]]?, String) -> ()) {
        iotConnectManager?.getAttributes(callBack: callBack)
    }
    
    /**
     Get device callback
     
     - Author:
     Keyur Prajapati
     
     - parameters:
     - callBack:
     
     - returns:
     Returns nothing
     */
    public func getDeviceCallBack(deviceCallback: @escaping GetDeviceCallBackBlock) -> () {
        blockHandlerDeviceCallBack = deviceCallback
    }
    
    /**
     Get twin callback
     
     - Author:
     Keyur Prajapati
     
     - parameters:
     - callBack:
     
     - returns:
     Returns nothing
     */
    public func getTwinUpdateCallBack(twinUpdateCallback: @escaping GetTwinUpdateCallBackBlock) -> () {
        blockHandlerTwinUpdateCallBack = twinUpdateCallback
    }
}
