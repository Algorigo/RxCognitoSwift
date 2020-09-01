//
//  CryptoString.swift
//  RxCognito
//
//  Created by Jaehong Yoo on 2020/08/31.
//

import Foundation
import CryptoKit

extension String {
    func hmac(key: String) -> String {
        let symmetricKey = SymmetricKey(data: key.data(using: .utf8) ?? Data.init())
        var hmac = HMAC<SHA256>.init(key: symmetricKey)
        hmac.update(data: self.data(using: .utf8)!)
        let mac = hmac.finalize()
        let data = Data(mac)
        let hmacBase64 = data.base64EncodedString(options: Data.Base64EncodingOptions.lineLength76Characters)
        return hmacBase64
    }
}

extension Sequence where Element == UInt8 {
    func hmac(key: [UInt8]) -> Data {
        let symmetricKey = SymmetricKey(data: Data.init(key))
        let mac = HMAC<SHA256>.authenticationCode(for: self.data(), using: symmetricKey)
        return Data(mac)
    }
}

//SHA256
extension Data {
    func hash256() -> SHA256Digest {
        return SHA256.hash(data: self)
    }
}
