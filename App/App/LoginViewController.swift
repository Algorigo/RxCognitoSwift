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
    }
    
    @IBAction func handleLoginBtn() {
        if let userId = idTextField.text,
            let password = passwordTextField.text {
            _ = RxCognito.instance.login(userId: userId, password: password)
                .observeOn(MainScheduler.instance)
                .subscribe { [weak self](event) in
                    switch (event) {
                    case .completed:
                        print("completed")
                        self?.resultTextView.text = "\(RxCognito.instance.currentUser)"
                    case .error(let error):
                        print("error:\(error)")
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
