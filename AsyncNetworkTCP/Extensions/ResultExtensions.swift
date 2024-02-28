//
//  ResultExtensions.swift
//  AsyncNetworkTCP
//
//  Created by 정준우 on 2/29/24.
//

import Foundation

extension Result {
    
    func getOrNull() -> Success? {
        switch self {
        case .success(let result):
            return result
        case .failure(_):
            return nil
        }
    }
    
    func getOrDefault(defaultValue : Success) -> Success {
        switch self {
        case.success(let result):
            return result
        case.failure(_):
            return defaultValue
        }
    }
    
    func onFailure(handle : (Failure) -> Void) -> Result<Success, Failure>  {
        switch self {
        case .failure(let error):
            handle(error)
            break;
        case .success(_):
            break;
        }
        return self
    }
    
    @discardableResult
    func onSuccess(handle: (Success) -> Void) -> Result<Success, Failure> {
        switch self {
        case .success(let output):
            handle(output)
            break;
        case .failure(_):
            break;
        }
        return self
    }
}
