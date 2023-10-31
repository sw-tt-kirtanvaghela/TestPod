//
//  IoTConnectManager.swift
//  IoTConnect
//
//  Created by Devesh Mevada on 8/20/21.
//

import Foundation
import Network

class IoTConnectManager {
    
    /*!
     * @brief Use Shared instance to access IoTConnectManager. Singleton instance.
     */
    static let sharedInstance = IoTConnectManager()
    
    //MARK:- Variables
    var blockHandlerDeviceCallBack : GetDeviceCallBackBlock!
    var blockHandlerTwinUpdateCallBack : GetTwinUpdateCallBackBlock!
    var strCPId: String!
    var strUniqueId: String!
    var strEnv: Environment = .PROD
    var strDiscoveryURL: String = SDKURL.discoveryHost
    var dictReference: [String:Any]!
    var dictSyncResponse: [String:Any]!
    var dataSDKOptions: SDKClientOption!
    var boolCanCallInialiseYN: Bool = true
    var boolDebugYN: Bool = false
    var timerNotRegister: Timer?
    var objCommon: Common!
    var objMQTTClient: MQTTClient!
    var DATA_FREQUENCY_NEXT_TIME: Date?
    var CERT_PATH_FLAG: Bool = true
    var reachability: Reachability?
    var intervalObj: [Any] = []
    

    
    init() {}
    
    //MARK: - Method - SDK-Initialiase
    init(cpId: String, uniqueId: String, env: String, sdkOptions: SDKClientOption?, deviceCallback: @escaping GetDeviceCallBackBlock, twinUpdateCallback: @escaping GetDeviceCallBackBlock) {

        objCommon = Common(cpId, uniqueId)
        strCPId = cpId
        strUniqueId = uniqueId
        if !env.isEmpty {
            strEnv = Environment(rawValue: env)!
        }

        if sdkOptions != nil {
            dataSDKOptions = sdkOptions
        } else {
            dataSDKOptions = SDKClientOption()
        }

        boolDebugYN = dataSDKOptions.debug

        if dataSDKOptions.discoveryUrl != nil {
            if dataSDKOptions.discoveryUrl!.isEmpty {
                objCommon.manageDebugLog(code: Log.Errors.ERR_IN02, uniqueId: uniqueId, cpId: cpId, message: "", logFlag: false, isDebugEnabled: boolDebugYN)
            } else {
                strDiscoveryURL = dataSDKOptions.discoveryUrl!
            }
        }

        if dataSDKOptions.SSL.Certificate != nil {
            let dataCertificate = dataSDKOptions.SSL.Certificate
            if !objCommon.checkForIfFileExistAtPath(filePath: dataCertificate as Any) {
                CERT_PATH_FLAG = false
            }
        } else {
            CERT_PATH_FLAG = false
        }

        objMQTTClient = MQTTClient(cpId, uniqueId, dataSDKOptions, CERT_PATH_FLAG, boolDebugYN)

        objMQTTClient.boolIsInternetAvailableYN = checkInternetAvailable()
        reachabilityObserver()

        initialize(cpId: cpId, uniqueId: uniqueId, deviceCallback: deviceCallback, twinUpdateCallback: twinUpdateCallback)
    }
    
    //MARK:- Sample API check
    fileprivate func sampleAPI() {
        HTTPManager().getBaseUrls { (data) in
            self.saveFile(data: data)
            self.sampleAPI2(data: data)
        } failure: { (error) in
            print(error)
        }
    }
    
    fileprivate func sampleAPI2(data: Discovery) {
        let cpid = "nine"
        let uniqueId = "ios"
        HTTPManager().syncCall(dynamicBaseUrl: data.baseUrl, cpid: cpid, uniqueId: uniqueId) { (data) in
            self.sampleMqttConnection(cpid: cpid, uniqueId: uniqueId, iotObj: data)
        } failure: { (error) in
            print(error)
        }
    }
    
    fileprivate func sampleMqttConnection(cpid: String, uniqueId: String, iotObj: IoTData) {
        let config = CocoaMqttConfig(cpid: cpid,
                                     uniqueId: uniqueId,
                                     mqttConnectionType: .userCredntialAuthentication,
                                     certificateConfig: nil,
                                     offlineStorageConfig: nil,
                                     iotData: iotObj)
        let mqtt = MqttClientManager(mqttConfig: config)
        mqtt.connect { (status) in
            print(status ? "Mqtt Connected ✅" : "Mqtt Failed 🚫")
        }
    }
    
    fileprivate func saveFile(data: Discovery) {
        if let data = try? JSONEncoder().encode(data) {
            let cacheData = CacheModel(fileName:"text.json", data: data)
            let cacheManager = CacheManager()
            cacheManager.saveDataToFile(data: cacheData) { (error) in
                if error == nil {
                    print("Save successfully")
                } else {
                    print("Failed to save")
                }
            }
        }
    }
    //MARK:-
    
