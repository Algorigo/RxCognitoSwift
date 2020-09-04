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
        let subject = ReplaySubject<Value>.create(bufferSize: 1)
        self.whenSuccess { (value) in
            subject.onNext(value)
            subject.onCompleted()
        }
        self.whenFailure { (error) in
            subject.onError(error)
        }
        return subject.firstOrError()
//        return Single.create { (observer) -> Disposable in
//            self.whenSuccess { (value) in
//                observer(.success(value))
//            }
//            self.whenFailure { (error) in
//                observer(.error(error))
//            }
//            return Disposables.create()
//        }
//        .subscribeOn(ConcurrentDispatchQueueScheduler.init(qos: .background))
    }
}
