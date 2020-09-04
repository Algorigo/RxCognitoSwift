//
//  FormatDate.swift
//  RxCognito
//
//  Created by Jaehong Yoo on 2020/08/31.
//

import Foundation

extension Date {
    func string() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = TimeZone.init(secondsFromGMT: 0)
        formatter.dateFormat = "EEE MMM d HH:mm:ss 'UTC' yyyy"
        return formatter.string(from: self)
    }
    
    func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyMMdd HHmmss"
        return formatter.string(from: self)
    }
}
