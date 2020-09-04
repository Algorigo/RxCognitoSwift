//
//  Log.swift
//  RxCognito
//
//  Created by Jaehong Yoo on 2020/09/04.
//

import Foundation

public class Log {
    public static func e(_ tag: String, _ message: String) {
        print("\(Date()) E/\(tag): \(message)")
    }
    
    public static func d(_ tag: String, _ message: String) {
#if DEBUG
        print("\(Date()) D/\(tag): \(message)")
#endif
    }
    
    public static func i(_ tag: String, _ message: String) {
        print("\(Date()) D/\(tag): \(message)")
    }
}
