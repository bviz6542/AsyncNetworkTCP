//
//  ResponseModel.swift
//  AsyncNetworkTCP
//
//  Created by 정준우 on 2/29/24.
//

struct ResponseModel<T: Codable>: Codable {
    let result: String
    let errorContents: String?
    let outputData: T?
    
    private enum CodingKeys: String, CodingKey {
        case result = "Result"
        case errorContents = "ErrorContents"
        case outputData = "OutputData"
    }
}
