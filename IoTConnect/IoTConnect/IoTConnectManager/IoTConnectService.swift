//
//  IoTConnectService.swift
//  IoTConnect
//
//  Created by Devesh Mevada on 8/20/21.
//

import Foundation

extension IoTConnectManager {
    //MARK: - Instance Methods
    func initialize(cpId: String, uniqueId: String, deviceCallback: @escaping GetDeviceCallBackBlock, twinUpdateCallback: @escaping GetDeviceCallBackBlock) {
        dictReference = [:]
        dictSyncResponse = [:]
        blockHandlerDeviceCallBack = deviceCallback
        blockHandlerTwinUpdateCallBack = twinUpdateCallback
        boolCanCallInialiseYN = true
        objCommon.createDirectoryFoldersForLogs()
        objCommon.manageDebugLog(code: Log.Info.INFO_IN04, uniqueId: uniqueId, cpId: cpId, message: "", logFlag: true, isDebugEnabled: boolDebugYN)
        objCommon.getBaseURL(strURL: SDKURL.discovery(strDiscoveryURL, cpId, SDKConstants.Language, SDKConstants.Version, strEnv.rawValue)) { (status, data) in
            if status {
                if let dataRef = data as? [String : Any] {
                    self.objCommon.manageDebugLog(code: Log.Info.INFO_IN07, uniqueId: uniqueId, cpId: cpId, message: "", logFlag: true, isDebugEnabled: self.boolDebugYN)
                    self.dictReference = dataRef
                    self.initaliseCall()
                } else {
                    self.objCommon.manageDebugLog(code: Log.Errors.ERR_IN09, uniqueId: uniqueId, cpId: cpId, message: "", logFlag: false, isDebugEnabled: self.boolDebugYN)
                }
            } else {
                if let error = data as? Error {
                    self.objCommon.manageDebugLog(code: Log.Errors.ERR_IN01, uniqueId: uniqueId, cpId: cpId, message: error.localizedDescription, logFlag: false, isDebugEnabled: self.boolDebugYN)
                }
            }
        }
    }
    private func initaliseCall() {
        if boolCanCallInialiseYN {
            boolCanCallInialiseYN = false
            dictSyncResponse.removeAll()

            objCommon.makeSyncCall(withBaseURL: dictReference["baseUrl"] as! String + "sync", withData: [DeviceSync.Request.cpId: strCPId as Any, DeviceSync.Request.uniqueId: strUniqueId as Any, DeviceSync.Request.option: [DeviceSync.Request.attribute: true, DeviceSync.Request.setting: true, DeviceSync.Request.protocolKey: true, DeviceSync.Request.device: true, DeviceSync.Request.sdkConfig: true, DeviceSync.Request.rule: true]]) { (data, response, error) in
                
                if error == nil {
                    let errorParse: Error? = nil
         
                    let dataDeviceTemp = try? JSONSerialization.jsonObject(with: data!, options: .mutableContainers)
                    
                    if dataDeviceTemp == nil {
                        
                        print("Error parsing DSC: \(String(describing: errorParse))")
                        self.objCommon.manageDebugLog(code: Log.Errors.ERR_PS01, uniqueId: self.strUniqueId, cpId: self.strCPId, message: errorParse?.localizedDescription ?? "", logFlag: false, isDebugEnabled: self.boolDebugYN)
                        
                    } else {
                        let dataDevice = dataDeviceTemp as! [String:Any]
                        if dataDevice["d"] != nil {
                            self.objCommon.manageDebugLog(code: Log.Info.INFO_IN01, uniqueId: self.strUniqueId, cpId: self.strCPId, message: "", logFlag: true, isDebugEnabled: self.boolDebugYN)
                            
                            if SDKConstants.DevelopmentSDKYN {
                                self.blockHandlerDeviceCallBack(["sdkStatus": "success", "data": dataDevice["d"]])
                            }
                            if dataDevice[keyPath:"d.rc"] as! Int == DeviceSync.Response.OK {//...OK
                                
                                if !self.dataSDKOptions.OfflineStorage.Disabled {
                                    self.objCommon.createPredeffinedLogDirecctories(folderName: "logs/offline/\(self.strCPId!)_\(self.strUniqueId!)")
                                }
                                
                                self.objCommon.manageDebugLog(code: Log.Info.INFO_IN08, uniqueId: self.strUniqueId, cpId: self.strCPId, message: "", logFlag: true, isDebugEnabled: self.boolDebugYN)
                                
                                if self.timerNotRegister != nil {
                                    self.timerNotRegister?.invalidate()
                                    self.timerNotRegister = nil
                                }
                                self.dictSyncResponse = dataDevice["d"] as? [String : Any]
                                
                                if dataDevice[keyPath: "d.at"] as! Int == AuthType.CA_SIGNED || dataDevice[keyPath: "d.at"] as! Int == AuthType.CA_SELF_SIGNED && !self.CERT_PATH_FLAG {
                                    
                                    self.objCommon.manageDebugLog(code: Log.Errors.ERR_IN06, uniqueId: self.strUniqueId, cpId: self.strCPId, message: "", logFlag: false, isDebugEnabled: self.boolDebugYN)
                                    
                                } else {
                                    
                                    if (dataDevice[keyPath: "d.p.n"] as! String).lowercased() == SDKConstants.protocolMQTT {
                                        //...Here
                                        self.startMQTTCall(dataSyncResponse: self.dictSyncResponse)
                                    } else if (dataDevice[keyPath: "d.p.n"] as! String).lowercased() == SDKConstants.protocolHTTP {
                                        
                                    } else if (dataDevice[keyPath: "d.p.n"] as! String).lowercased() == SDKConstants.protocolAMQP {
                                        
                                    }
                                    
                                }
                                
                            } else if dataDevice[keyPath:"d.rc"] as! Int == DeviceSync.Response.DEVICE_NOT_REGISTERED {//...Not Register
                                
                                self.objCommon.manageDebugLog(code: Log.Info.INFO_IN09, uniqueId: self.strUniqueId, cpId: self.strCPId, message: "", logFlag: true, isDebugEnabled: self.boolDebugYN)
                                
                                if self.timerNotRegister == nil {
                                    var dblSyncFrequency = SDKConstants.FrequencyDSC
                                    if let dblSyncFrequencyTemp = dataDevice[keyPath:"d.sc.sf"] as? Double {
                                        dblSyncFrequency = dblSyncFrequencyTemp
                                    }
                                    self.startTimerForReInitialiseDSC(durationSyncFrequency: dblSyncFrequency)
                                }
                                
                            } else if dataDevice[keyPath:"d.rc"] as! Int == DeviceSync.Response.AUTO_REGISTER {//...Auto Register
                                
                                self.objCommon.manageDebugLog(code: Log.Info.INFO_IN10, uniqueId: self.strUniqueId, cpId: self.strCPId, message: "", logFlag: true, isDebugEnabled: self.boolDebugYN)
                                
                            } else if dataDevice[keyPath:"d.rc"] as! Int == DeviceSync.Response.DEVICE_NOT_FOUND {//...Not Found
                                
                                self.objCommon.manageDebugLog(code: Log.Info.INFO_IN11, uniqueId: self.strUniqueId, cpId: self.strCPId, message: "", logFlag: true, isDebugEnabled: self.boolDebugYN)
                                
                                if self.timerNotRegister == nil {
                                    var dblSyncFrequency = SDKConstants.FrequencyDSC
                                    if let dblSyncFrequencyTemp = dataDevice[keyPath:"d.sc.sf"] as? Double {
                                        dblSyncFrequency = dblSyncFrequencyTemp
                                    }
                                    self.startTimerForReInitialiseDSC(durationSyncFrequency: dblSyncFrequency)
                                }
                                
                            } else if dataDevice[keyPath:"d.rc"] as! Int == DeviceSync.Response.DEVICE_INACTIVE {//...Inactive
                                
                                self.objCommon.manageDebugLog(code: Log.Info.INFO_IN12, uniqueId: self.strUniqueId, cpId: self.strCPId, message: "", logFlag: true, isDebugEnabled: self.boolDebugYN)
                                
                                if self.timerNotRegister == nil {
                                    var dblSyncFrequency = SDKConstants.FrequencyDSC
                                    if let dblSyncFrequencyTemp = dataDevice[keyPath:"d.sc.sf"] as? Double {
                                        dblSyncFrequency = dblSyncFrequencyTemp
                                    }
                                    self.startTimerForReInitialiseDSC(durationSyncFrequency: dblSyncFrequency)
                                }
                                
                            } else if dataDevice[keyPath:"d.rc"] as! Int == DeviceSync.Response.OBJECT_MOVED {//...Discovery URL
                                
                                self.objCommon.manageDebugLog(code: Log.Info.INFO_IN13, uniqueId: self.strUniqueId, cpId: self.strCPId, message: "", logFlag: true, isDebugEnabled: self.boolDebugYN)
                                
                            } else if dataDevice[keyPath:"d.rc"] as! Int == DeviceSync.Response.CPID_NOT_FOUND {//...CPID Not Found
                                
                                self.objCommon.manageDebugLog(code: Log.Info.INFO_IN14, uniqueId: self.strUniqueId, cpId: self.strCPId, message: "", logFlag: true, isDebugEnabled: self.boolDebugYN)
                                
                            } else {
                                
                                self.objCommon.manageDebugLog(code: Log.Info.INFO_IN15, uniqueId: self.strUniqueId, cpId: self.strCPId, message: "", logFlag: true, isDebugEnabled: self.boolDebugYN)
                                
                            }
                            
                        } else {
                            
                            self.objCommon.manageDebugLog(code: Log.Errors.ERR_IN10, uniqueId: self.strUniqueId, cpId: self.strCPId, message: "", logFlag: false, isDebugEnabled: self.boolDebugYN)
                            
                        }
                    }
                } else {
                    
                    print("Error parsing DSC: \(String(describing: error))")
                    self.objCommon.manageDebugLog(code: Log.Errors.ERR_IN01, uniqueId: self.strUniqueId, cpId: self.strCPId, message: error!.localizedDescription, logFlag: false, isDebugEnabled: self.boolDebugYN)
                    
                    if SDKConstants.DevelopmentSDKYN {
                        self.blockHandlerDeviceCallBack(["sdkStatus": "error"])
                    }
                    
                }
                
                self.boolCanCallInialiseYN = true
            }
        }
    }
    private func startTimerForReInitialiseDSC(durationSyncFrequency: Double) {
        self.timerNotRegister = Timer(timeInterval: durationSyncFrequency, target: self, selector: #selector(self.reInitialise), userInfo: nil, repeats: true)
        RunLoop.main.add(self.timerNotRegister!, forMode: .default)
        self.timerNotRegister!.fire()
    }
    @objc private func reInitialise() {
        self.objCommon.manageDebugLog(code: Log.Info.INFO_IN06, uniqueId: strUniqueId, cpId: strCPId, message: "", logFlag: true, isDebugEnabled: self.boolDebugYN)
        initaliseCall()
    }
    private func startMQTTCall(dataSyncResponse: [String:Any]) {
        if dataSyncResponse["p"] != nil {
            
            self.objCommon.manageDebugLog(code: Log.Info.INFO_IN05, uniqueId: strUniqueId, cpId: strCPId, message: "", logFlag: true, isDebugEnabled: boolDebugYN)
            //startEdgeDeviceProcess(dictSyncResponse: dataSyncResponse)
            self.objMQTTClient.initiateMQTT(dictSyncResponse: dataSyncResponse) { (dataToPass, typeAction) in
                
                //typeAction == 1   //...For Development Call Back
                //typeAction == 2   //...For Device Command Fire
                //typeAction == 3   //...For Updated Sync Response
                //typeAction == 4   //...For Get Desired and Reported twin property
                //typeAction == 5   //...For Get All Twin Property
                //typeAction == 6   //...For Perform Dispose
                if typeAction == 1 {
                    if let dataMessage = dataToPass as? [String:Any] {
                        if let strMsgStatus = dataMessage["sdkStatus"] as? String {
                            if strMsgStatus == "connect" {
                            } else if strMsgStatus == "error" {
                            } else if strMsgStatus == "success" {
                            }
                        }
                    }
                }
                
                if (typeAction == 1 && SDKConstants.DevelopmentSDKYN) || typeAction == 2 {
                    self.blockHandlerDeviceCallBack(dataToPass)
                } else if typeAction == 3 {
                    self.getUpdatedSyncResponseFor(strKey: dataToPass as! String)
                } else if typeAction == 4 {
                    var dataTwin: [String:Any] = [:]
                    dataTwin["desired"] = dataToPass
                    dataTwin["uniqueId"] = self.strUniqueId
                    self.blockHandlerTwinUpdateCallBack(dataTwin)
                } else if typeAction == 5 {
                    var dataTwin: [String:Any] = dataToPass as! [String : Any]
                    dataTwin["uniqueId"] = self.strUniqueId
                    self.blockHandlerTwinUpdateCallBack(dataTwin)
                } else if typeAction == 6 {
                    self.dispose(sdkconnection: dataToPass as! String)
                }
                
            }
        } else {
            
            self.objCommon.manageDebugLog(code: Log.Errors.ERR_IN11, uniqueId: strUniqueId, cpId: strCPId, message: "", logFlag: false, isDebugEnabled: boolDebugYN)
            
        }
    }
    private func getUpdatedSyncResponseFor(strKey: String) {
        var dict: [String:Any]?
        if strKey == CommandType.ATTRIBUTE_INFO_UPDATE {//...AttributeChanged
            dict = [DeviceSync.Request.cpId: strCPId as Any, DeviceSync.Request.uniqueId: strUniqueId as Any, DeviceSync.Request.option: [DeviceSync.Request.attribute: true]]
        } else if strKey == CommandType.SETTING_INFO_UPDATE {//...SettingChanged
            dict = [DeviceSync.Request.cpId: strCPId as Any, DeviceSync.Request.uniqueId: strUniqueId as Any, DeviceSync.Request.option: [DeviceSync.Request.setting: true]]
        } else if strKey == CommandType.PASSWORD_INFO_UPDATE {//...PasswordChanged
            dict = [DeviceSync.Request.cpId: strCPId as Any, DeviceSync.Request.uniqueId: strUniqueId as Any, DeviceSync.Request.option: [DeviceSync.Request.protocolKey: true]]
        } else if strKey == CommandType.DEVICE_INFO_UPDATE {//...DeviceChanged
            dict = [DeviceSync.Request.cpId: strCPId as Any, DeviceSync.Request.uniqueId: strUniqueId as Any, DeviceSync.Request.option: [DeviceSync.Request.device: true]]
        } else if strKey == CommandType.DATA_FREQUENCY_UPDATE {//...DataFrequencyUpdated
            dict = [DeviceSync.Request.cpId: strCPId as Any, DeviceSync.Request.uniqueId: strUniqueId as Any, DeviceSync.Request.option: [DeviceSync.Request.sdkConfig: true]]
        }
        if dict != nil {
            objCommon.makeSyncCall(withBaseURL: dictReference["baseUrl"] as! String + "sync", withData: dict) { (data, response, error) in
                if error == nil {
                    let errorParse: Error? = nil
                    let dataDeviceTemp = try? JSONSerialization.jsonObject(with: data!, options: .mutableContainers)
                    if dataDeviceTemp == nil {
                        print("Error parsing Sync Call: \(String(describing: errorParse))")
                        self.objCommon.manageDebugLog(code: Log.Errors.ERR_PS01, uniqueId: self.strUniqueId, cpId: self.strCPId, message: errorParse?.localizedDescription ?? "", logFlag: false, isDebugEnabled: self.boolDebugYN)
                    } else {
                        print("Success Sync Call: \(String(describing: dataDeviceTemp))")
                        
                        let dataDevice = dataDeviceTemp as! [String:Any]
                        
                        if dataDevice["d"] != nil {
                            
                            self.objCommon.manageDebugLog(code: Log.Info.INFO_IN01, uniqueId: self.strUniqueId, cpId: self.strCPId, message: "", logFlag: true, isDebugEnabled: self.boolDebugYN)
                            
                            if dataDevice[keyPath:"d.rc"] as! Int == DeviceSync.Response.OK {
                                var dictToUpdate = self.dictSyncResponse
                                if strKey == CommandType.ATTRIBUTE_INFO_UPDATE {
                                    dictToUpdate?["att"] = dataDevice[keyPath:"d.att"]
                                } else if strKey == CommandType.SETTING_INFO_UPDATE {
                                    dictToUpdate?["set"] = dataDevice[keyPath:"d.set"]
                                } else if strKey == CommandType.PASSWORD_INFO_UPDATE {
                                    dictToUpdate?["p"] = dataDevice[keyPath:"d.p"]
                                    if dictToUpdate != nil {
                                        self.startMQTTCall(dataSyncResponse: dictToUpdate!)
                                    } else {
                                        self.objCommon.manageDebugLog(code: Log.Errors.ERR_IN11, uniqueId: self.strUniqueId, cpId: self.strCPId, message: "", logFlag: false, isDebugEnabled: self.boolDebugYN)
                                    }
                                } else if strKey == CommandType.DEVICE_INFO_UPDATE {
                                    dictToUpdate?["d"] = dataDevice[keyPath:"d.d"]
                                } else if strKey == CommandType.DATA_FREQUENCY_UPDATE {
                                    dictToUpdate?["sc"] = dataDevice[keyPath:"d.sc"]
                                }
                                if dictToUpdate != nil {
                                    self.dictSyncResponse = dictToUpdate
                                }
                            }
                            
                        } else {
                            
                            self.objCommon.manageDebugLog(code: Log.Errors.ERR_IN10, uniqueId: self.strUniqueId, cpId: self.strCPId, message: "", logFlag: false, isDebugEnabled: self.boolDebugYN)
                            
                        }
                    }
                } else {
                    print("Error parsing Sync Call: \(String(describing: error))")
                    self.objCommon.manageDebugLog(code: Log.Errors.ERR_IN01, uniqueId: self.strUniqueId, cpId: self.strCPId, message: error!.localizedDescription, logFlag: false, isDebugEnabled: self.boolDebugYN)
                }
            }
        }
    }
    
    //MARK: - SendData: Logic Methods
    func setSendDataFormat(data: [[String:Any]]) {
        let timeNow = objCommon.now()
        let dict = dictSyncResponse!
        for d: [String: Any] in data  {
            autoreleasepool {
                let uniqueIds = dict["d"].flatMap{($0 as! [[String:Any]]).map { $0["id"] }} as! [String]
                if uniqueIds.contains(d["uniqueId"] as! String) {
                    let dictData = loadDataToSendIoTHub(fromSDKInput: d, withData: dict, withTime: d["time"] as! String)
                    if (dictData["rptdata"] as! [String:Any]).count > 0 {
                        var dictRptResult = [String: Any]()
                        dictRptResult["cpId"] = dict["cpId"]
                        dictRptResult["dtg"] = dict["dtg"]
                        dictRptResult["t"] = timeNow
                        dictRptResult["mt"] = MessageType.rpt
                        dictRptResult["d"] = [dictData["rptdata"]]
                        dictRptResult["sdk"] = ["l": SDKConstants.Language, "v": SDKConstants.Version, "e": strEnv.rawValue]
                        print("If-dictRptResult)")
                        objMQTTClient.publishTopicOnMQTT(withData: dictRptResult)
                    } else {
                        print("Else-dictRptResult")
                    }
                    if (dictData["faultdata"] as! [String:Any]).count > 0 {
                        var dictFaultResult = [String: Any]()
                        dictFaultResult["cpId"] = dict["cpId"]
                        dictFaultResult["dtg"] = dict["dtg"]
                        dictFaultResult["t"] = timeNow
                        dictFaultResult["mt"] = MessageType.flt
                        dictFaultResult["d"] = [dictData["faultdata"]]
                        dictFaultResult["sdk"] = ["l": SDKConstants.Language, "v": SDKConstants.Version, "e": strEnv.rawValue]
                        print("If-dictFaultResult");
                        objMQTTClient.publishTopicOnMQTT(withData: dictFaultResult)
                    } else {
                        print("Else-dictFaultResult")
                    }
                } else {
                    print("UniqueId not exist in 'devices'")
                }
            }
        }
    }
    private func loadDataToSendIoTHub(fromSDKInput dictSDKInput: [String: Any], withData dictSaved: [String: Any], withTime timeInput: String) -> [String: Any] {
        var dictDevice = [String : Any]()
        let uniqueIds = dictSaved["d"].flatMap{($0 as! [[String:Any]]).map { $0["id"] }} as! [String]
        if let index = uniqueIds.firstIndex(where: {$0  == dictSDKInput["uniqueId"] as! String}) {
            dictDevice = (dictSaved["d"] as! [[String:Any]])[index]
        }
        
        var dictCommonAttribute: [String : Any]?
        for dictAttribute  in (dictSaved["att"] as! [[String:Any]]) {
            if dictAttribute["p"] as! String == "" {
                dictCommonAttribute = dictAttribute
            }
        }
        
        var dictFaultAttributeData: [String:Any] = [:]
        var dictRptAttributeData: [String:Any] = [:]
        
        for strKey in (dictSDKInput["data"] as! [String:Any]).keys {
            var arrayFltAttrData:[[String:Any]] = []
            var arrayRptAttrData:[[String:Any]] = []
            var dictSelectAttribute: [String:Any]?
            
            for dictAttribute: [String: Any] in (dictSaved["att"] as! [[String: Any]])  {
                //Will Check for if attribute has parent or not with tag validation
                if (dictAttribute["p"] as! String == strKey) && (dictAttribute["tg"] as! String  == dictDevice["tg"] as! String) {
                    dictSelectAttribute = dictAttribute
                }
            }
            
            if dictSelectAttribute != nil {//Attribute has parent
                print("Attribute is parent")
                var arrayFltTmp:[[String:Any]] = []
                var arrayRptTmp:[[String:Any]] = []
                let strkeyPathM = KeyPath("data.\(strKey)")
                for strKeyChild: String in (dictSDKInput[keyPath:strkeyPathM] as! [String:Any]).keys {
                    let strkeyPath = KeyPath("data.\(strKey).\(strKeyChild)")
                    let dictForm = getAttributeForm(with: dictSelectAttribute!, withForKey: strKeyChild, withValue: dictSDKInput[keyPath:strkeyPath]!, withIsParent: false, withTag: "") as [String:Any]
                    if dictForm.count > 0 {
                        if !(dictForm["faultAttribute"] as! Int != 0) {
                            arrayFltTmp.append(dictForm["dataAtt"] as! [String : Any])
                        } else {
                            arrayRptTmp.append(dictForm["dataAtt"] as! [String : Any])
                        }
                    }
                }
                
                if arrayFltTmp.count > 0 {
                    var dictPFlt: [String:Any] = [:]
                    for dicD:[String:Any] in arrayFltTmp {
                        dictPFlt[dicD["key"] as! String] = dicD["value"]
                    }
                    arrayFltAttrData.append(["key": dictSelectAttribute!["p"] as Any, "value": dictPFlt])
                }
                
                if arrayRptTmp.count > 0 {
                    var dictPRpt: [String:Any] = [:]
                    for dicD:[String:Any] in arrayRptTmp {
                        dictPRpt[dicD["key"] as! String] = dicD["value"]
                    }
                    arrayRptAttrData.append(["key": dictSelectAttribute!["p"] as Any, "value": dictPRpt])
                }
                
            } else {//Attribute has no parent
                print("Attribute is not parent")
                if dictCommonAttribute != nil {
                    let strkeyPath = KeyPath("data." + strKey)
                    let dictForm = getAttributeForm(with: dictCommonAttribute!, withForKey: strKey, withValue: dictSDKInput[keyPath:strkeyPath]!, withIsParent: true, withTag: dictDevice["tg"] as! String)
                    if dictForm.count > 0 {
                        if !(dictForm["faultAttribute"] as! Int != 0) {
                            arrayFltAttrData.append(dictForm["dataAtt"] as! [String : Any])
                        } else {
                            arrayRptAttrData.append(dictForm["dataAtt"] as! [String : Any])
                        }
                    }
                } else {
                    print("Common attribute not available")
                }
            }
            
            if arrayFltAttrData.count > 0 {
                for dicD:[String:Any] in arrayFltAttrData {
                    dictFaultAttributeData[dicD["key"] as! String] = dicD["value"]
                }
            }
            if arrayRptAttrData.count > 0 {
                for dicD:[String:Any] in arrayRptAttrData {
                    dictRptAttributeData[dicD["key"] as! String] = dicD["value"]
                }
            }
            
        }
        
        print("dictFaultAttributeData: \(dictFaultAttributeData)")
        print("dictRptAttributeData: \(dictRptAttributeData)")
        
        var dictDataFault = [String: Any]()
        if dictFaultAttributeData.count > 0 {
            dictDataFault["id"] = dictDevice["id"]
            dictDataFault["dt"] = timeInput
            dictDataFault["d"] = [dictFaultAttributeData]
            dictDataFault["tg"] = dictDevice["tg"]
        }
        var dictDataRpt = [String: Any]()
        if dictRptAttributeData.count > 0 {
            dictDataRpt["id"] = dictDevice["id"]
            dictDataRpt["dt"] = timeInput
            dictDataRpt["d"] = [dictRptAttributeData]
            dictDataRpt["tg"] = dictDevice["tg"]
        }
        
        return ["faultdata": dictDataFault, "rptdata": dictDataRpt]
    }
    private func getAttributeForm(with dictAttribute: [String: Any], withForKey strKey: String, withValue idValue: Any, withIsParent boolYNParent: Bool, withTag strTag: String) -> [String: Any] {
        var dictResultAttribute = [String: Any]()
        for dict: [String: Any] in dictAttribute["d"] as! [[String: Any]] {
            if boolYNParent {
                if (dict["ln"] as! String == strKey) && (dict["tg"] as! String == strTag) {
                    let dictAttr = [strKey: idValue]
                    let boolYN: Bool = checkForIsValidOrNotWith(forData: dict, withValue: idValue)
                    dictResultAttribute["faultAttribute"] = (boolYN ? 1 : 0)
                    dictResultAttribute["dataAttribute"] = dictAttr
                    dictResultAttribute["dataAtt"] = ["key": strKey, "value": idValue]
                }
            } else {
                if (dict["ln"] as! String == strKey) {
                    let dictAttr = [strKey: idValue]
                    let boolYN: Bool = checkForIsValidOrNotWith(forData: dict, withValue: idValue)
                    dictResultAttribute["faultAttribute"] = (boolYN ? 1 : 0)
                    dictResultAttribute["dataAttribute"] = dictAttr
                    dictResultAttribute["dataAtt"] = ["key": strKey, "value": idValue]
                }
            }
        }
        return dictResultAttribute
    }
    private func checkForIsValidOrNotWith(forData dictForData: [String: Any], withValue idValue: Any) -> Bool {
        if dictForData["dt"] as? Int == DataType.DTNumber {
            let scan = Scanner(string: "\(Int(String(describing: idValue)) ?? 0)")
            var val: Int32 = 0
            if scan.scanInt32(&val) && scan.isAtEnd {
                
            } else {
                return false
            }
        }
        let arr = (dictForData["dv"] as! String).components(separatedBy: ",")
        if arr.count != 0 && !(dictForData["dv"] as! String == "") {
            if dictForData["dt"] as? Int == DataType.DTNumber {
                let valueToCheck = Int(String(describing: idValue)) ?? 0
                var boolInYN = false
                for strObject: String in arr {
                    if strObject.components(separatedBy: "to").count == 2 {
                        let arrayComponent = strObject.components(separatedBy: "to")

                        let min = Int(arrayComponent[0].trimmingCharacters(in: .whitespaces)) ?? 0
                        let max = Int(arrayComponent[1].trimmingCharacters(in: .whitespaces)) ?? 0

                        if valueToCheck <= max && valueToCheck >= min {
                           // print("if")
                            boolInYN = true
                        }
                    } else {
                        if Int(strObject) ?? 0 == valueToCheck || strObject.count == 0 {
                            boolInYN = true
                        }
                    }
                }
                return boolInYN
            } else if dictForData["dt"] as? Int == DataType.DTString {
                if arr.contains(idValue as! String) {
                    return true
                }
                return false
            }
        }
        return true
    }
    //MARK: - Method - Reachability Methods
    func checkInternetAvailable() -> Bool {
        let networkStatus = try! Reachability().connection
        
        switch networkStatus {
        case nil:
            return false
        case .cellular:
            return true
        case .wifi:
            return true
        case .none, .unavailable:
            return false
        }
    }
    
    func reachabilityObserver() {
        self.reachability = try! Reachability()
        NotificationCenter.default.addObserver(self, selector:#selector(self.reachabilityChanged), name: NSNotification.Name.reachabilityChanged, object: nil)
        do {
            try reachability?.startNotifier()
        } catch( _) {
        }
    }
    
    @objc private func reachabilityChanged(note: Notification) {
        let reachability = note.object as! Reachability
        
        var boolInternetAvailable: Bool = false
        switch reachability.connection {
        
        case .cellular:
            boolInternetAvailable = true
            print("Network available via Cellular Data.")
            break
        case .wifi:
            boolInternetAvailable = true
            print("Network available via WiFi.")
            break
        case .none:
            print("Network is not available.")
            break
        case .unavailable:
            print("Network unavailable.")
        
        }
        var boolCanReconnectYN = false
        if boolInternetAvailable && !objMQTTClient.boolIsInternetAvailableYN {
            boolCanReconnectYN = true
        }
        objMQTTClient.boolIsInternetAvailableYN = boolInternetAvailable
        if boolCanReconnectYN {
            objMQTTClient.connectMQTTAgain()
        }
    }
    //MARK: - Method - Custom Methods
    private func startEdgeDeviceProcess(dictSyncResponse: [String:Any]) {
        let boolEdgeDevice = dictSyncResponse["ee"] as! Bool
        var dictSyncResponseTemp = dictSyncResponse
        if boolEdgeDevice {
            objCommon.setEdgeConfiguration(attributes: dictSyncResponseTemp["att"] as! [[String:Any]], uniqueId: strUniqueId, devices: dictSyncResponseTemp["d"] as! [[String:Any]]) { (res) in
                if (res["status"] as! Bool) {
                    dictSyncResponseTemp["edgeData"] = res[keyPath:"data.mainObj"]
                    (res[keyPath:"data.intObj"] as! [[String:Any]]).forEach { (data) in
                        self.objCommon.setIntervalForEdgeDevice(tumblingWindowTime: data["tumblingWindowTime"] as! String, timeType: data["lastChar"] as! String, edgeAttributeKey: data["edgeAttributeKey"] as! String, uniqueId: data["uniqueId"] as! String, attrTag: data["attrTag"] as! String, env: self.strEnv.rawValue, offlineConfig: self.dataSDKOptions.OfflineStorage, intervalObj: self.intervalObj, cpId: self.strCPId, isDebug: self.boolDebugYN)
                    }
                }
            }
        }
    }
}
