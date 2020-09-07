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
    
    @IBOutlet weak var resultTetView: UITextView!
    
    private let disposeBag = DisposeBag()

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
        RxCognito.instance.getCurrentUser()
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] (event) in
                switch event {
                case .success(let user):
                    self?.resultTetView.text = "\(user.getIdToken())"
                case .completed:
                    Log.d("RefreshViewController", "complete")
                    self?.resultTetView.text = "no user"
                case .error(let error):
                    Log.e("RefreshViewController", "cognito error:\(error)")
                }
            }
            .disposed(by: disposeBag)
    }
    
    @IBAction func handleRefresh(_ sender: Any) {
        refresh()
    }
    
}
