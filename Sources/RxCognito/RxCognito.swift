
import RxSwift

public class RxCognito {

    public static let version = "0.0.3"
    
    fileprivate let userPool: CognitoUserPool
    
    public init(accessKeyId: String, secretAccessKey: String, regions: Regions, userPoolId: String, appClientId: String, appClientSecret: String) {
        userPool = CognitoUserPool(accessKeyId: accessKeyId, secretAccessKey: secretAccessKey, regions: regions, userPoolId: userPoolId, appClientId: appClientId, appClientSecret: appClientSecret)
    }
    
    public func getCurrentUser() -> Maybe<CognitoUser> {
        return checkPoolInitialized()
            .flatMapMaybe { (pool) -> Maybe<CognitoUser> in
                return pool.getCurrentUser()
            }
    }
    
    public func login(userId: String, password: String) -> Single<CognitoUser> {
        return checkPoolInitialized()
            .flatMap { (pool) -> Single<CognitoUser> in
                pool.initiateAuth(userId: userId)
                .flatMap { (response) -> Single<CognitoUser> in
                    pool.respondToAuthChallenge(userId: userId, password: password, response: response)
                        .map { (cognitoUserOptional) -> CognitoUser in
                            if let cognitoUser = cognitoUserOptional {
                                return cognitoUser
                            } else {
                                throw CognitoError.NotEnoughResponse
                            }
                        }
                }
            }
    }
    
    fileprivate func checkPoolInitialized() -> Single<CognitoUserPool> {
        return Single.deferred { [unowned self] () -> Single<CognitoUserPool> in
            return Single.just(self.userPool)
        }
    }
}
