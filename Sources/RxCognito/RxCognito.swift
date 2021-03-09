
import Foundation
import RxSwift
import SotoCore

public class RxCognito {

    public static let version = "0.0.9"
    
    fileprivate let awsClient: AWSClient
    fileprivate let userPool: CognitoUserPool
    fileprivate let s3Uploader: S3Uploader
    
    public init(accessKeyId: String, secretAccessKey: String, regions: Regions, userPoolId: String, appClientId: String, appClientSecret: String) {
        awsClient = AWSClient(
            credentialProvider: .static(accessKeyId: accessKeyId, secretAccessKey: secretAccessKey),
            httpClientProvider: .createNew
        )
        userPool = CognitoUserPool(awsClient: awsClient, regions: regions, userPoolId: userPoolId, appClientId: appClientId, appClientSecret: appClientSecret)
        s3Uploader = S3Uploader(awsClient: awsClient, regions: regions)
    }
    
    public func getCurrentUserId() -> Maybe<String> {
        if let userId = userPool.getCurrentUserId() {
            return Maybe.just(userId)
        } else {
            return Maybe.empty()
        }
    }
    
    public func getCurrentUser() -> Maybe<CognitoUser> {
        userPool.getCurrentUser()
    }
    
    public func login(userId: String, password: String) -> Single<CognitoUser> {
        userPool.initiateAuth(userId: userId)
            .flatMap { [unowned self] (response) -> Single<CognitoUser> in
                self.userPool.respondToAuthChallenge(userId: userId, password: password, response: response)
                    .map { (cognitoUserOptional) -> CognitoUser in
                        if let cognitoUser = cognitoUserOptional {
                            return cognitoUser
                        } else {
                            throw CognitoError.NotEnoughResponse
                        }
                    }
            }
    }
    
    public func resendConfirmCode(userId: String) -> Single<String> {
        userPool.resendConfirmCode(userId: userId)
    }
    
    public func forgotPassword(userId: String) -> Single<ForgotPasswordContinuation> {
        userPool.forgotPassword(userId: userId)
    }
    
    public func continueForgotPassword(continuation: ForgotPasswordContinuation, verificationCode: String, newPassword: String) -> Completable {
        userPool.continueForgotPassword(forgotPasswordContinuation: continuation, verificationCode: verificationCode, newPassword: newPassword)
    }
    
    public func putObject(bucket: String, key: String, data: Data) -> Completable {
        s3Uploader.putObject(bucket: bucket, key: key, data: data)
    }
}
