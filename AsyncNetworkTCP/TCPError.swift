//
//  TCPError.swift
//  AsyncNetworkTCP
//
//  Created by 정준우 on 2/29/24.
//

enum TCPError: Error{
    case requestConfigurationError
    case responseUnexpectedFormatError
    case responseCommandSpecificCustomError(String)
    case responseXMLParseError
    case responseBadClientIDError
    case responseBadCommandError
    case responseOutputNilError
    case connectionError
    case sendRequestError
}
