//
//  Attributes.swift
//  IoTConnectDemo
//
//  Created by kirtan.vaghela on 20/06/23.
//

import Foundation

struct Attributes: Codable {
    var d: AttributesData?
}

struct AttributesData: Codable {
    var att: [Att]?
    let ct: Int?
    let dt: String?
    let ec: Int?
}

// MARK: - Att
struct Att: Codable {
    var d: [AttData]?
    let dt: Int?
    let p,tg: String?
}

struct AttData: Codable {
    let dt: Int?
    let dv, ln,tw,tg: String?
    let sq: Int?
    var p:String? = ""
    var value:String?
}
