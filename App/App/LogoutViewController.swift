//
//  LogoutViewController.swift
//  App
//
//  Created by Jaehong Yoo on 2020/09/04.
//  Copyright © 2020 Algorigo. All rights reserved.
//

import UIKit
import RxSwift
import RxCognito

class LogoutViewController: UIViewController {

    @IBOutlet weak var resultTextView: UITextView!
    
    fileprivate let disposeBag = DisposeBag()
    
    fileprivate var user: CognitoUser? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        RxCognito.instance.getCurrentUser()
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] (event) in
                switch event {
                case .success(let user):
                    self?.resultTextView.text = "\(user.getIdToken())"
                    self?.user = user
                case .completed:
                    Log.d("LogoutViewController", "complete")
                    self?.resultTextView.text = "no user"
                    self?.user = nil
                case .error(let error):
                    Log.e("LogoutViewController", "cognito error:\(error)")
                    self?.user = nil
                }
            }
            .disposed(by: disposeBag)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func handleLogout(_ sender: Any) {
        Completable.create { [unowned self] (observer) -> Disposable in
            do {
                try self.user?.logout()
                observer(.completed)
            } catch {
                observer(.error(error))
            }
            return Disposables.create()
        }
        .delay(RxTimeInterval.milliseconds(500), scheduler: ConcurrentDispatchQueueScheduler.init(qos: .background))
        .andThen(RxCognito.instance.getCurrentUser())
        .observeOn(MainScheduler.instance)
        .subscribe { [weak self] (event) in
            switch event {
            case .success(let user):
                self?.resultTextView.text = "\(user.getIdToken())"
                self?.user = user
            case .completed:
                Log.d("LogoutViewController", "complete")
                self?.resultTextView.text = "no user"
                self?.user = nil
            case .error(let error):
                Log.e("LogoutViewController", "cognito error:\(error)")
                self?.user = nil
            }
        }
        .disposed(by: disposeBag)
    }
}
