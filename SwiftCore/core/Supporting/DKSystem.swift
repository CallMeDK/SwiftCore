//
//  DKSystem.swift
//  SwiftCore
//
//  Created by dkpro on 2018/6/7.
//  Copyright © 2018年 dkpro. All rights reserved.
//

import UIKit
import Foundation

public extension DispatchQueue {
    private static var _onceTracker = [String]()

    public class func once(token: String, block:()->Void) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        if _onceTracker.contains(token) {
            return
        }
        
        _onceTracker.append(token)
        block()
    }
}

class DKSystem {
    class DKSystemDevice {
        /*!
         * 设备名称
         */
        var name:String? {
            return UIDevice.current.name
        }
        /*!
         * 系統名稱
         */
        var sysName:String? {
            return UIDevice.current.systemName
        }
        /*!
         * 系統版本
         */
        var version:String? {
            return UIDevice.current.systemVersion
        }
        
        var platform:String? {
            if let key = "dk.machine".cString(using: String.Encoding.utf8) {
                var size: Int = 0
                sysctlbyname(key, nil, &size, nil, 0)
                var machine = [CChar](repeating: 0, count: Int(size))
                sysctlbyname(key, &machine, &size, nil, 0)
                return String.init(cString: machine)
            }
            return nil
        }
        
        /*!
         * 设备模式
         */
        var model:String? {
            return UIDevice.current.model
        }
        /*!
         * 本地设备模式
         */
        var locModel:String? {
            return UIDevice.current.localizedModel
        }
    }
    
    class DKSystemApp {
        /*!
         * 应用名称
         */
        var name:String? {
            return Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
        }
        /*!
         * 应用版本
         */
        var version:String? {
            return Bundle.main.infoDictionary?["CFBundleShortVersionString"]  as? String
        }
        /*!
         *  Build版本
         */
        var build:String? {
            return Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        }
    }
    
    class DKSystemLocale {
        /*!
         * 本地化语言
         */
        var language:String? {
            return NSLocale.preferredLanguages[0]
        }
        /*!
         * 本地化国家
         */
        var country:String? {
            return NSLocale.current.identifier
        }
    }
    
    let device  = DKSystemDevice()
    let app     = DKSystemApp()
    let locale  = DKSystemLocale()
    
    //单例
    static var instance: DKSystem?
    
    class var shared: DKSystem {
        DispatchQueue.once(token: "com.DKSystem.dk") {
           instance = DKSystem()
        }
        return DKSystem.instance!
    }
    
}

