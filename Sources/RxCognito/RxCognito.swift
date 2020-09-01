
import RxSwift

public class RxCognito {

    public static let version = "0.0.1"
    
    public static let instance = RxCognito()
    
    fileprivate var cognito: Cognito? = nil
    
    public fileprivate(set) var currentUser: CognitoUser? = nil
    
    fileprivate init() {
        cognito = nil
    }
    
    public func initialize(accessKeyId: String, secretAccessKey: String, regions: Regions, userPoolId: String, appClientId: String, appClientSecret: String) {
        cognito = Cognito(accessKeyId: accessKeyId, secretAccessKey: secretAccessKey, regions: regions, userPoolId: userPoolId, appClientId: appClientId, appClientSecret: appClientSecret)
    }
    
    public func login(userId: String, password: String) -> Completable {
        if let cognito = cognito {
            return cognito.initiateAuth(userId: userId)
                .toSingle()
                .flatMap { (response) -> Single<CognitoUser?> in
                    cognito.respondToAuthChallenge(userId: userId, password: password, response: response)
                        .toSingle()
                }
                .do(onSuccess: { [weak self] (cognitoUser) in
                    if cognitoUser == nil {
                        throw CognitoError.NotEnoughResponse
                    } else {
                        self?.currentUser = cognitoUser
                    }
                })
                .asCompletable()
        } else {
            return Completable.error(CognitoError.NotInitializedError)
        }
    }
}
