//
//  PaddingString.swift
//  RxCognito
//
//  Created by Jaehong Yoo on 2020/08/31.
//

import Foundation
import BigNum

extension BigNum {
    func padHex() -> String {
        let hexa = self.hex
        if self.hex.count % 2 == 1 {
            return "0"+hexa
        } else if let first = hexa.first, "89ABCDEFabcdef".firstIndex(of: first) != nil {
            return "00"+hexa
        }
        return hexa
    }
}
