//
//  TCPCommand.swift
//  AsyncNetworkTCP
//
//  Created by 정준우 on 2/29/24.
//

enum TCPCommand: String {
    case createUser = "REQ_CREATE_USER"
    case fetchUser = "REQ_FETCH_USER"
    case fetchUsers = "REQ_FETCH_USERS"
    case updateUser = "REQ_UPDATE_USER"
    case deleteUser = "REQ_DELETE_USER"
}
