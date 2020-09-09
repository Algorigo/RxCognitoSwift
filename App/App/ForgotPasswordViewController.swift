//
//  ForgotPasswordViewController.swift
//  App
//
//  Created by Jaehong Yoo on 2020/09/09.
//  Copyright © 2020 Algorigo. All rights reserved.
//

import UIKit
import RxSwift
import RxCognito

class ForgotPasswordViewController: UIViewController {

    enum Step {
        case sendVerification
        case changePassword(continuation: ForgotPasswordContinuation)
    }
    
    @IBOutlet weak var userIdTextField: UITextField!
    @IBOutlet weak var verificationTextField: UITextField!
    @IBOutlet weak var newPasswordTextField: UITextField!
    
    fileprivate var step = Step.sendVerification
    
    fileprivate var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        userIdTextField.delegate = self
        verificationTextField.delegate = self
        newPasswordTextField.delegate = self
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func handleNextStep(_ sender: Any) {
        switch step {
        case .sendVerification:
            if let userId = userIdTextField.text {
                CognitoStore.cognito.forgotPassword(userId: userId)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onSuccess: { [weak self] (continuation) in
                        self?.userIdTextField.isEnabled = false
                        self?.verificationTextField.isEnabled = true
                        self?.newPasswordTextField.isEnabled = true
                        self?.step = .changePassword(continuation: continuation)
                    }, onError: { (error) in
                        
                    })
                    .disposed(by: disposeBag)
            }
            break
        case .changePassword(let continuation):
            if let verificationCode = verificationTextField.text,
                let newPassword = newPasswordTextField.text {
                CognitoStore.cognito.continueForgotPassword(continuation: continuation, verificationCode: verificationCode, newPassword: newPassword)
                    .observeOn(MainScheduler.instance)
                    .subscribe({ [weak self] (event) in
                        switch event {
                        case .completed:
                            self?.userIdTextField.isEnabled = false
                            self?.verificationTextField.isEnabled = false
                            self?.newPasswordTextField.isEnabled = false
                        case .error(let error):
                            print("error:\(error)")
                        }
                    })
                    .disposed(by: disposeBag)
            }
            break
        }
    }
}

extension ForgotPasswordViewController : UITextFieldDelegate {
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
