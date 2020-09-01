//
//  ViewController.swift
//  App
//
//  Created by Jaehong Yoo on 2020/08/31.
//  Copyright © 2020 Algorigo. All rights reserved.
//

import UIKit
import RxCognito

class ViewController: UIViewController {

    @IBOutlet weak var accessKeyIdTextField: UITextField!
    @IBOutlet weak var secretAccessKeyTextField: UITextField!
    @IBOutlet weak var regionPickerView: UIPickerView!
    @IBOutlet weak var userPoolIdTextField: UITextField!
    @IBOutlet weak var appClientIdTextField: UITextField!
    @IBOutlet weak var appClientSecretTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let defaults = UserDefaults.standard
        accessKeyIdTextField.text = defaults.string(forKey: "AccessKeyId")
        secretAccessKeyTextField.text = defaults.string(forKey: "SecretAccessKey") ?? ""
        regionPickerView.selectRow(defaults.integer(forKey: "Regions"), inComponent: 0, animated: false)
        userPoolIdTextField.text = defaults.string(forKey: "UserPoolId") ?? ""
        appClientIdTextField.text = defaults.string(forKey: "AppClientId") ?? ""
        appClientSecretTextField.text = defaults.string(forKey: "AppClientSecret") ?? ""
    }

    fileprivate func initiate(accessKeyId: String, secretAccessKey: String, regions: Regions, userPoolId: String, appClientId: String, appClientSecret: String) {
        RxCognito.instance.initialize(accessKeyId: accessKeyId, secretAccessKey: secretAccessKey, regions: regions, userPoolId: userPoolId, appClientId: appClientId, appClientSecret: appClientSecret)
    }
    
    @IBAction func handleInitiate() {
        if let accessKeyId = accessKeyIdTextField.text,
            !accessKeyId.isEmpty,
            let secretAccessKey = secretAccessKeyTextField.text,
            !secretAccessKey.isEmpty,
            let userPoolId = userPoolIdTextField.text,
            !userPoolId.isEmpty,
            let appClientId = appClientIdTextField.text,
            !appClientId.isEmpty,
            let appClientSecret = appClientSecretTextField.text,
            !appClientSecret.isEmpty {
            let index = regionPickerView.selectedRow(inComponent: 0)
            let regions = Regions.allCases[index]
            
            initiate(accessKeyId: accessKeyId, secretAccessKey: secretAccessKey, regions: regions, userPoolId: userPoolId, appClientId: appClientId, appClientSecret: appClientSecret)
            
            let defaults = UserDefaults.standard
            defaults.set(accessKeyId, forKey: "AccessKeyId")
            defaults.set(secretAccessKey, forKey: "SecretAccessKey")
            defaults.set(index, forKey: "Regions")
            defaults.set(userPoolId, forKey: "UserPoolId")
            defaults.set(appClientId, forKey: "AppClientId")
            defaults.set(appClientSecret, forKey: "AppClientSecret")
            
            if let loginVC = self.storyboard?.instantiateViewController(identifier: "LoginVC") {
            
                loginVC.modalTransitionStyle = .coverVertical
                self.present(loginVC, animated: true, completion: nil)
            }
        } else {
            let alertController = UIAlertController(title: title, message: "Not Enough Information", preferredStyle: UIAlertController.Style.alert)

            let okButton = UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil)

            alertController.addAction(okButton)

            self.present(alertController, animated: true, completion: nil)
        }
    }
}

extension ViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Regions.allCases.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Regions.allCases[row].getName()
    }
}

