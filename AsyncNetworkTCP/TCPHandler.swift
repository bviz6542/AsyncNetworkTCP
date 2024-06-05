//
//  TCPHandler.swift
//  AsyncNetworkTCP
//
//  Created by 정준우 on 2/29/24.
//

import Network
import XMLCoder

final class TCPHandler {
    func handleAsyncTCP<InputType: Codable, OutputType: Codable> (
        sendTo kindsOfSocket: TCPSocketAddress,
        command: TCPCommand,
        inputParameter: InputType?,
        inputData: InputType.Type,
        outputData: OutputType.Type
    ) async -> Swift.Result<OutputType, Error> {
        
        var connection: NWConnection?
        do {
            let addressInfo = try resolveAddress(using: kindsOfSocket)
            connection = makeConnection(using: addressInfo)
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
    
    private func resolveAddress(using kindsOfSocket: TCPSocketAddress) throws -> (host: NWEndpoint.Host, port: NWEndpoint.Port) {
        let (ip, port) = kindsOfSocket.socketAddress
        guard let convertedPort = NWEndpoint.Port(rawValue: UInt16(port)) else { throw TCPError.connectionError }
        
        var hints = addrinfo()
        hints.ai_family = AF_UNSPEC
        hints.ai_socktype = SOCK_STREAM
        
        var res: UnsafeMutablePointer<addrinfo>?
        let serverPort = String(port)
        
        let result = getaddrinfo(ip, serverPort, &hints, &res)
        guard result == 0, let resList = res else { throw TCPError.addressResolveError }
        
        defer { freeaddrinfo(resList) }
        
        for addr in sequence(first: resList, next: { $0.pointee.ai_next }) {
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(addr.pointee.ai_addr, socklen_t(addr.pointee.ai_addrlen), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                let convertedHost = NWEndpoint.Host(String(cString: hostname))
                return (host: convertedHost, port: convertedPort)
            }
        }
        
        throw TCPError.addressResolveError
    }
    
    private func makeConnection(using addressInfo: (host: NWEndpoint.Host, port: NWEndpoint.Port)) -> NWConnection {
        let options = NWProtocolTCP.Options()
        options.connectionTimeout = 3
        let parameters = NWParameters(tls: nil, tcp: options)
        return NWConnection(host: addressInfo.host, port: addressInfo.port, using: parameters)
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

        guard responseModel.result == TCP_SUCCESS else {
            guard let errorContents = responseModel.errorContents else { throw TCPError.responseUnexpectedFormatError }
            switch errorContents {
            case TCP_ERROR_XML_PARSE_ERROR:
                throw TCPError.responseXMLParseError
            case TCP_ERROR_BAD_ORG_ID:
                throw TCPError.responseBadOrgIDError
            case TCP_ERROR_BAD_AUTH_CODE:
                throw TCPError.responseBadAuthCodeError
            case TCP_ERROR_BAD_EXEC_COMMAND:
                throw TCPError.responseBadExecCommandError
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
