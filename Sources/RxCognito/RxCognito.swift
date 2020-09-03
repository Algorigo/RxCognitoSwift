
import RxSwift

public class RxCognito {

    public static let version = "0.0.1"
    
    public static let instance = RxCognito()
    
    fileprivate var userPool: CognitoUserPool? = nil
    
    fileprivate init() {
        userPool = nil
    }
    
    public func initialize(accessKeyId: String, secretAccessKey: String, regions: Regions, userPoolId: String, appClientId: String, appClientSecret: String) {
        userPool = CognitoUserPool(accessKeyId: accessKeyId, secretAccessKey: secretAccessKey, regions: regions, userPoolId: userPoolId, appClientId: appClientId, appClientSecret: appClientSecret)
    }
    
    public func getCurrentUser() -> Single<CognitoUser> {
        return checkPoolInitialized()
            .flatMap { (pool) -> Single<CognitoUser> in
                return Single.deferred({ () -> Single<CognitoUser> in
                    if let user = pool.currentUser() {
                        return Single.just(user)
                    } else {
                        return Single.error(CognitoError.NotEnoughResponse)
                    }
                })
            }
            .flatMap({ [weak self] (cognitoUser) -> Single<CognitoUser> in
                if (cognitoUser.isValidForThreshold()) {
                    return Single.just(cognitoUser)
                } else {
                    print("111 not isValidForThreshold")
                    return self?.userPool?.refreshSession(uesr: cognitoUser)
                        .toSingle()
                        .flatMap({ (response) -> Single<CognitoUser> in
                            print("222 response \(response)")
                            if let response = response {
                                try cognitoUser.setIdToken(idToken: response.idToken)
                                try cognitoUser.setAccessToken(accessToken: response.acessToken)
                                cognitoUser.setExpiresIn(expiresIn: response.expiresIn)
                                return Single.just(cognitoUser)
                            } else {
                                return Single.error(CognitoError.NotEnoughResponse)
                            }
                        }) ?? Single.error(CognitoError.NotInitializedError)
                }
            })
    }
    
    public func login(userId: String, password: String) -> Single<CognitoUser> {
        return checkPoolInitialized()
            .flatMap { (pool) -> Single<CognitoUser> in
                pool.initiateAuth(userId: userId)
                .toSingle()
                .flatMap { (response) -> Single<CognitoUser> in
                    pool.respondToAuthChallenge(userId: userId, password: password, response: response)
                        .toSingle()
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
        return Single.deferred { [weak self] () -> Single<CognitoUserPool> in
            if let userPool = self?.userPool {
                return Single.just(userPool)
            } else {
                return Single.error(CognitoError.NotInitializedError)
            }
        }
    }
}
