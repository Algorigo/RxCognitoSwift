//
//  TypeConvert.swift
//  RxCognito
//
//  Created by Jaehong Yoo on 2020/08/31.
//

import Foundation

// [UInt8] <-> Data
extension Sequence where Element == UInt8 {
    func data() -> Data {
        return Data.init(self)
    }
}

extension Data {
    func uInt8Array() -> [UInt8] {
        return [UInt8](self)
    }
}

// [UInt8] -> String
extension Sequence where Element == UInt8 {
    func utf8() -> String? {
        return String.init(bytes: self, encoding: .utf8)
    }
}

extension Sequence where Element == UInt8 {
    func hex() -> String {
        return self.map { .init(format: "%02x", $0) }.joined()
    }
}

// Data -> String
extension Data {
    func stringWithBase64() -> String {
        return base64EncodedString(options: .lineLength76Characters)
    }
}

extension Data {
    func stringWithUTF8() -> String {
        return String(decoding: self, as: UTF8.self)
    }
}

// String -> [UInt8], Data
extension String {
    func uInt8ArrayWithUTF8() -> [UInt8] {
        return Array(self.utf8)
    }
    
    func dataWithUTF8() -> Data? {
        return self.data(using: .utf8)
    }
}

extension String {
    func uInt8ArrayWithHex() -> [UInt8]? {
        var length = self.count
        let newString: String
        if length & 1 == 0 {
            newString = self
        } else {
            newString = "0"+self
            length += 1
        }
        var bytes = [UInt8]()
        bytes.reserveCapacity(length/2)
        var index = newString.startIndex
        for _ in 0..<length/2 {
            let nextIndex = newString.index(index, offsetBy: 2)
            if let b = UInt8(newString[index..<nextIndex], radix: 16) {
                bytes.append(b)
            } else {
                return nil
            }
            index = nextIndex
        }
        return bytes
    }
}

extension String {
    func dataWithBase64Encoded() -> Data? {
        if self.count % 4 == 0 {
            return Data(base64Encoded: self)
        } else {
            return Data(base64Encoded: self + String.init(repeating: "=", count: 4 - self.count % 4))
        }
    }
}
