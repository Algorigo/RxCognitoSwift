//
//  Cognito.swift
//  RxCognito
//
//  Created by Jaehong Yoo on 2020/08/31.
//

import Foundation
import BigNum
import CryptoKit
import SotoCognitoIdentityProvider
import NIO
import RxSwift

class CognitoUserPool {

    struct InitiateAuthResponse {
        var challengeName: CognitoIdentityProvider.ChallengeNameType
        var secretBlock: String
        var srpA: String
        var smallA: BigNum
        var srpB: String
        var salt: String
        var srpUserId: String
    }
    
    struct RefreshTokenResponse {
        var idToken: String
        var acessToken: String
        var expiresIn: Int
        var tokenType: String
    }
    
    fileprivate static let N = BigNum(hex:
        "FFFFFFFFFFFFFFFFC90FDAA22168C234C4C6628B80DC1CD129024E08" +
        "8A67CC74020BBEA63B139B22514A08798E3404DDEF9519B3CD3A431B" +
        "302B0A6DF25F14374FE1356D6D51C245E485B576625E7EC6F44C42E9" +
        "A637ED6B0BFF5CB6F406B7EDEE386BFB5A899FA5AE9F24117C4B1FE6" +
        "49286651ECE45B3DC2007CB8A163BF0598DA48361C55D39A69163FA8" +
        "FD24CF5F83655D23DCA3AD961C62F356208552BB9ED529077096966D" +
        "670C354E4ABC9804F1746C08CA18217C32905E462E36CE3BE39E772C" +
        "180E86039B2783A2EC07A28FB5C55DF06F4C52C9DE2BCBF695581718" +
        "3995497CEA956AE515D2261898FA051015728E5A8AAAC42DAD33170D" +
        "04507A33A85521ABDF1CBA64ECFB850458DBEF0A8AEA71575D060C7D" +
        "B3970F85A6E1E4C7ABF5AE8CDB0933D71E8C94E04A25619DCEE3D226" +
        "1AD2EE6BF12FFA06D98A0864D87602733EC86A64521F2B18177B200C" +
        "BBE117577A615D6C770988C0BAD946E208E24FA074E5AB3143DB5BFC" +
        "E0FD108E4B82D120A93AD2CAFFFFFFFFFFFFFFFF")!
    fileprivate static let g = BigNum(2)
    fileprivate static let k = BigNum(hex: "538282c4354742d7cbbde2359fcf67f9f5b3a6b08791e5011b43b8a5b66d9ee6")!

    fileprivate static let INFO_BITS = "43616c646572612044657269766564204b657901"
    
    let userDefaults = UserDefaults.init(suiteName: "Cognito")
    
    let regions: Regions
    let userPoolId: String
    let appClientId: String
    let appClientSecret: String
    let identityProvider: CognitoIdentityProvider
    var csiLastUserKey: String {
        return "CognitoIdentityProvider." + appClientId + ".LastAuthUser"
    }
    
    init(awsClient: AWSClient, regions: Regions, userPoolId: String, appClientId: String, appClientSecret: String) {
        self.regions = regions
        self.userPoolId = userPoolId
        self.appClientId = appClientId
        self.appClientSecret = appClientSecret
        
        self.identityProvider = CognitoIdentityProvider.init(client: awsClient, region: regions.getRegion())
    }
    
    func getCurrentUserId() -> String? {
        self.userDefaults?.string(forKey: self.csiLastUserKey)
    }
    
    func getCurrentUser() -> Maybe<CognitoUser> {
        return Maybe<CognitoUser>.create { [unowned self] (observer) -> Disposable in
            if let userId = getCurrentUserId(),
                let user = CognitoUser.init(userPool: self, userId: userId) {
                observer(.success(user))
            } else {
                observer(.completed)
            }
            return Disposables.create()
        }
        .flatMap({ [unowned self] (cognitoUser) -> Maybe<CognitoUser> in
            if (cognitoUser.isValidForThreshold()) {
                return Maybe.just(cognitoUser)
            } else {
                return self.refreshSession(uesr: cognitoUser)
                    .flatMapMaybe({ (response) -> Maybe<CognitoUser> in
                        if let response = response {
                            try cognitoUser.setIdToken(idToken: response.idToken)
                            try cognitoUser.setAccessToken(accessToken: response.acessToken)
                            return Maybe.just(cognitoUser)
                        } else {
                            return Maybe.empty()
                        }
                    })
            }
        })
    }
    
