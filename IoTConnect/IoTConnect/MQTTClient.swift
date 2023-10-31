//
//  MQTTClient.swift
//  IoTConnect

import Foundation

typealias GetMQTTStatusCallBackBlock = (Any?, Int) -> Void

class MQTTClient {
    //MARK: Variables - Private
    private var blockHandler : GetMQTTStatusCallBackBlock?
    private var mqtt: CocoaMQTT?
    private var dataSyncResponse: [String:Any]!
    private var objCommon: Common!
    private var strCPID: String = ""
    private var strUniqueID: String = ""
    private var boolDebugYN: Bool = false
    private var dataSDKOptions: SDKClientOption!
    private var CERT_PATH_FLAG: Bool
    var boolIsInternetAvailableYN: Bool = false
    private var isRunningOfflineStoring = false
    private var isRunningOfflineSending = false
    private var totalRecordCnt: Int = 0
    private let logBaseUrl = "logs/offline/"
    private var boolAlreadyConnectedYN: Bool = false
    
    //MARK: - MQTT-Init
    init(_ cpId: String, _ uniqueId: String, _ sdkOptions: SDKClientOption, _ boolCertiPathFlagYN: Bool, _ debugYN: Bool) {
        strCPID = cpId
        strUniqueID = uniqueId
        boolDebugYN = debugYN
        dataSDKOptions = sdkOptions
        CERT_PATH_FLAG = boolCertiPathFlagYN
        objCommon =  Common(cpId, uniqueId)
    }
    
