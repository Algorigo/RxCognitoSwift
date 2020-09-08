//
//  ResendCodeViewController.swift
//  App
//
//  Created by Jaehong Yoo on 2020/09/09.
//  Copyright © 2020 Algorigo. All rights reserved.
//

import UIKit
import RxSwift

class ResendCodeViewController: UIViewController {

    @IBOutlet weak var userIdTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        userIdTextField.delegate = self
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func handleResendConfirmCode(_ sender: Any) {
        if let userId = userIdTextField.text,
            !userId.isEmpty {
            CognitoStore.cognito.resendConfirmCode(userId: userId)
                .observeOn(MainScheduler.instance)
                .subscribe({ (event) in
                    switch event {
                    case .success(let deliveryMedium):
                        print("success:\(deliveryMedium)")
                    case .error(let error):
                        print("error:\(error)")
                    }
                })
        }
    }
}

extension ResendCodeViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let nextTag = textField.tag + 1
        // Try to find next responder
        if let nextResponder = textField.superview?.viewWithTag(nextTag) {
            nextResponder.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }

        return false
    }
}
