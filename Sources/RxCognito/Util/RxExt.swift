//
//  RxExt.swift
//  RxCognito
//
//  Created by Jaehong Yoo on 2020/09/03.
//

import Foundation
import RxSwift

class NoSuchElement : Error {
    
}

extension Observable {
    func firstOrError() -> Single<Element> {
        return first()
            .map { (optional) -> Element in
                if let optional = optional {
                    return optional
                } else {
                    throw NoSuchElement()
                }
            }
    }
}

extension PrimitiveSequence where Trait == SingleTrait {
    public func wait(dueTime: RxTimeInterval) throws -> Element {
        let semaphore = DispatchSemaphore.init(value: 0)
        var element: Element? = nil
        var error: Error? = nil
        _ = self.timeout(dueTime, scheduler: ConcurrentDispatchQueueScheduler.init(qos: .background))
            .observeOn(ConcurrentDispatchQueueScheduler.init(qos: .background))
            .subscribe { (event) in
                switch (event) {
                case .success(let value):
                    element = value
                case .error(let err):
                    error = err
                }
                semaphore.signal()
            }
        semaphore.wait()
        if let error = error {
            throw error
        } else if let element = element {
            return element
        } else {
            throw NoSuchElement()
        }
    }
}

extension PrimitiveSequence where Trait == MaybeTrait {
    public func wait(dueTime: RxTimeInterval) throws -> Element? {
        let semaphore = DispatchSemaphore.init(value: 0)
        var element: Element? = nil
        var error: Error? = nil
        _ = self.timeout(dueTime, scheduler: ConcurrentDispatchQueueScheduler.init(qos: .background))
            .observeOn(ConcurrentDispatchQueueScheduler.init(qos: .background))
            .subscribe { (event) in
                switch (event) {
                case .success(let value):
                    element = value
                case .completed:
                    break
                case .error(let err):
                    error = err
                }
                semaphore.signal()
            }
        semaphore.wait()
        if let error = error {
            throw error
        } else {
            return element
        }
    }
}