    //MARK: - Initiate MQTT Connection
    func initiateMQTT(dictSyncResponse: [String:Any], callbackMQTTStatus: @escaping GetMQTTStatusCallBackBlock) {
        blockHandler = callbackMQTTStatus
        dataSyncResponse = dictSyncResponse
        if mqtt?.connState == .connected {
            mqtt!.disconnect()
        }
        mqtt = CocoaMQTT(clientID: dataSyncResponse[keyPath:"p.id"] as! String, host: dataSyncResponse[keyPath:"p.h"] as! String, port: dataSyncResponse[keyPath:"p.p"] as! UInt16)
        mqtt!.username = dataSyncResponse[keyPath:"p.un"] as? String
        mqtt!.password = dataSyncResponse[keyPath:"p.pwd"] as? String
//        mqtt!.keepAlive = 600
        mqtt!.delegate = self 
        mqtt!.enableSSL = true
         
        var boolToConnectYN = false
        if (dictSyncResponse["at"] as! Int == AuthType.CA_SIGNED || dictSyncResponse["at"] as! Int == AuthType.CA_SELF_SIGNED) {
            if CERT_PATH_FLAG {
                var sslSettings: [String: NSObject] = [:]
                let pwd = dataSDKOptions.SSL.Password
                let clientCertificate = objCommon.getClientCertFromP12File(pathCertificate: objCommon.getFilePath(dataSDKOptions.SSL.Certificate as Any), certPassword: pwd)
                sslSettings[kCFStreamSSLCertificates as String] = clientCertificate
                mqtt!.sslSettings = sslSettings
                mqtt!.allowUntrustCACertificate = true
                boolToConnectYN = true
            } else {
                objCommon.manageDebugLog(code: Log.Errors.ERR_IN11, uniqueId: strUniqueID, cpId: strCPID, message: "", logFlag: false, isDebugEnabled: boolDebugYN)
            }
        } else {
            boolToConnectYN = true
        }
        if boolToConnectYN {
            boolAlreadyConnectedYN = true
            _ = mqtt!.connect()
        }
    }
    func connectMQTTAgain() {
        print("connectMQTTAgain: ", boolIsInternetAvailableYN)
        if mqtt?.connState == .disconnected && boolAlreadyConnectedYN {
            _ = mqtt?.connect()
        }
    }
    //MARK: - Disconnect MQTT Connection
    func disconnect() {
        boolAlreadyConnectedYN = false
        if mqtt != nil {
            mqtt!.disconnect()
            mqtt = nil
            objCommon.manageDebugLog(code: Log.Info.INFO_IN03, uniqueId: strUniqueID, cpId: strCPID, message: "", logFlag: true, isDebugEnabled: boolDebugYN)
            blockHandler?(["cmdType": CommandType.DEVICE_CONNECTION_STATUS,
                           "data": ["cpid": strCPID,
                                    "guid": "",
                                    "uniqueId": strUniqueID,
                                    "command": false,
                                    "ack": false,
                                    "ackId": "",
                                    "cmdType": CommandType.DEVICE_CONNECTION_STATUS]], 2)
        } else {
            objCommon.manageDebugLog(code: Log.Errors.ERR_DC02, uniqueId: strUniqueID, cpId: strCPID, message: "", logFlag: false, isDebugEnabled: boolDebugYN)
        }
    }
    //MARK: - Offline Process Methods
    private func offlineProcess(_ offlineData: [String: Any]) {
        let offlinePerFileDataLimit = ((dataSDKOptions.OfflineStorage.AvailSpaceInMb * 1024) / dataSDKOptions.OfflineStorage.FileCount) * 1000 //Convert > KB > Bytes
        print("offlinePerFileDataLimit: ", offlinePerFileDataLimit as Any)
        if isRunningOfflineStoring {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.offlineProcess(offlineData)
            }
        } else {
            isRunningOfflineStoring = true
            let logPath = logBaseUrl + strCPID + "_" + strUniqueID + "/"
            do {
                // Get the directory contents urls (including subfolders urls)
                var files = try FileManager.default.contentsOfDirectory(atPath: objCommon.getDocumentsDirectory().appendingPathComponent(logPath).path)
                print("directoryContents-Before: \(files)")
                if files.contains(".DS_Store") {
                    files.remove(at: files.firstIndex(of: ".DS_Store")!)
                }
                print("directoryContents-After: \(files)")
                if (files.count == 0) {
                    createFile(offlineData: offlineData, oldFile: nil, logPath: logPath) { (res) in
                        self.isRunningOfflineStoring = false
                    }
                } else {
                    var boolIsActiveYN = false
                    files.forEach { (file) in
                        print("file: ", file)
                        if file.contains("Active") {
                            boolIsActiveYN = true
                            do {
                                let urlFile = objCommon.getDocumentsDirectory().appendingPathComponent(logPath + file)
                                let fileSize = try FileManager.default.attributesOfItem(atPath: urlFile.path)[FileAttributeKey.size]
                                var dataOffline = offlineData
                                if dataOffline["mt"] == nil || (dataOffline["mt"] as? Int) == MessageType.ack {
                                    dataOffline.removeValue(forKey: "cpId")
                                }
                                print("fileSize-Bytes: ", fileSize as Any)
                                if offlinePerFileDataLimit > fileSize as! Int || offlinePerFileDataLimit == 0 {
                                    //In File Size Limit or limited
                                    do {
                                        let data = try Data(contentsOf: urlFile, options: [])
                                        guard var packageObj = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] else {
                                            print("PackageObj-Read-parse error")
                                            objCommon.manageDebugLog(code: Log.Errors.ERR_OS01, uniqueId: strUniqueID, cpId: strCPID, message: "", logFlag: false, isDebugEnabled: boolDebugYN)
                                            return
                                        }
                                        print("PackageObj-Main:\(packageObj)")
                                        packageObj.append(offlineData)
                                        print("PackageObj-After:\(packageObj)")
                                        do {
                                            let dataToWrite = try JSONSerialization.data(withJSONObject: packageObj, options: .prettyPrinted)
                                            try dataToWrite.write(to: urlFile, options: [])
                                            objCommon.manageDebugLog(code: Log.Info.INFO_OS02, uniqueId: self.strUniqueID, cpId: self.strCPID, message: "", logFlag: true, isDebugEnabled: self.boolDebugYN)
                                        } catch {
                                            print("UpdateFile-error.localizedDescription: \(error.localizedDescription)")
                                            objCommon.manageDebugLog(code: Log.Errors.ERR_OS01, uniqueId: self.strUniqueID, cpId: self.strCPID, message: error.localizedDescription, logFlag: false, isDebugEnabled: self.boolDebugYN)
                                        }
                                    } catch {
                                        print("PackageObj-parse error: \(error.localizedDescription)")
                                        objCommon.manageDebugLog(code: Log.Errors.ERR_OS01, uniqueId: strUniqueID, cpId: strCPID, message: error.localizedDescription, logFlag: false, isDebugEnabled: boolDebugYN)
                                    }
                                    isRunningOfflineStoring = false
                                } else {
                                    //Exceeded the file limit as predetermined...
                                    if dataSDKOptions.OfflineStorage.FileCount == 1 {
                                        var shiftcnt = 1
                                        if offlinePerFileDataLimit > 1500 {
                                            shiftcnt = 3
                                        } else if offlinePerFileDataLimit > 1024 {
                                            shiftcnt = 2
                                        }
                                        do {
                                            let data = try Data(contentsOf: urlFile, options: [])
                                            guard var packageObj = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] else {
                                                print("ExceedLimit-PackageObj-Read-parse error")
                                                objCommon.manageDebugLog(code: Log.Errors.ERR_OS01, uniqueId: strUniqueID, cpId: strCPID, message: "", logFlag: false, isDebugEnabled: boolDebugYN)
                                                return
                                            }
                                            print("ExceedLimit-PackageObj-Main:\(packageObj)")
                                            if shiftcnt == 3 {
                                                packageObj.removeFirst()
                                                packageObj.removeFirst()
                                            } else if shiftcnt == 2 {
                                                packageObj.removeFirst()
                                            }
                                            packageObj.removeFirst()
                                            print("ExceedLimit-PackageObj-Removed:\(packageObj)")
                                            packageObj.append(offlineData)
                                            print("ExceedLimit-PackageObj-After:\(packageObj)")
                                            do {
                                                let dataToWrite = try JSONSerialization.data(withJSONObject: packageObj, options: .prettyPrinted)
                                                try dataToWrite.write(to: urlFile, options: [])
                                                objCommon.manageDebugLog(code: Log.Info.INFO_OS02, uniqueId: self.strUniqueID, cpId: self.strCPID, message: "", logFlag: true, isDebugEnabled: self.boolDebugYN)
                                            } catch {
                                                print("ExceedLimit-UpdateFile-error.localizedDescription: \(error.localizedDescription)")
                                                objCommon.manageDebugLog(code: Log.Errors.ERR_OS01, uniqueId: self.strUniqueID, cpId: self.strCPID, message: error.localizedDescription, logFlag: false, isDebugEnabled: self.boolDebugYN)
                                            }
                                        } catch {
                                            print("ExceedLimit-PackageObj-parse error: \(error.localizedDescription)")
                                            objCommon.manageDebugLog(code: Log.Errors.ERR_OS01, uniqueId: strUniqueID, cpId: strCPID, message: error.localizedDescription, logFlag: false, isDebugEnabled: boolDebugYN)
                                        }
                                        isRunningOfflineStoring = false
                                    } else {
                                        createFile(offlineData: offlineData, oldFile: nil, logPath: logPath) { (res) in
                                            do {
                                                var allFiles = try FileManager.default.contentsOfDirectory(atPath: self.objCommon.getDocumentsDirectory().appendingPathComponent(logPath).path)
                                                print("allFiles-directoryContents-Before: \(files)")
                                                if allFiles.contains(".DS_Store") {
                                                    allFiles.remove(at: allFiles.firstIndex(of: ".DS_Store")!)
                                                }
                                                print("allFiles-directoryContents-After: \(allFiles)")
                                                if allFiles.count > self.dataSDKOptions.OfflineStorage.FileCount {
                                                    self.deleteFile(logPath: logPath)
                                                }
                                            } catch {
                                                print("allFiles-offlineProcess-error.localizedDescription: \(error.localizedDescription)")
                                                self.objCommon.manageDebugLog(code: Log.Errors.ERR_OS04, uniqueId: self.strUniqueID, cpId: self.strCPID, message: Log.Errors.ERR_OS04.rawValue + " " + error.localizedDescription, logFlag: false, isDebugEnabled: self.boolDebugYN)
                                            }
                                            self.isRunningOfflineStoring = false
                                        }
                                    }
                                }
                            } catch {
                                print("offlineProcess-fileSize-error.localizedDescription: \(error.localizedDescription)")
                                objCommon.manageDebugLog(code: Log.Errors.ERR_OS01, uniqueId: strUniqueID, cpId: strCPID, message: error.localizedDescription, logFlag: false, isDebugEnabled: boolDebugYN)
                                isRunningOfflineStoring = false
                            }
                        }
                    }
                    if !boolIsActiveYN {
                        isRunningOfflineStoring = false
                    }
                }
            } catch {
                print("offlineProcess-error.localizedDescription: \(error.localizedDescription)")
                objCommon.manageDebugLog(code: Log.Errors.ERR_OS01, uniqueId: strUniqueID, cpId: strCPID, message: error.localizedDescription, logFlag: false, isDebugEnabled: boolDebugYN)
            }
        }
    }
    private func createFile(offlineData: [String: Any], oldFile: String?, logPath: String, callBack: @escaping (Bool) -> ()) {
        var dataOffline = offlineData
        if dataOffline["mt"] == nil || (dataOffline["mt"] as? Int) == MessageType.ack {
            dataOffline.removeValue(forKey: "cpId")
        }
        swapFilename(oldFileName: oldFile, logPath: logPath) {
            let newFilePath = self.objCommon.getDocumentsDirectory().appendingPathComponent(logPath + "Active_" + String(format: "\(Int64(Date().timeIntervalSince1970))") + ".json")
            let offlineDataArray = [offlineData]
            do {
                let data = try JSONSerialization.data(withJSONObject: offlineDataArray, options: .prettyPrinted)
                try data.write(to: newFilePath, options: [])
                
                self.objCommon.manageDebugLog(code: Log.Info.INFO_OS03, uniqueId: self.strUniqueID, cpId: self.strCPID, message: "", logFlag: true, isDebugEnabled: self.boolDebugYN)
                self.objCommon.manageDebugLog(code: Log.Info.INFO_OS02, uniqueId: self.strUniqueID, cpId: self.strCPID, message: "", logFlag: true, isDebugEnabled: self.boolDebugYN)
                callBack(true)
            } catch {
                print("createFile-error.localizedDescription: \(error.localizedDescription)")
                self.objCommon.manageDebugLog(code: Log.Errors.ERR_OS01, uniqueId: self.strUniqueID, cpId: self.strCPID, message: error.localizedDescription, logFlag: false, isDebugEnabled: self.boolDebugYN)
                callBack(false)
            }
        }
    }
    private func swapFilename(oldFileName: String?, logPath: String, callBack: @escaping () -> ()) {
        if oldFileName == nil {
            callBack()
        } else {
            if FileManager.default.fileExists(atPath: objCommon.getDocumentsDirectory().appendingPathComponent(logPath + oldFileName!).path) {
                let newFile = oldFileName![oldFileName!.index(oldFileName!.startIndex, offsetBy: 7)..<oldFileName!.endIndex]
                do {
                    let originPath = objCommon.getDocumentsDirectory().appendingPathComponent(logPath + oldFileName!)
                    let destinationPath = objCommon.getDocumentsDirectory().appendingPathComponent(logPath + newFile)
                    try FileManager.default.moveItem(at: originPath, to: destinationPath)
                    callBack()
                } catch {
                    print("swapFilename-error.localizedDescription: \(error.localizedDescription)")
                    objCommon.manageDebugLog(code: Log.Errors.ERR_OS01, uniqueId: strUniqueID, cpId: strCPID, message: error.localizedDescription, logFlag: false, isDebugEnabled: boolDebugYN)
                    callBack()
                }
            } else {
                callBack()
            }
        }
    }
    private func deleteFile(logPath: String, deleteFilePath: String = "") {
        let clientId = logPath.components(separatedBy: "/")
        let companyInfo = clientId[2].components(separatedBy: "_")
        let cpId = companyInfo[0]
        let uniqueId = companyInfo[1]
        if deleteFilePath == "" {
            do {
                var files = try FileManager.default.contentsOfDirectory(atPath: self.objCommon.getDocumentsDirectory().appendingPathComponent(logPath).path)
                print("deleteFile-directoryContents-Before: \(files)")
                if files.contains(".DS_Store") {
                    files.remove(at: files.firstIndex(of: ".DS_Store")!)
                }
                print("deleteFile-directoryContents-After: \(files)")
                if files.count > 0 {
                    var tempArray: [Int] = []
                    files.forEach { (file) in
                        tempArray.append(Int(file.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())!)
                    }
                    let deleteFileTimeStamp = tempArray.min()
                    if tempArray.firstIndex(of: deleteFileTimeStamp!) != -1 {
                        do {
                            try FileManager.default.removeItem(at: objCommon.getDocumentsDirectory().appendingPathComponent(logPath + files[tempArray.firstIndex(of: deleteFileTimeStamp!)!]))
                            objCommon.manageDebugLog(code: Log.Info.INFO_OS04, uniqueId: uniqueId, cpId: cpId, message: "", logFlag: true, isDebugEnabled: boolDebugYN)
                        } catch {
                            print("deleteFile-Remove-error.localizedDescription: \(error.localizedDescription)")
                            objCommon.manageDebugLog(code: Log.Errors.ERR_OS01, uniqueId: uniqueId, cpId: cpId, message:error.localizedDescription, logFlag: false, isDebugEnabled: boolDebugYN)
                        }
                    }
                }
            } catch {
                print("deleteFile-error.localizedDescription: \(error.localizedDescription)")
                objCommon.manageDebugLog(code: Log.Errors.ERR_OS01, uniqueId: uniqueId, cpId: cpId, message:error.localizedDescription, logFlag: false, isDebugEnabled: boolDebugYN)
            }
        } else {
            do {
                try FileManager.default.removeItem(at: objCommon.getDocumentsDirectory().appendingPathComponent(deleteFilePath))
                objCommon.manageDebugLog(code: Log.Info.INFO_OS04, uniqueId: uniqueId, cpId: cpId, message: "", logFlag: true, isDebugEnabled: boolDebugYN)
            } catch {
                print("deleteFilePath-error.localizedDescription: \(error.localizedDescription)")
                objCommon.manageDebugLog(code: Log.Errors.ERR_OS01, uniqueId: uniqueId, cpId: cpId, message:error.localizedDescription, logFlag: false, isDebugEnabled: boolDebugYN)
            }
        }
    }
    //MARK: - Offline Data Process On Online Methods
    private func checkOfflineData() {
        isRunningOfflineSending = true
        var dataPublishFileArray: [Int] = []
        let logPath = logBaseUrl + strCPID + "_" + strUniqueID + "/"
        do {
            var files = try FileManager.default.contentsOfDirectory(atPath: self.objCommon.getDocumentsDirectory().appendingPathComponent(logPath).path)
            print("checkOfflineData-directoryContents-Before: \(files)")
            if files.contains(".DS_Store") {
                files.remove(at: files.firstIndex(of: ".DS_Store")!)
            }
            print("checkOfflineData-directoryContents-After: \(files)")
            if files.count > 0 {
                var tempArray: [Int] = []
                files.forEach { (file) in
                    tempArray.append(Int(file.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())!)
                }
                print("tempArray-Before: ", tempArray)
                tempArray.sort()
                print("tempArray-After: ", tempArray)
                dataPublishFileArray = tempArray
            }
        } catch {
            print("checkOfflineData-error.localizedDescription: \(error.localizedDescription)")
            objCommon.manageDebugLog(code: Log.Errors.ERR_OS01, uniqueId: strUniqueID, cpId: strCPID, message:error.localizedDescription, logFlag: false, isDebugEnabled: boolDebugYN)
        }
        if dataPublishFileArray.count > 0 {
            dataPublishFileArray.forEach { (file) in
                var dataFile = String(format: "\(file)") + ".json"
                if FileManager.default.fileExists(atPath: objCommon.getDocumentsDirectory().appendingPathComponent(logPath + dataFile).path) {
                    checkAndSendOfflineData(offlineDataFile: logPath + dataFile, logPath: logPath) { (res) in
                        
                    }
                    
                } else {
                    dataFile = logPath + "Active_" + dataFile
                    if FileManager.default.fileExists(atPath: objCommon.getDocumentsDirectory().appendingPathComponent(dataFile).path) {
                        checkAndSendOfflineData(offlineDataFile: dataFile, logPath: logPath) { (res) in
                            
                        }
                    }
                }
            }
        } else {
            objCommon.manageDebugLog(code: Log.Info.INFO_OS05, uniqueId: strUniqueID, cpId: strCPID, message:"", logFlag: true, isDebugEnabled: boolDebugYN)
            isRunningOfflineSending = false
        }
    }
    private func checkAndSendOfflineData(offlineDataFile: String, logPath: String, callBack: @escaping (Bool) -> ()) {
        
        if FileManager.default.fileExists(atPath: objCommon.getDocumentsDirectory().appendingPathComponent(offlineDataFile).path) {
            var offlineDtaCountforAllFIles: Int = 0
            do {
                let data = try Data(contentsOf: objCommon.getDocumentsDirectory().appendingPathComponent(offlineDataFile), options: [])
                guard let offDataObj = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] else {
                    print("checkAndSendOfflineData-Read-parse error")
                    objCommon.manageDebugLog(code: Log.Errors.ERR_OS01, uniqueId: strUniqueID, cpId: strCPID, message: "", logFlag: false, isDebugEnabled: boolDebugYN)
                    callBack(true)
                    return
                }
                print("checkAndSendOfflineData-Main:\(offDataObj)")
                if offDataObj.count > 0 {
                    offlineDtaCountforAllFIles = offlineDtaCountforAllFIles + offDataObj.count
                    sendOfflineDataProcess(offDataObj: offDataObj, offlineDataLength: offlineDtaCountforAllFIles, offlineDataFile: offlineDataFile, logPath: logPath)
                } else {
                    deleteFile(logPath: logPath, deleteFilePath: offlineDataFile)
                    callBack(true)
                }
            } catch {
                print("checkAndSendOfflineData-parse error: \(error.localizedDescription)")
                objCommon.manageDebugLog(code: Log.Errors.ERR_OS01, uniqueId: strUniqueID, cpId: strCPID, message: error.localizedDescription, logFlag: false, isDebugEnabled: boolDebugYN)
                callBack(true)
            }
        } else {
            objCommon.manageDebugLog(code: Log.Errors.ERR_OS01, uniqueId: strUniqueID, cpId: strCPID, message: "", logFlag: false, isDebugEnabled: boolDebugYN)
            callBack(true)
        }
    }
    private func sendOfflineDataProcess(offDataObj: [[String: Any]], offlineDataLength: Int, offlineDataFile: String, logPath: String) {
        let offlineData = offDataObj
        var dataOfflineToModify = offDataObj
        print("CNT-Start: ", dataOfflineToModify.count)
        let actualDataLength = offlineDataLength
        let offlineHoldTillTime = Date().addingTimeInterval(SDKConstants.holdOfflineDataTime)
        
        var indX = 0
        offlineData.forEach { (offlineDataResult) in
            if Date() > offlineHoldTillTime {
                dataOfflineToModify = dataOfflineToModify.filter { (obj) -> Bool in
                    return obj.count > 0
                }
                print("CNT-After-1: ", dataOfflineToModify.count)
                objCommon.manageDebugLog(code: Log.Info.INFO_OS06, uniqueId: strUniqueID, cpId: strCPID, message:String(format: "\(Log.Info.INFO_OS06)\(totalRecordCnt) / \(actualDataLength)"), logFlag: true, isDebugEnabled: boolDebugYN)
                holdFunc(offDataObj: dataOfflineToModify, offlineDataLength: offlineDataLength, offlineDataFile: offlineDataFile, logPath: logPath)
                return
            } else {
                totalRecordCnt += 1
                var dataOfflineResult = offlineDataResult
                dataOfflineResult["od"] = 1
                
                if (dataOfflineResult["mt"] != nil) || dataOfflineResult["mt"] as? Int == 0 {
                    publishTopicOnMQTT(withData: dataOfflineResult)
                } else {
                    if dataOfflineResult["cpId"] != nil {
                        dataOfflineResult.removeValue(forKey: "cpId")
                    }
                    publishTwinPropertyDataOnMQTT(withData: dataOfflineResult)
                }
                dataOfflineToModify[indX] = [:]
                if(actualDataLength == totalRecordCnt) {
                    dataOfflineToModify = dataOfflineToModify.filter { (obj) -> Bool in
                        return obj.count > 0
                    }
                    print("CNT-After-2: ", dataOfflineToModify.count)
                    objCommon.manageDebugLog(code: Log.Info.INFO_OS06, uniqueId: strUniqueID, cpId: strCPID, message:String(format: "\(Log.Info.INFO_OS06)\(totalRecordCnt) / \(actualDataLength)"), logFlag: true, isDebugEnabled: boolDebugYN)
                    isRunningOfflineSending = false
                    totalRecordCnt = 0
                    
                    deleteFile(logPath: logPath, deleteFilePath: offlineDataFile)
                }
            }
            indX += 1
        }
    }
    private func holdFunc(offDataObj: [[String: Any]], offlineDataLength: Int, offlineDataFile: String, logPath: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + SDKConstants.holdOfflineDataTime) {
            self.sendOfflineDataProcess(offDataObj: offDataObj, offlineDataLength: offlineDataLength, offlineDataFile: offlineDataFile, logPath: logPath)
        }
    }
    //MARK: - Publish Data On MQTT
    func publishTopicOnMQTT(withData dictSDKToHub: [String: Any]) {
        print("publishTopicOnMQTT: \(dictSDKToHub)")
        do {
            let jsonData =  try JSONSerialization.data(withJSONObject: dictSDKToHub, options: .prettyPrinted)
            let  message = String(data: jsonData, encoding: .utf8)!
            publishDataOnMQTT(dictSDKToHubForOS: dictSDKToHub, strPubTopic: dataSyncResponse[keyPath:"p.pub"] as! String, strMessageToPass: message)
        } catch let error {
            print("parse error: \(error.localizedDescription)")
            objCommon.manageDebugLog(code: Log.Errors.ERR_CM01, uniqueId: strUniqueID, cpId: strCPID, message: error.localizedDescription, logFlag: false, isDebugEnabled: boolDebugYN)
        }
    }
    func publishTwinPropertyDataOnMQTT(withData dictSDKToHub: [String: Any]) {
        print("publishTwinPropertyDataOnMQTT: \(dictSDKToHub)")
        do {
            let jsonData =  try JSONSerialization.data(withJSONObject: dictSDKToHub, options: .prettyPrinted)
            let  message = String(data: jsonData, encoding: .utf8)!
            publishDataOnMQTT(dictSDKToHubForOS: dictSDKToHub, strPubTopic: SDKConstants.TwinPropertyPubTopic, strMessageToPass: message)
            if mqtt?.connState == .connected {
                objCommon.manageDebugLog(code: Log.Info.INFO_TP01, uniqueId: strUniqueID, cpId: strCPID, message: "", logFlag: true, isDebugEnabled: boolDebugYN)
            } else {
                objCommon.manageDebugLog(code: Log.Errors.ERR_TP02, uniqueId: strUniqueID, cpId: strCPID, message: "", logFlag: false, isDebugEnabled: boolDebugYN)
            }
        } catch let error {
            print("parse error: \(error.localizedDescription)")
            objCommon.manageDebugLog(code: Log.Errors.ERR_TP01, uniqueId: strUniqueID, cpId: strCPID, message: error.localizedDescription, logFlag: false, isDebugEnabled: boolDebugYN)
        }
    }
    private func publishDataOnMQTT(dictSDKToHubForOS: [String: Any], strPubTopic: String, strMessageToPass: String) {
        autoreleasepool {
            if (boolIsInternetAvailableYN) {
                if mqtt?.connState == .connected {
                    mqtt!.publish(strPubTopic, withString: strMessageToPass, qos: .qos1)
                    objCommon.manageDebugLog(code: Log.Info.INFO_SD01, uniqueId: strUniqueID, cpId: strCPID, message: "", logFlag: true, isDebugEnabled: boolDebugYN)
                } else {
                    objCommon.manageDebugLog(code: Log.Errors.ERR_SD10, uniqueId: strUniqueID, cpId: strCPID, message: "", logFlag: false, isDebugEnabled: boolDebugYN)
                }
            } else {
                if !dataSDKOptions.OfflineStorage.Disabled {
                    offlineProcess(dictSDKToHubForOS)
                }
            }
        }
    }
    func getAllTwins() {
        autoreleasepool {
            if mqtt?.connState == .connected {
                mqtt!.publish(SDKConstants.TwinResponsePubTopic, withString: "", qos: .qos1)
                objCommon.manageDebugLog(code: Log.Info.INFO_TP02, uniqueId: strUniqueID, cpId: strCPID, message: "", logFlag: true, isDebugEnabled: boolDebugYN)
            } else {
                objCommon.manageDebugLog(code: Log.Errors.ERR_TP04, uniqueId: strUniqueID, cpId: strCPID, message: "", logFlag: false, isDebugEnabled: boolDebugYN)
            }
        }
    }
    
    func TRACE(_ message: String = "", fun: String = #function) {
        let names = fun.components(separatedBy: ":")
        var prettyName: String
        if names.count == 2 {
            prettyName = names[0]
        } else {
            prettyName = names[1]
        }
        
        if fun == "mqttDidDisconnect(_:withError:)" {
            prettyName = "didDisconnect"
        }

        print("[TRACE] [\(prettyName)]: \(message)")
    }
}

