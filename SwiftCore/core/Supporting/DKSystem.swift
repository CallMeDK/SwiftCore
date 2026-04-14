//
//  DKSystem.swift
//  SwiftCore
//
//  Created by dkpro on 2018/6/7.
//  Copyright © 2018年 dkpro. All rights reserved.
//

import Foundation

class DKSystem {
    class DKSystemDevice {
        /*!
         * Device name
         */
        var name: String? {
            return UIDevice.current.name
        }
        /*!
         * System name
         */
        var sysName: String? {
            return UIDevice.current.systemName
        }
        /*!
         * System version
         */
        var version: String? {
            return UIDevice.current.systemVersion
        }

        var platform: String? {
            let key = "hw.machine"
            var size: size_t = 0
            sysctlbyname(key, nil, &size, nil, 0)
            var machine = [CChar](repeating: 0, count: Int(size))
            if sysctlbyname(key, &machine, &size, nil, 0) == 0 {
                return String(cString: machine)
            }
            return nil
        }

        /*!
         * Device model
         */
        var model: String? {
            return UIDevice.current.model
        }
        /*!
         * Localized device model
         */
        var locModel: String? {
            return UIDevice.current.localizedModel
        }
    }

    class DKSystemApp {
        /*!
         * App name
         */
        var name: String? {
            guard let info = Bundle.main.infoDictionary else { return nil }
            return info["CFBundleDisplayName"] as? String ?? info["CFBundleName"] as? String
        }
        /*!
         * App version
         */
        var version: String? {
            return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        }
        /*!
         * Build version
         */
        var build: String? {
            return Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        }
    }

    class DKSystemLocale {
        /*!
         * Preferred language
         */
        var language: String? {
            return Locale.preferredLanguages.first
        }
        /*!
         * Country code
         */
        var country: String? {
            return Locale.current.regionCode
        }
    }

    let device = DKSystemDevice()
    let app = DKSystemApp()
    let locale = DKSystemLocale()

    // Singleton
    static let shared = DKSystem()

    private init() {}
}

