//
//  CognitoError.swift
//  RxCognito
//
//  Created by Jaehong Yoo on 2020/08/31.
//

import Foundation

public enum CognitoError : Error {
    case NotInitializedError
    case NotEnoughResponse
    case SignatureCalculationError
    case ResendCodeDeliveryMediumEmpty
}
