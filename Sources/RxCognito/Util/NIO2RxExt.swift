//
//  NIO2RxExt.swift
//  RxCognito
//
//  Created by Jaehong Yoo on 2020/09/01.
//

import Foundation
import NIO
import RxSwift

extension EventLoopFuture {
    func toSingle() -> Single<Value> {
        return Single.create { (observer) -> Disposable in
            self.whenSuccess { (value) in
                observer(.success(value))
            }
            self.whenFailure { (error) in
                observer(.error(error))
            }
            return Disposables.create()
        }
    }
}
