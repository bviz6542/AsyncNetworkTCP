//
//  MainViewController.swift
//  AsyncNetworkTCP
//
//  Created by 정준우 on 2/29/24.
//

import UIKit

class MainViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Task {
            let imageData = UIImage(systemName: "pencil.line")!.pngData()!
            let input = UserInfoInput(userCode: "110001", name: "mraz", gender: "male", phoneNumber: "040-8877-8223", image: imageData)
            
            await TCPHandler().handleAsyncTCP(
                sendTo: .aSocket,
                command: .createUser,
                inputParameter: nil,
                inputData: EmptyInput.self, outputData: EmptyOutput.self)
            .onFailure { error in
                print(error)
            }
            .onSuccess { output in
                print("succeeded tcp")
            }
        }
    }
}
