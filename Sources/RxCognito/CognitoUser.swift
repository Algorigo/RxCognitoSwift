//
//  CognitoUser.swift
//  RxCognito
//
//  Created by Jaehong Yoo on 2020/09/01.
//

import Foundation
import CognitoIdentityProvider
import RxSwift

public class CognitoUser {
    struct IdToken {
        let jwtToken: String
        let appClientId: String //aud
        let email: String //email
        let emailVerified: Bool //email_verified
        let userName: UUID //cognito:username
        let eventId: UUID //eventId
        let sub: UUID //sub
        let authTime: Date //auth_time
        let iat: Date //iat
        let exp : Date //exp
        let iss: String //iss
        let tokenUse: String //id
        
        init?(idToken: String?) {
            if let idToken = idToken {
                self.jwtToken = idToken
                let jwt = idToken.decodeJwt()
                let _appClientId = jwt["aud"] as? String
                let _email = jwt["email"] as? String
                let _emailVerified = jwt["email_verified"] as? Int
                let _userName = UUID(uuidString: jwt["cognito:username"] as? String ?? "")
                let _eventId = UUID(uuidString: jwt["event_id"] as? String ?? "")
                let _sub = UUID(uuidString: jwt["sub"] as? String ?? "")
                let _authTime = jwt["auth_time"] as? Int
                let _iat = jwt["iat"] as? Int
                let _exp = jwt["exp"] as? Int
                let _iss = jwt["iss"] as? String
                let _tokenUse = jwt["token_use"] as? String
                if let _appClientId = _appClientId,
                    let _email = _email,
                    let _emailVerified = _emailVerified,
                    let _userName = _userName,
                    let _eventId = _eventId,
                    let _sub = _sub,
                    let _authTime = _authTime,
                    let _iat = _iat,
                    let _exp = _exp,
                    let _iss = _iss,
                    let _tokenUse = _tokenUse {
                    self.appClientId = _appClientId
                    self.email = _email
                    self.emailVerified = _emailVerified > 0
                    self.userName = _userName
                    self.eventId = _eventId
                    self.sub = _sub
                    self.authTime = Date(timeIntervalSince1970: Double(_authTime))
                    self.iat = Date(timeIntervalSince1970: Double(_iat))
                    self.exp = Date(timeIntervalSince1970: Double(_exp))
                    self.iss = _iss
                    self.tokenUse = _tokenUse
                } else {
                    return nil
                }
            } else {
                return nil
            }
        }
    }
    struct AccessToken {
        let jwtToken: String
        let clientId: String //client_id
        let eventId: UUID //event_id
        let jti: UUID //jti
        let sub: UUID //sub
        let userName: UUID //username
        let authTime: Date //auth_time
        let iat: Date //iat
        let exp: Date //exp
        let scope: String //scope
        let iss: String //iss
        let tokenUse: String //token_use
        
        init?(accessToken: String?) {
            if let accessToken = accessToken {
                self.jwtToken = accessToken
                let jwt = accessToken.decodeJwt()
                let _clientId = jwt["client_id"] as? String
                let _eventId = UUID(uuidString: jwt["event_id"] as? String ?? "")
                let _jti = UUID(uuidString: jwt["jti"] as? String ?? "")
                let _sub = UUID(uuidString: jwt["sub"] as? String ?? "")
                let _userName = UUID(uuidString: jwt["username"] as? String ?? "")
                let _authTime = jwt["auth_time"] as? Int
                let _iat = jwt["iat"] as? Int
                let _exp = jwt["exp"] as? Int
                let _scope = jwt["scope"] as? String
                let _iss = jwt["iss"] as? String
                let _tokenUse = jwt["token_use"] as? String
                if let _clientId = _clientId,
                    let _eventId = _eventId,
                    let _jti = _jti,
                    let _sub = _sub,
                    let _userName = _userName,
                    let _authTime = _authTime,
                    let _iat = _iat,
                    let _exp = _exp,
                    let _scope = _scope,
                    let _iss = _iss,
                    let _tokenUse = _tokenUse {
                    self.clientId = _clientId
                    self.eventId = _eventId
                    self.jti = _jti
                    self.sub = _sub
                    self.userName = _userName
                    self.authTime = Date(timeIntervalSince1970: Double(_authTime))
                    self.iat = Date(timeIntervalSince1970: Double(_iat))
                    self.exp = Date(timeIntervalSince1970: Double(_exp))
                    self.scope = _scope
                    self.iss = _iss
                    self.tokenUse = _tokenUse
                } else {
                    return nil
                }
            } else {
                return nil
            }
        }
    }
    
    fileprivate static let REFRESH_THRESHOLD = TimeInterval(300.0)
    
    fileprivate weak var userPool: CognitoUserPool?
    public let userId: String
    var idToken: IdToken
    var accessToken: AccessToken
    var refreshToken: String
    var expiresIn: Date
    
