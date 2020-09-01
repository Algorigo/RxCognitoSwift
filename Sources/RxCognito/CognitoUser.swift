//
//  CognitoUser.swift
//  RxCognito
//
//  Created by Jaehong Yoo on 2020/09/01.
//

import Foundation

public struct CognitoUser {
    struct IdToken {
        let idToken: String
        let appClientId: String //aud
        let email: String //email
        let locale: String //locale
        let emailVerified: Bool //email_verified
        let userName: UUID //cognito:username
        let eventId: UUID //eventId
        let sub: UUID //sub
        let authTime: Date //auth_time
        let iat: Date //iat
        let exp : Date //exp
        let iss: String //iss
        let tokenUse: String //id
        
        init(idToken: String) {
            self.idToken = idToken
            let jwt = idToken.decodeJwt()
            print("idToken:\(jwt)")
            self.appClientId = jwt["aud"] as! String
            self.email = jwt["email"] as! String
            self.locale = jwt["locale"] as! String
            self.emailVerified = jwt["email_verified"] as! Int > 0
            self.userName = UUID(uuidString: jwt["cognito:username"] as! String)!
            self.eventId = UUID(uuidString: jwt["event_id"] as! String)!
            self.sub = UUID(uuidString: jwt["sub"] as! String)!
            self.authTime = Date(timeIntervalSince1970: Double(jwt["auth_time"] as! Int))
            self.iat = Date(timeIntervalSince1970: Double(jwt["iat"] as! Int))
            self.exp = Date(timeIntervalSince1970: Double(jwt["exp"] as! Int))
            self.iss = jwt["iss"] as! String
            self.tokenUse = jwt["token_use"] as! String
        }
    }
    struct AccessToken {
        let accessToken: String
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
        
        init(accessToken: String) {
            self.accessToken = accessToken
            let jwt = accessToken.decodeJwt()
            print("accessToken:\(jwt)")
            print("client_id:\(type(of: jwt["client_id"]))")
            self.clientId = jwt["client_id"] as! String
            self.eventId = UUID(uuidString: jwt["event_id"] as! String)!
            self.jti = UUID(uuidString: jwt["jti"] as! String)!
            self.sub = UUID(uuidString: jwt["sub"] as! String)!
            self.userName = UUID(uuidString: jwt["username"] as! String)!
            self.authTime = Date(timeIntervalSince1970: Double(jwt["auth_time"] as! Int))
            self.iat = Date(timeIntervalSince1970: Double(jwt["iat"] as! Int))
            self.exp = Date(timeIntervalSince1970: Double(jwt["exp"] as! Int))
            self.scope = jwt["scope"] as! String
            self.iss = jwt["iss"] as! String
            self.tokenUse = jwt["token_use"] as! String
        }
    }
    let idToken: IdToken
    let accessToken: AccessToken
    let refreshToken: String
    let expiresIn: Date
    
    init(idToken: String, accessToken: String, refreshToken: String, expiresIn: TimeInterval) {
        self.idToken = IdToken(idToken: idToken)
        self.accessToken = AccessToken(accessToken: accessToken)
        self.refreshToken = refreshToken
        self.expiresIn = Date(timeInterval: expiresIn, since: Date.init())
    }
    
    func isExpired() -> Bool {
        return Date().compare(expiresIn) == .orderedDescending
    }
}
