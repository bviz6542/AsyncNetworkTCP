//
//  TCPSocketAddress.swift
//  AsyncNetworkTCP
//
//  Created by 정준우 on 2/29/24.
//

enum TCPSocketAddress {
    case aSocket
    case bSocket
    case newSocket(newIP: String, newPort: Int32)
    
    var socketAddress: (String, Int32) {
        switch self {
        case .aSocket:
            return (TCPSocketAddressHolder.shared.aSocketIP, TCPSocketAddressHolder.shared.aSocketPort)
        case .bSocket:
            return (TCPSocketAddressHolder.shared.bSocketIP, TCPSocketAddressHolder.shared.bSocketPort)
        case .newSocket(let ip, let port):
            return (ip, port)
        }
    }
}