    //MARK: - Method - SDK-Deinit
    deinit {
        print("deinit")
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: - Methods - SDK
    func sendData(data: [[String:Any]]) {
        if data.count > 0 {
            if dictSyncResponse.count > 0 {
                if strUniqueId != data[0]["uniqueId"] as? String {
                    self.objCommon.manageDebugLog(code: Log.Errors.ERR_SD02, uniqueId: strUniqueId, cpId: strCPId, message: "", logFlag: false, isDebugEnabled: boolDebugYN)
                } else {
                    let boolEdgeDevice = dictSyncResponse["ee"] as! Bool
                    if boolEdgeDevice {
                        setSendDataFormat(data: data)
                    } else {
                        let dataFrequencyInSec = dictSyncResponse[keyPath: "sc.df"] as! Int
                        let currentTime = Date()
                        if dataFrequencyInSec == 0 || DATA_FREQUENCY_NEXT_TIME == nil || (DATA_FREQUENCY_NEXT_TIME != nil &&  DATA_FREQUENCY_NEXT_TIME! < currentTime) {
                            setSendDataFormat(data: data)
                            
                            DATA_FREQUENCY_NEXT_TIME = currentTime.addingTimeInterval(TimeInterval(dataFrequencyInSec))
                        } else {
                            print("DF: Drop Send Data")
                        }
                    }
                }
            }
        } else {
            self.objCommon.manageDebugLog(code: Log.Errors.ERR_SD06, uniqueId: strUniqueId, cpId: strCPId, message: "", logFlag: false, isDebugEnabled: boolDebugYN)
        }
    }
    
    func sendLog(data: [String: Any]?) {
        
    }
    
    func sendAck(data: [[String:Any]], msgType: String) {
        if data.count == 0 || msgType.isEmpty {
            objCommon.manageDebugLog(code: Log.Errors.ERR_CM02, uniqueId: strUniqueId, cpId: strCPId, message: "", logFlag: false, isDebugEnabled: boolDebugYN)
        } else {
            if dictSyncResponse.count > 0 {
                let timeNow = objCommon.now()
                let dict = dictSyncResponse!
                for d: [String: Any] in data  {
                    autoreleasepool {
                        var dictAck: [String:Any] = [:]
                        dictAck["cpId"] = dict["cpId"]
                        dictAck["uniqueId"] = strUniqueId
                        dictAck["t"] = timeNow
                        dictAck["mt"] = msgType
                        dictAck["d"] = d["data"]
                        dictAck["sdk"] = ["l": SDKConstants.Language, "v": SDKConstants.Version, "e": strEnv.rawValue]
                        objMQTTClient.publishTopicOnMQTT(withData: dictAck)
                    }
                }
                objCommon.manageDebugLog(code: Log.Info.INFO_CM10, uniqueId: strUniqueId, cpId: strCPId, message: "", logFlag: true, isDebugEnabled: boolDebugYN)
            } else {
                objCommon.manageDebugLog(code: Log.Errors.ERR_CM04, uniqueId: strUniqueId, cpId: strCPId, message: "", logFlag: false, isDebugEnabled: boolDebugYN)
            }
        }
    }
    
    func getAllTwins() {
        if dictSyncResponse.count > 0 {
            objMQTTClient.getAllTwins()
        } else {
            objCommon.manageDebugLog(code: Log.Errors.ERR_TP04, uniqueId: strUniqueId, cpId: strCPId, message: "", logFlag: false, isDebugEnabled: boolDebugYN)
        }
    }
    
    func updateTwin(key: String, value: Any) {
        if dictSyncResponse.count > 0 {
            let strV = value as? String
            
            if key.isEmpty || strV == nil || strV?.count == 0 {
                objCommon.manageDebugLog(code: Log.Errors.ERR_TP03, uniqueId: strUniqueId, cpId: strCPId, message: "", logFlag: false, isDebugEnabled: boolDebugYN)
            } else {
                objMQTTClient.publishTwinPropertyDataOnMQTT(withData: [key: value])
            }
        } else {
            objCommon.manageDebugLog(code: Log.Errors.ERR_TP02, uniqueId: strUniqueId, cpId: strCPId, message: "", logFlag: false, isDebugEnabled: boolDebugYN)
        }
    }
    
    func dispose(sdkconnection: String = "") {
        if dictSyncResponse.count > 0 {
            objMQTTClient.disconnect()
            if sdkconnection != "" {
                objCommon.deleteAllLogFile(logPath: "logs/offline/" + strCPId + "_" + strUniqueId + "/", debugYN: boolDebugYN)
            }
        } else {
            objCommon.manageDebugLog(code: Log.Info.INFO_DC01, uniqueId: strUniqueId, cpId: strCPId, message: "", logFlag: true, isDebugEnabled: boolDebugYN)
        }
    }
    
    func getAttributes(callBack: @escaping (Bool, [[String:Any]]?, String) -> ()) {
        if dictSyncResponse.count > 0 {
            objCommon.getAttributes(dictSyncResponse: dictSyncResponse) { (data, msg) in
                print("data: ", data as Any)
                var sdkDataArray: [[String:Any]] = []
                (self.dictSyncResponse["d"] as! [[String:Any]]).forEach { (device) in
                    var attArray: [String:Any] = ["device": ["id": device["id"], "tg": device["tg"] ?? nil], "attributes": []] //device.tg == "" ? undefined : device.tg
                    let attributeData = data!["attribute"] as! [[String:Any]]
                    attributeData.forEach { (attribData) in
                        var attrib = attribData
                        if (attrib["p"] as! String == "") {// Parent
                            if (attrib["dt"] as? Int == 2) {
                                print("attrib: ", attrib)
                                attrib.removeValue(forKey: "agt")
                                var pcAttributes = [
                                    "ln" : attrib["p"],
                                    "dt": self.objCommon.dataTypeToString(value: attrib["dt"] as! Int),
                                    "tw": attrib["tw"] ?? nil,
                                    "d" : []
                                ]
                                
                                (attrib["d"] as! [[String:Any]]).forEach { (attData) in
                                    let att = attData
                                    if(att["tg"] as! String == device["tg"] as! String) {// Parent
                                        let cAttribute = [
                                            "ln": att["ln"],
                                            "dt": self.objCommon.dataTypeToString(value: att["dt"] as! Int),
                                            "dv": att["dv"],
                                            "tg": att["tg"] ?? nil,
                                            "tw": att["tw"] ?? nil
                                        ]
                                        
                                        var dA = pcAttributes["d"] as! [[String:Any]]
                                        dA.append(cAttribute as [String : Any])
                                        pcAttributes["d"] = dA
                                    }
                                }
                                
                            } else {
                                (attrib["d"] as! [[String:Any]]).forEach { (attData) in
                                    var att = attData
                                    if(att["tg"] as! String == device["tg"] as! String) {// Parent
                                        if(att["tg"] as! String == "") {
                                            att.removeValue(forKey: "tg")
                                        }
                                        att.removeValue(forKey: "agt")
                                        att["dt"] = self.objCommon.dataTypeToString(value: att["dt"] as! Int)
                                        var attributesA = attArray["attributes"] as! [[String:Any]]
                                        attributesA.append(att)
                                        attArray["attributes"] = attributesA
                                    }
                                }
                            }
                        } else {
                            if (attrib["tg"] as! String == device["tg"] as! String) {// Parent
                                attrib.removeValue(forKey: "agt")
                                var pcAttributes = [
                                    "ln" : attrib["p"] ?? "",
                                  "dt": self.objCommon.dataTypeToString(value: attrib["dt"] as! Int),
                                  "tg": attrib["tg"] ?? "",
                                  "tw": attrib["tw"] ?? "",
                                  "d" : []
                                ] as [String : Any]
                                (attrib["d"] as! [[String:Any]]).forEach { (attData) in
                                    let att = attData
                                    if(att["tg"] as! String == device["tg"] as! String) {// Parent
                                        let cAttribute = [
                                            "ln": att["ln"],
                                            "dt": self.objCommon.dataTypeToString(value: att["dt"] as! Int),
                                            "dv": att["dv"],
                                            "tg": att["tg"] ?? nil,
                                            "tw": att["tw"] ?? nil
                                        ]
                                        
                                        var dA = pcAttributes["d"] as! [[String:Any]]
                                        dA.append(cAttribute as [String : Any])
                                        pcAttributes["d"] = dA
                                    }
                                }
                                var pcAttributesA = attArray["attributes"] as! [[String:Any]]
                                pcAttributesA.append(pcAttributes as [String : Any])
                                attArray["attributes"] = pcAttributesA
                            }
                        }
                    }
                    sdkDataArray.append(attArray)
                }
                print("sdkDataArray: ", sdkDataArray)
                self.objCommon.manageDebugLog(code: Log.Info.INFO_GA01, uniqueId: self.strUniqueId, cpId: self.strCPId, message: "", logFlag: true, isDebugEnabled: self.boolDebugYN)
                callBack(true, sdkDataArray, "Attribute get successfully.")
            }
        } else {
            objCommon.manageDebugLog(code: Log.Errors.ERR_GA02, uniqueId: strUniqueId, cpId: strCPId, message: "", logFlag: false, isDebugEnabled: boolDebugYN)
            callBack(false, nil, "Attributes data not found")
        }
    }
    
}







