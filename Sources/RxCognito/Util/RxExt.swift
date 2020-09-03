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