extension MQTTClient: CocoaMQTTDelegate {
    
    // Optional ssl CocoaMQTTDelegate
    func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        //TRACE("trust: \(trust)")
        completionHandler(true)
    }
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        TRACE("ack: \(ack)")
        if ack == .accept {
            blockHandler?(["sdkStatus": "connect"], 1)
            mqtt.subscribe(dataSyncResponse[keyPath:"p.sub"] as! String, qos: .qos1)
            mqtt.subscribe(SDKConstants.TwinPropertySubTopic, qos: .qos1)
            mqtt.subscribe(SDKConstants.TwinResponseSubTopic, qos: .qos1)
            objCommon.manageDebugLog(code: Log.Info.INFO_IN02, uniqueId: strUniqueID, cpId: strCPID, message: "", logFlag: true, isDebugEnabled: boolDebugYN)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if !self.dataSDKOptions.OfflineStorage.Disabled && self.isRunningOfflineSending == false {
                    self.totalRecordCnt = 0
                    self.checkOfflineData()
                }
            }
            blockHandler?([
                            "cmdType": CommandType.DEVICE_CONNECTION_STATUS,
                            "data": ["cpid": strCPID,
                                     "guid": "",
                                     "uniqueId": strUniqueID,
                                     "command": true,
                                     "ack": false,
                                     "ackId": "",
                                     "cmdType": CommandType.DEVICE_CONNECTION_STATUS]], 2)
        }
    }
    func mqtt(_ mqtt: CocoaMQTT, didStateChangeTo state: CocoaMQTTConnState) {
        TRACE("new state: \(state)")
    }
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        TRACE("Publish message: \(String(describing: message.string?.description)), id: \(id)")
    }
    func mqtt(_ mqtt: CocoaMQTT, didPublishComplete id: UInt16) {
        TRACE("didPublishComplete: id: \(id)")
    }
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        //TRACE("id: \(id)")
    }
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        TRACE("message: \(String(describing: message.string)), id: \(id)")
        if let data = message.string?.data(using: .utf8), message.string?.count != 0 {
            let errorParse: Error? = nil
            let objectMessageData = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            var boolCanProceedYN:Bool = true
            if objectMessageData == nil {
                print("Error parsing New Message: \(String(describing: errorParse))")
            } else {
                print("Success New Message: \(String(describing: objectMessageData))")
                if  let objectMessage = objectMessageData as? [String:Any]  {
                    if message.topic.hasPrefix(objCommon.getSubStringFor(strToProcess: SDKConstants.TwinPropertySubTopic, indStart: 0, indEnd: -1)) {
                        blockHandler?(objectMessage, 4)
                        boolCanProceedYN = false
                    } else if message.topic.hasPrefix(objCommon.getSubStringFor(strToProcess: SDKConstants.TwinResponseSubTopic, indStart: 0, indEnd: -1)) {
                        blockHandler?(objectMessage, 5)
                        boolCanProceedYN = false
                    } else {
                        if objectMessage["cmdType"] as! String == CommandType.CORE_COMMAND {//...DeviceCommand
                            
                            objCommon.manageDebugLog(code: Log.Info.INFO_CM01, uniqueId: strUniqueID, cpId: strCPID, message: "", logFlag: true, isDebugEnabled: boolDebugYN)
                            blockHandler?(objectMessage, 2)
                            boolCanProceedYN = false
                            
                        } else if objectMessage["cmdType"] as! String == CommandType.FIRMWARE_UPDATE {//...FirmwareUpgrade
                            
                            objCommon.manageDebugLog(code: Log.Info.INFO_CM02, uniqueId: strUniqueID, cpId: strCPID, message: "", logFlag: true, isDebugEnabled: boolDebugYN)
                            blockHandler?(objectMessage, 2)
                            boolCanProceedYN = false
                            
                        } else if [CommandType.ATTRIBUTE_INFO_UPDATE, CommandType.SETTING_INFO_UPDATE, CommandType.PASSWORD_INFO_UPDATE, CommandType.DEVICE_INFO_UPDATE, CommandType.DATA_FREQUENCY_UPDATE].contains(objectMessage["cmdType"] as! String) {
                            
                            if CommandType.ATTRIBUTE_INFO_UPDATE == objectMessage["cmdType"] as! String {
                                objCommon.manageDebugLog(code: Log.Info.INFO_CM03, uniqueId: strUniqueID, cpId: strCPID, message: "", logFlag: true, isDebugEnabled: boolDebugYN)
                            } else if CommandType.SETTING_INFO_UPDATE == objectMessage["cmdType"] as! String {
                                objCommon.manageDebugLog(code: Log.Info.INFO_CM04, uniqueId: strUniqueID, cpId: strCPID, message: "", logFlag: true, isDebugEnabled: boolDebugYN)
                            } else if CommandType.PASSWORD_INFO_UPDATE == objectMessage["cmdType"] as! String {
                                objCommon.manageDebugLog(code: Log.Info.INFO_CM05, uniqueId: strUniqueID, cpId: strCPID, message: "", logFlag: true, isDebugEnabled: boolDebugYN)
                            } else if CommandType.DEVICE_INFO_UPDATE == objectMessage["cmdType"] as! String {
                                objCommon.manageDebugLog(code: Log.Info.INFO_CM06, uniqueId: strUniqueID, cpId: strCPID, message: "", logFlag: true, isDebugEnabled: boolDebugYN)
                            } else if CommandType.DATA_FREQUENCY_UPDATE == objectMessage["cmdType"] as! String {
                                objCommon.manageDebugLog(code: Log.Info.INFO_CM11, uniqueId: strUniqueID, cpId: strCPID, message: "", logFlag: true, isDebugEnabled: boolDebugYN)
                            }
                            
                            blockHandler?(objectMessage["cmdType"] as! String, 3)
                            boolCanProceedYN = false
                            
                        } else if objectMessage["cmdType"] as! String == CommandType.STOP_SDK_CONNECTION {
                            
                            objCommon.manageDebugLog(code: Log.Info.INFO_CM08, uniqueId: strUniqueID, cpId: strCPID, message: "", logFlag: true, isDebugEnabled: boolDebugYN)
                            blockHandler?(CommandType.STOP_SDK_CONNECTION, 6)
                            boolCanProceedYN = false
                            
                        }
                    }
                }
            }
            if boolCanProceedYN {
                blockHandler?(objectMessageData, 1)
            }
        }
    }
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
        TRACE("subscribed: \(success), failed: \(failed)")
    }
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {
        TRACE("topic: \(topics)")
    }
    func mqttDidPing(_ mqtt: CocoaMQTT) {
        //TRACE()
    }
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        //TRACE()
    }
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        TRACE("mqttDidDisconnect: \(err.debugDescription)")
        objCommon.manageDebugLog(code: Log.Errors.ERR_IN14, uniqueId: strUniqueID, cpId: strCPID, message: "", logFlag: false, isDebugEnabled: boolDebugYN)
        blockHandler?(["cmdType": CommandType.DEVICE_CONNECTION_STATUS,
                       "data": ["cpid": strCPID,
                                "guid": "",
                                "uniqueId": strUniqueID,
                                "command": false,
                                "ack": false,
                                "ackId": "",
                                "cmdType": CommandType.DEVICE_CONNECTION_STATUS]], 2)
        objCommon.manageDebugLog(code: Log.Info.INFO_IN03, uniqueId: strUniqueID, cpId: strCPID, message: "", logFlag: true, isDebugEnabled: boolDebugYN)
        blockHandler?(["sdkStatus": "error"], 1)
    }
}
