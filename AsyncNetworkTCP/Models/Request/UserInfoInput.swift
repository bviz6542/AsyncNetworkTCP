//
//  UserInfoInput.swift
//  AsyncNetworkTCP
//
//  Created by 정준우 on 2/29/24.
//

import Foundation

struct UserInfoInput: Codable {
    let userCode: String
    let name: String
    let gender: String
    let phoneNumber: String
    let image: Data
    
    private enum CodingKeys: String, CodingKey {
        case userCode = "UserCd"
        case name = "Name"
        case gender = "Gender"
        case phoneNumber = "CellPhoneNumber"
        case image = "Img"
    }
}
