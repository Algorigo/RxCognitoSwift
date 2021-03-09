//
//  CognitoData.swift
//  RxCognito
//
//  Created by Jaehong Yoo on 2020/09/09.
//

import Foundation
import SotoCognitoIdentityProvider

public struct ForgotPasswordContinuation {
    let userId: String
    let destination: String
    let deliveryMedium: CognitoIdentityProvider.DeliveryMediumType
}
