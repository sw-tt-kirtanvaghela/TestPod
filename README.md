# IOT Connect SDK: iotconnect-iOS-sdk(Device Message 2.1)

This is iOS library to connect with IoTConnect cloud by MQTT
This library only abstract JSON responses from both end D2C and C2D

IoTConnect Device SDKs (System Development Kit) are highly secure and reliable, solving the purpose of D2C (device to cloud) and C2D (cloud to device) communications. It is a mediator between device and cloud platforms.

IoTConnect Device SDKs help you to easily and quickly connect your devices to IoTConnect. IoTConnect Device SDKs include a set of tools, libraries, developer guides with code samples, and porting guides. IoTConnect SDK is a full-fledged workshop for you to build innovative IoT products or solutions on your choice of hardware platforms.

## Features

* The SDK supports to send telemetry data and receive commands from IoTConnect portal.
* User can update firmware Over The Air using "OTA update" Feature supported by SDK.
* SDK support SAS authentication as well as Certificate Authority(CA) Signed and Self Signed authentication.  
* SDK consists of Gateway device with multiple child devices support.
* SDK supports to receive and update the Twin property. 
* SDK supports device and OTA command acknowledgment.
* Edge device support with data aggregation.
* Provide device connection status receive by command.
* Support hard stop command to stop device client from cloud.
* It allows sending the OTA command acknowledgment for Gateway and child device.
* It manages the sensor data sending flow over the cloud by using data frequency("df") configuration.
* It allows to disconnect the device from firmware.
* Offline Storage is used to store device data in a text file when the internet is not available.

# Example Usage:

-Prerequisite input data *

* "uniqueId"     : Your device uniqueId
* "cpId"         : It is the company code. It gets from the IoTConnect UI portal "Settings->Key Vault"
* "environment"         : pass environment type from mentioned enum(EnvironmentType) i.e. AVNET, DEV, QA, PROD, POC, PREQA

- SdkOptions is for the SDK configuration and needs to parse in SDK object initialize call. You need to manage the below configuration as per your device authentication type.

- public struct SDKClientOption {
    
    //For SSL CA signed and SelfSigned authorized device only
    public var ssl = SSLOption()
    
    //For Offline Storage only
    public var offlineStorage = OfflineStorageOption()
    
    //For Developer only
    public var discoveryUrl: String?
    public var debug: Bool = false
    public var skipValidation = false
    
    //device PK
    public var devicePK = ""
   
    //broker options
    public var brokerType: BrokerType?{
        didSet{
            if brokerType == .aws{
                enum Env:String{
                    case a = "a"
                    case b  = "b"
                }
            }else if brokerType == .az{
                enum Env:String{
                    case c = "a"
                    case d  = "b"
                }
            }
        }
    }
    
    //MARK: - Method - SDK-Initialiase
    public init () {}
}

- Create object for SDKClientOption and init values

* "brokerType": pass broker type either AZ or AWS from mentioned enum(BrokerType)
* "devicePK":  If authentication type is symmetric key then use it.
* "skipValidation": false = do not want to skip data validation for attributes, true= want to skip data validation for attributes
* "SSLOption": It is indicated to define the path of the certificate file. Mandatory for X.509/SSL device CA signed or self-signed authentication type only.
    - certificatePath: your device certificate path
    - password: your device certificate password
* "offlineStorage" : Define the configuration related to the offline data storage 
    - disabled : false = offline data storing, true = not storing offline data 
    - availSpaceInMb : Define the file size of off-line data which should be in (MB)
    - fileCount : Number of files need to create for off-line data
   
            > ****Note**:-**  In sdkOptions it is mandatory to pass broker type, and define other setting acording to needs. 
If you do not provide off-line storage, it will set the default settings as per defined above. It may harm your device by storing the large data. Once memory gets full may chance to stop the execution.

- To Initialize the SDK object and connect to the cloud.
```
            let objConfig = IoTConnectConfig(cpId: txtCPID.text?.replacingOccurrences(of: " ", with: "") ?? "", uniqueId: txtUniqueID.text?.replacingOccurrences(of: " ", with: "")  ?? "", env: env, mqttConnectionType: .userCredntialAuthentication, sdkOptions: sdkOptions)
            
            SDKClient.shared.initialize(config: objConfig)
```

- To receive the command from Cloud to Device(C2D).

```
                SDKClient.shared.getDeviceCallBack { (message) in
                
                
                }

```

- To receive Device Command C2D(C2D)
```
                SDKClient.shared.onDeviceCommand { message in
                
                }
```

- To receive OTA Command(C2D)
```
                SDKClient.shared.onOTACommand { message in
                
                }
```

- To receive Module Command(C2D)
```
                SDKClient.shared.onModuleCommand { message in
                
                }
```

- To receive Attributes Change Command(C2D)

```
                SDKClient.shared.onAttrChangeCommand { message in
                
                
                }

```

- To receive Twin Change Command(C2D)

```
            SDKClient.shared.onTwinChangeCommand { (twinMessage) in
            
            
            }

```

- To receive Rule Change Command(C2D)
```
            SDKClient.shared.onRuleChangeCommand { response in
            
            }
```

- To receive Device Change Command(C2D)
```
            SDKClient.shared.onDeviceChangeCommand { response in
            
            }

```

- To get the list of attributes with respective device.
```
            SDKClient.shared.getAttributes { attrinuteResponse in
                
            }
```

- To get the all twin property Desired and Reported
```
        SDKClient.shared.getAllTwins()

```

- To get the child devices
```
        SDKClient.shared.getChildDevices { response in
        
        }

```

- To create child device
```
            SDKClient.shared.createChildDevice(deviceId: <Device_Id>, deviceTag:<Device_Tag>, displayName:  <Display_Name>, createChildCallBack:{ (response) in
            
            }
```

- To delete child device
```
            SDKClient.shared.deleteChildDevice(deviceId:<Device_ID>) { response in
            
            }
```

- This is the standard data input format for Gateway and non Gateway device to send the data on IoTConnect cloud(D2C).
```
     ["d":
      [
        [
       "d":
     [
      <ln>: <value>],
      "dt": <dateTime>, "id": <id>, "tg": <tag>
     ]
       ],
        "dt": <dateTime>
       ]
```
            



## Third party Frameworks Used
- [CocoaMQTT] (https://github.com/emqx/CocoaMQTT) for MQTTClient connection
- [Starscream] (https://github.com/nuclearace/Starscream) for Websocket library
- [CocoaAsyncSocket] (https://github.com/robbiehanson/CocoaAsyncSocket) for socket library

## Build Details
- IDE
- - Please use Xcode 12.4 to compile
- Targets
- - IoTConnect
- - IoTConnectDemo
- Key Branches
- -  **develop:** contains the latest dev code.
- - **master:** this contains the code for the current app store release.

## Usage

```Swift
import IoTConnect

let objConfig = IoTConnectConfig(cpId: "{replace-with-your-id}",
                                         uniqueId: "{replace-with-your-id}",
                                         env: .QA,
                                         mqttConnectionType: .userCredntialAuthentication,
                                         sdkOptions: nil)
SDKClient.shared.initialize(config: objConfig)

SDKClient.shared.getDeviceCallBack { (message) in
  print("message: ", message as Any)
}

SDKClient.shared.getTwinUpdateCallBack { (twinMessage) in
  print("twinMessage: ", twinMessage as Any)
}

```


## License
[Softweb Proprietor](https://www.softwebsolutions.com)
