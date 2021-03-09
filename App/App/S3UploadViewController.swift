//
//  S3UploadViewController.swift
//  App
//
//  Created by Jaehong Yoo on 2021/03/09.
//  Copyright © 2021 Algorigo. All rights reserved.
//

import UIKit
import RxSwift
import RxCognito

class S3UploadViewController: UIViewController {

    @IBOutlet weak var bucketTextField: UITextField!
    @IBOutlet weak var keyTextField: UITextField!
    @IBOutlet weak var contentTextView: UITextView!

    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func handleUpload(_ sender: Any) {
        if let bucket = bucketTextField.text,
           let key = keyTextField.text {
            CognitoStore.cognito.putObject(bucket: bucket, key: key, data: contentTextView.text.data(using: .utf8)!)
                .subscribe { [weak self] in
                    print("onCompleted")
                    self?.contentTextView.text = "onCompleted"
                } onError: { [weak self] (error) in
                    print("onError:\(error)")
                    self?.contentTextView.text = "onError:\(error)"
                }
                .disposed(by: disposeBag)
        }
    }
    
    @IBAction func handleTap(_ sender: Any) {
        bucketTextField.resignFirstResponder()
        keyTextField.resignFirstResponder()
        contentTextView.resignFirstResponder()
    }
}