    func initiateAuth(userId: String) -> Single<InitiateAuthResponse> {
        let clientAValueNumber = BigNum(bytes: SymmetricKey(size: .bits256))
        let publicAValueNumber = CognitoUserPool.g.power(clientAValueNumber, modulus: CognitoUserPool.N)
        let clientPublicKey = publicAValueNumber.hex
        let secretHash = createSecretHash(userId: userId)
        
        return identityProvider.initiateAuth(CognitoIdentityProvider.InitiateAuthRequest.init(analyticsMetadata: nil, authFlow: CognitoIdentityProvider.AuthFlowType.userSrpAuth, authParameters: ["USERNAME": userId, "SRP_A": clientPublicKey, "SECRET_HASH": secretHash], clientId: appClientId, clientMetadata: nil, userContextData: nil))
            .flatMap { (response) -> EventLoopFuture<CognitoUserPool.InitiateAuthResponse> in
                if let challengeName = response.challengeName, let secretBlock = response.challengeParameters?["SECRET_BLOCK"], let srpB = response.challengeParameters?["SRP_B"], let salt = response.challengeParameters?["SALT"], let srpUserId = response.challengeParameters?["USER_ID_FOR_SRP"] {
                    let initiateAuthResponse = InitiateAuthResponse(challengeName: challengeName, secretBlock: secretBlock, srpA: clientPublicKey, smallA: clientAValueNumber, srpB: srpB, salt: salt, srpUserId: srpUserId)
                    let promise = EmbeddedEventLoop.init().makePromise(of: InitiateAuthResponse.self)
                    promise.succeed(initiateAuthResponse)
                    return promise.futureResult
                } else {
                    let promise = EmbeddedEventLoop.init().makePromise(of: InitiateAuthResponse.self)
                    promise.fail(CognitoError.NotEnoughResponse)
                    return promise.futureResult
                }
            }
            .toSingle()
    }
    
    fileprivate func createSecretHash(userId: String) -> String {
        (userId+appClientId).hmac(key: appClientSecret)
    }
    
    func respondToAuthChallenge(userId: String, password: String, response: InitiateAuthResponse) -> Single<CognitoUser?> {
        
        let dateTimeString = Date().string()
        let secretHash = (userId+appClientId).hmac(key: appClientSecret)
        do {
            let signatureString = try getSignatureString(password: password, srpA: response.srpA, smallA: response.smallA, srpB: response.srpB, srpUserId: response.srpUserId, dateTimeString: dateTimeString, salt: response.salt, secretBlock: response.secretBlock)
            let challengeResponses = ["TIMESTAMP": dateTimeString, "USERNAME": userId, "PASSWORD_CLAIM_SECRET_BLOCK": response.secretBlock, "PASSWORD_CLAIM_SIGNATURE": signatureString, "SECRET_HASH": secretHash]
            
            return identityProvider.respondToAuthChallenge(CognitoIdentityProvider.RespondToAuthChallengeRequest.init(analyticsMetadata: nil, challengeName: response.challengeName, challengeResponses: challengeResponses, clientId: appClientId, clientMetadata: nil, session: nil, userContextData: nil))
                .map { [unowned self] (response) -> (CognitoUser?) in
                    if let idToken = response.authenticationResult?.idToken,
                        let accessToken = response.authenticationResult?.accessToken,
                        let refreshToken = response.authenticationResult?.refreshToken,
                        let expiresIn = response.authenticationResult?.expiresIn {
                        
                        return CognitoUser(userPool: self, userId: userId, idToken: idToken, accessToken: accessToken, refreshToken: refreshToken, expiresIn: Double(expiresIn))
                    } else {
                        return nil
                    }
                }
                .toSingle()
        } catch {
            let promise = EmbeddedEventLoop.init().makePromise(of: Optional<CognitoUser>.self)
            promise.fail(CognitoError.SignatureCalculationError)
            return promise.futureResult
                .toSingle()
        }
    }
    
