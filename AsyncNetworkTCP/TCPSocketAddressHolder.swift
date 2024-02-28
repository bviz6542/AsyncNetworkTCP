//
//  TCPSocketAddressHolder.swift
//  AsyncNetworkTCP
//
//  Created by 정준우 on 2/29/24.
//

class TCPSocketAddressHolder {
    static let shared = TCPSocketAddressHolder()
    private init() {}
    
    var aSocketIP: String = ""
    var aSocketPort: Int32 = 0
    
    var bSocketIP: String = ""
    var bSocketPort: Int32 = 0
}
