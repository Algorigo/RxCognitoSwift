//
//  LoginViewController.swift
//  App
//
//  Created by Jaehong Yoo on 2020/09/01.
//  Copyright © 2020 Algorigo. All rights reserved.
//

import UIKit
import RxCognito
import RxSwift

class LoginViewController: UIViewController {

    @IBOutlet weak var idTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var resultTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        idTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    @IBAction func handleLoginBtn() {
        if let userId = idTextField.text,
            let password = passwordTextField.text {
            _ = CognitoStore.cognito.login(userId: userId, password: password)
                .observeOn(MainScheduler.instance)
                .subscribe { [weak self] (event) in
                    switch (event) {
                    case .success(let cognitoUser):
                        self?.resultTextView.text = "\(cognitoUser.getIdToken())"
                    case .error(let error):
                        Log.e("LoginViewController", "error:\(error)")
                    }
                }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension LoginViewController : UITextFieldDelegate {
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