    fileprivate func getSignatureString(password: String, srpA: String, smallA: BigNum, srpB: String, srpUserId: String, dateTimeString: String, salt: String, secretBlock: String) throws -> String {

        // A + B -> U
        let clientAValue = BigNum.init(hex: srpA)!
        let padA = clientAValue.padHex()
        let serverBValue = BigNum.init(hex: srpB)!
        let padB = serverBValue.padHex()
        let padded = (padA + padB)
        let uValueStr = padded.uInt8ArrayWithHex()!.data().hash256().hex()
        let uValue = BigNum.init(hex: uValueStr)!
        
        // poolId + userName + password -> Message1
        let poolIdSuffix = String(userPoolId.split(separator: "_")[1])
        let usernamePassword = poolIdSuffix + srpUserId + ":" + password
        let usernamePasswordHash = usernamePassword.dataWithUTF8()?.hash256().hex()
        
        // Salt + Message1 -> X
        let saltUserPass = BigNum.init(hex: salt)!.padHex() + usernamePasswordHash!
        let xValueStr = saltUserPass.uInt8ArrayWithHex()!.data().hash256().hex()
        let xValue = BigNum.init(hex: xValueStr)!
        
        // (B - k * g ^ X % N) ^ (A + U * X) % N -> S
        let gModPowXN = CognitoUserPool.g.power(xValue, modulus: CognitoUserPool.N)
        let multiflied = CognitoUserPool.k * gModPowXN
        let intValue2 = serverBValue - multiflied
        let multiflied2 = uValue * xValue
        let added = smallA + multiflied2
        let sValue = intValue2.power(added, modulus: CognitoUserPool.N)
        
        // Hash(S, U) -> PRK
        let ikmWordArray = sValue.padHex()
        let saltWordArray = uValue.padHex()
        let prk = ikmWordArray.uInt8ArrayWithHex()!.hmac(key: saltWordArray.uInt8ArrayWithHex()!).hex()
        
        // Hash(InfoBits + 1, PRK) -> HMac
        let infoBitsWordArray = CognitoUserPool.INFO_BITS
        let hmac = infoBitsWordArray.uInt8ArrayWithHex()!.hmac(key: prk.uInt8ArrayWithHex()!).hex()
        
        let key = String(hmac[...hmac.index(hmac.startIndex, offsetBy: 31)])
        
        // poolId + userName + secretBlock + dateStr -> Message2
        let buffer = (poolIdSuffix.uInt8ArrayWithUTF8() +  srpUserId.uInt8ArrayWithUTF8() + secretBlock.dataWithBase64Encoded()!.uInt8Array() + dateTimeString.uInt8ArrayWithUTF8()).hex()
        let message = buffer
     
        let signatureData = message.uInt8ArrayWithHex()!.hmac(key: key.uInt8ArrayWithHex()!)
        return signatureData.base64EncodedString()
    }
    
    fileprivate func refreshSession(uesr: CognitoUser) -> Single<RefreshTokenResponse?> {
        var authParameters = [String : String]()
        authParameters["REFRESH_TOKEN"] = uesr.refreshToken
        authParameters["SECRET_HASH"] = appClientSecret
    
        let authRequest = CognitoIdentityProvider.InitiateAuthRequest(analyticsMetadata: nil, authFlow: .refreshToken, authParameters: authParameters, clientId: appClientId, clientMetadata: nil, userContextData: nil)
        return identityProvider.initiateAuth(authRequest)
            .map { (response) -> (RefreshTokenResponse?) in
                if let idToken = response.authenticationResult?.idToken,
                    let accessToken = response.authenticationResult?.accessToken,
                    let expiresIn = response.authenticationResult?.expiresIn,
                    let tokenType = response.authenticationResult?.tokenType {
                    return RefreshTokenResponse(idToken: idToken, acessToken: accessToken, expiresIn: expiresIn, tokenType: tokenType)
                } else {
                    return nil
                }
            }
            .toSingle()
    }
    
    func resendConfirmCode(userId: String) -> Single<String> {
        let secretHash = createSecretHash(userId: userId)
        let resendConfirmCodeReq = CognitoIdentityProvider.ResendConfirmationCodeRequest(analyticsMetadata: nil, clientId: appClientId, clientMetadata: nil, secretHash: secretHash, userContextData: nil, username: userId)
        return identityProvider.resendConfirmationCode(resendConfirmCodeReq)
            .toSingle()
            .map({ (response) -> String in
                if let deliveryMedium = response.codeDeliveryDetails?.deliveryMedium?.rawValue {
                    return deliveryMedium
                } else {
                    throw CognitoError.ResendCodeDeliveryMediumEmpty
                }
            })
    }
    
    func forgotPassword(userId: String) -> Single<ForgotPasswordContinuation> {
        let secretHash = createSecretHash(userId: userId)
        let forgotPasswordReq = CognitoIdentityProvider.ForgotPasswordRequest(analyticsMetadata: nil, clientId: appClientId, clientMetadata: nil, secretHash: secretHash, userContextData: nil, username: userId)
        
        return identityProvider.forgotPassword(forgotPasswordReq)
            .toSingle()
            .map { (response) -> ForgotPasswordContinuation in
                if let destination = response.codeDeliveryDetails?.destination,
                    let deliveryMedium = response.codeDeliveryDetails?.deliveryMedium {
                    return ForgotPasswordContinuation(userId: userId, destination: destination, deliveryMedium: deliveryMedium)
                } else {
                    throw CognitoError.ForgotPasswordResponseEmpty
                }
            }
    }
    
    func continueForgotPassword(forgotPasswordContinuation: ForgotPasswordContinuation, verificationCode: String, newPassword: String) -> Completable {
        let secretHash = createSecretHash(userId: forgotPasswordContinuation.userId)
        let confirmForgotPasswordReq = CognitoIdentityProvider.ConfirmForgotPasswordRequest(analyticsMetadata: nil, clientId: appClientId, clientMetadata: nil, confirmationCode: verificationCode, password: newPassword, secretHash: secretHash, userContextData: nil, username: forgotPasswordContinuation.userId)
        return identityProvider.confirmForgotPassword(confirmForgotPasswordReq)
            .toSingle()
            .asCompletable()
    }
}