    init?(userPool: CognitoUserPool, userId: String, idToken: String, accessToken: String, refreshToken: String, expiresIn: TimeInterval) {
        let _idToken = IdToken(idToken: idToken)
        let _accessToken = AccessToken(accessToken: accessToken)
        if let _idToken = _idToken,
            let _accessToken = _accessToken {
            self.userPool = userPool
            self.userId = userId
            self.idToken = _idToken
            self.accessToken = _accessToken
            self.refreshToken = refreshToken
            self.expiresIn = Date(timeInterval: expiresIn, since: _idToken.authTime)
            
            cacheTokens()
        } else {
            return nil
        }
    }
    
    init?(userPool: CognitoUserPool, userId: String) {
        self.userPool = userPool
        self.userId = userId
        if let userDefaults = userPool.userDefaults,
            let _idToken = IdToken(idToken: userDefaults.string(forKey: CognitoUser.csiIdTokenKey(appClientId: userPool.appClientId, userId: userId))),
            let _accessToken = AccessToken(accessToken: userDefaults.string(forKey: CognitoUser.csiAccessTokenKey(appClientId: userPool.appClientId, userId: userId))),
            let _refreshToken = userDefaults.string(forKey: CognitoUser.csiRefreshTokenKey(appClientId: userPool.appClientId, userId: userId)) {
            self.idToken = _idToken
            self.accessToken = _accessToken
            self.refreshToken = _refreshToken
            self.expiresIn = idToken.exp
        } else {
            return nil
        }
    }
    
    public func logout() throws {
        if userPool == nil {
            throw CognitoError.NotInitializedError
        }
        
        clearCache()
        userPool = nil
    }
    
    public func getIdToken() -> String {
        return idToken.jwtToken
    }
    
    func setIdToken(idToken: String) throws {
        if let idToken = IdToken(idToken: idToken) {
            self.idToken = idToken
            if let pool = userPool,
                let userDefaults = pool.userDefaults {
                // Create keys to look for cached tokens
                // Store the data in Shared Preferences
                userDefaults.set(idToken.jwtToken, forKey: CognitoUser.csiIdTokenKey(appClientId: pool.appClientId, userId: userId))
            }
        } else {
            throw CognitoError.NotEnoughResponse
        }
    }
    
    func setAccessToken(accessToken: String) throws {
        if let accessToken = AccessToken(accessToken: accessToken) {
            self.accessToken = accessToken
            if let pool = userPool,
                let userDefaults = pool.userDefaults {
                // Create keys to look for cached tokens
                // Store the data in Shared Preferences
                userDefaults.set(accessToken.jwtToken, forKey: CognitoUser.csiAccessTokenKey(appClientId: pool.appClientId, userId: userId))
            }
        } else {
            throw CognitoError.NotEnoughResponse
        }
    }
    
    func setExpiresIn(expiresIn: Int) {
        self.expiresIn = Date(timeInterval: TimeInterval(expiresIn), since: self.idToken.authTime)
    }
    
    func isValidForThreshold() -> Bool {
        return Date().distance(to: expiresIn) > CognitoUser.REFRESH_THRESHOLD
    }
    
    public func changePassword(password: String, newPassword: String) -> Completable {
        if let pool = userPool {
            let changePasswordReq = CognitoIdentityProvider.ChangePasswordRequest(accessToken: accessToken.jwtToken, previousPassword: password, proposedPassword: newPassword)
            return pool.identityProvider.changePassword(changePasswordReq)
                .toSingle()
                .asCompletable()
        } else {
            return Completable.error(CognitoError.NotInitializedError)
        }
    }
    
    fileprivate func cacheTokens() {
        if let pool = userPool,
            let userDefaults = pool.userDefaults {
            // Create keys to look for cached tokens
            // Store the data in Shared Preferences
            userDefaults.set(idToken.jwtToken, forKey: CognitoUser.csiIdTokenKey(appClientId: pool.appClientId, userId: userId))
            userDefaults.set(accessToken.jwtToken, forKey: CognitoUser.csiAccessTokenKey(appClientId: pool.appClientId, userId: userId))
            userDefaults.set(refreshToken, forKey: CognitoUser.csiRefreshTokenKey(appClientId: pool.appClientId, userId: userId))
            userDefaults.set(userId, forKey: pool.csiLastUserKey)
        }
    }
    
    fileprivate func clearCache() {
        if let pool = userPool,
            let userDefaults = pool.userDefaults {
            // Create keys to look for cached tokens
            // Store the data in Shared Preferences
            userDefaults.removeObject(forKey: CognitoUser.csiIdTokenKey(appClientId: pool.appClientId, userId: userId))
            userDefaults.removeObject(forKey: CognitoUser.csiAccessTokenKey(appClientId: pool.appClientId, userId: userId))
            userDefaults.removeObject(forKey: CognitoUser.csiRefreshTokenKey(appClientId: pool.appClientId, userId: userId))
        }
    }
    
    fileprivate static func csiIdTokenKey(appClientId: String, userId: String) -> String {
        "CognitoIdentityProvider." + appClientId + "." + userId + ".idToken"
    }
    
    fileprivate static func csiAccessTokenKey(appClientId: String, userId: String) -> String {
        "CognitoIdentityProvider." + appClientId + "." + userId + ".accessToken"
    }
    
    fileprivate static func csiRefreshTokenKey(appClientId: String, userId: String) -> String {
        "CognitoIdentityProvider." + appClientId + "." + userId + ".refreshToken"
    }
}
