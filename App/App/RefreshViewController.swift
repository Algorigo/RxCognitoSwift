//
//  RefreshViewController.swift
//  App
//
//  Created by Jaehong Yoo on 2020/09/03.
//  Copyright © 2020 Algorigo. All rights reserved.
//

import UIKit
import RxCognito
import RxSwift

class RefreshViewController: UIViewController {
    
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var newPasswordTextField: UITextField!
    @IBOutlet weak var resultTetView: UITextView!
    
    private let disposeBag = DisposeBag()
    private var cognitoUser: CognitoUser? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        refresh()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    fileprivate func refresh() {
        CognitoStore.cognito.getCurrentUser()
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] (event) in
                switch event {
                case .success(let user):
                    self?.cognitoUser = user
                    self?.resultTetView.text = "\(user.getIdToken())"
                case .completed:
                    Log.d("RefreshViewController", "complete")
                    self?.cognitoUser = nil
                    self?.resultTetView.text = "no user"
                case .error(let error):
                    Log.e("RefreshViewController", "cognito error:\(error)")
                }
            }
            .disposed(by: disposeBag)
    }
    
    @IBAction func handleChangePassword(_ sender: Any) {
        if let password = passwordTextField.text,
            !password.isEmpty,
            let newPassword = newPasswordTextField.text,
            !newPassword.isEmpty {
            cognitoUser?.changePassword(password: password, newPassword: newPassword)
                .observeOn(MainScheduler.instance)
                .subscribe { [weak self] (event) in
                    switch event {
                    case .completed:
                        Log.d("RefreshViewController", "completed")
                        self?.resultTetView.text = "password change success"
                    case .error(let error):
                        Log.e("RefreshViewController", "cognito error:\(error)")
                    }
                }
                .disposed(by: disposeBag)
        }
    }
    
    @IBAction func handleRefresh(_ sender: Any) {
        refresh()
    }
    
}

extension RefreshViewController : UITextFieldDelegate {
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
