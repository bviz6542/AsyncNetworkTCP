//
//  RequestModel.swift
//  AsyncNetworkTCP
//
//  Created by 정준우 on 2/29/24.
//

struct RequestModel<T: Codable>: Codable {
    let organizationID: String = FileHandler.getInstance().getFileValue(FILEKEY_CAREORGID)
    let authCode: String = FileHandler.getInstance().getFileValue(FILEKEY_ACCEPTNO)
    let command: String
    let inputData: T?
    
    private enum CodingKeys: String, CodingKey {
        case organizationID = "OrgID"
        case authCode = "AuthCode"
        case command = "ExecCommand"
        case inputData = "InputData"
    }
}
