//
//  Regions.swift
//  RxCognito
//
//  Created by Jaehong Yoo on 2020/09/01.
//

import Foundation
import SotoCore

public enum Regions: CaseIterable {
    case useast1
    case useast2
    case uswest1
    case uswest2
    case apsouth1
    case apsoutheast1
    case apsoutheast2
    case apnortheast1
    case apnortheast2
    case apnortheast3
    case apeast1
    case cacentral1
    case euwest1
    case euwest3
    case euwest2
    case eucentral1
    case eunorth1
    case eusouth1
    case saeast1
    case mesouth1
    case afsouth1
    
    func getRegion() -> Region {
        switch self {
        case .useast1: return .useast1
        case .useast2: return .useast2
        case .uswest1: return .useast2
        case .uswest2: return .uswest2
        case .apsouth1: return .apsouth1
        case .apsoutheast1: return .apsoutheast1
        case .apsoutheast2: return .apsoutheast2
        case .apnortheast1: return .apnortheast1
        case .apnortheast2: return .apnortheast2
        case .apnortheast3: return .apnortheast3
        case .apeast1: return .apeast1
        case .cacentral1: return .cacentral1
        case .euwest1: return .euwest1
        case .euwest2: return .euwest2
        case .euwest3: return .euwest3
        case .eucentral1: return .eucentral1
        case .eunorth1: return .eunorth1
        case .eusouth1: return .eusouth1
        case .saeast1: return .saeast1
        case .mesouth1: return .mesouth1
        case .afsouth1: return .afsouth1
        }
    }
    
    public func getName() -> String {
        return getRegion().rawValue
    }
}
