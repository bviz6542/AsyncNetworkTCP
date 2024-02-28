//
//  TCPHandler.swift
//  AsyncNetworkTCP
//
//  Created by 정준우 on 2/29/24.
//

import Foundation
import Network
import XMLCoder

final class TCPHandler {
    func handleAsyncTCP<InputType: Codable, OutputType: Codable> (
        sendTo kindsOfSocket: TCPSocketAddress,
        command: TCPCommand,
        inputParameter: InputType?,
        inputData: InputType.Type,
        outputData: OutputType.Type
    ) async -> Result<OutputType, Error> {
        
        var connection: NWConnection?
        do {
            connection = makeConnection(using: kindsOfSocket)
            guard let connection = connection else { throw TCPError.connectionError }
            connection.start(queue: .global())
            try await checkConnectionState(using: connection)
            let requestData = try makeRequest(command: command, inputParameter: inputParameter)
            try await sendRequest(using: connection, requestData: requestData)
            let responseData = try await receiveMessage(using: connection)
            let resultOutput = try parseAndFetchResponseData(outputType: outputData.self, data: responseData)
            connection.cancel()
            return .success(resultOutput)
        } catch {
            connection?.cancel()
            return .failure(error)
        }
    }
    
    private func makeConnection(using kindsOfSocket: TCPSocketAddress) -> NWConnection? {
        let (ip, port) = kindsOfSocket.socketAddress
        let host = NWEndpoint.Host(ip)
        guard let port = NWEndpoint.Port(rawValue: UInt16(port)) else { return nil }
        let options = NWProtocolTCP.Options()
        options.connectionTimeout = 3
        let parameters = NWParameters(tls: nil, tcp: options)
        return NWConnection(host: host, port: port, using: parameters)
    }
    
    private func checkConnectionState(using connection: NWConnection) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            connection.stateUpdateHandler = { state in
                switch state {
                case .failed(_):
                    continuation.resume(throwing: TCPError.connectionError)
                case .waiting(_):
                    continuation.resume(throwing: TCPError.connectionError)
                case .ready:
                    continuation.resume()
                default:
                    break
                }
            }
        }
    }
    
    private func makeRequest<InputType: Codable>(command: TCPCommand, inputParameter: InputType) throws -> Data {
        let requestModel = RequestModel(command: command.rawValue, inputData: inputParameter)
        let header = XMLHeader(version: 1.0, encoding: "UTF-8", standalone: "yes")
        if let data = try? XMLEncoder().encode(requestModel, withRootKey: "Request", header: header) {
            return data
        } else {
            throw TCPError.requestConfigurationError
        }
    }
    
    private func sendRequest(using connection: NWConnection, requestData: Data) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let completion = NWConnection.SendCompletion.contentProcessed { error in
                if error != nil {
                    continuation.resume(throwing: TCPError.sendRequestError)
                } else {
                    continuation.resume()
                }
            }
            connection.send(content: requestData, completion: completion)
        }
    }
    
    
    private func receiveMessage(using connection: NWConnection) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            connection.receiveMessage { content, contentContext, isComplete, error in
                if let data = content, !data.isEmpty { continuation.resume(returning: data) }
                else { continuation.resume(throwing: TCPError.responseUnexpectedFormatError) }
            }
        }
    }
    
    private func parseAndFetchResponseData<OutputType: Codable>(outputType: OutputType.Type, data: Data) throws -> OutputType {
        guard let responseModel = try? XMLDecoder().decode(ResponseModel<OutputType>.self, from: data) else {
            throw TCPError.responseXMLParseError
        }
        
        guard responseModel.result == "OK" else {
            guard let errorContents = responseModel.errorContents else { throw TCPError.responseUnexpectedFormatError }
            switch errorContents {
            case "PARSE_FAILED":
                throw TCPError.responseXMLParseError
            case "BAD_CLIENT_ID":
                throw TCPError.responseBadClientIDError
            case "BAD_COMMAND":
                throw TCPError.responseBadCommandError
            default:
                throw TCPError.responseCommandSpecificCustomError(errorContents)
            }
        }
        
        if let outputData = responseModel.outputData {
            return outputData
        } else if let emptyOutput = EmptyOutput() as? OutputType {
            return emptyOutput
        } else {
            throw TCPError.responseOutputNilError
        }
    }
}
