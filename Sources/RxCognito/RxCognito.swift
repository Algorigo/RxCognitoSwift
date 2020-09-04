
import RxSwift

public class RxCognito {

    public static let version = "0.0.2"
    
    public static let instance = RxCognito()
    
    fileprivate var userPool: CognitoUserPool? = nil
    
    fileprivate init() {
        userPool = nil
    }
    
    public func initialize(accessKeyId: String, secretAccessKey: String, regions: Regions, userPoolId: String, appClientId: String, appClientSecret: String) {
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
            if let userPool = self.userPool {
                return Single.just(userPool)
            } else {
                return Single.error(CognitoError.NotInitializedError)
            }
        }
    }
}
