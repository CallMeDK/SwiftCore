//
//  DKUpdate.swift
//  SwiftCore
//
//  Created by dkpro on 2018/6/7.
//  Copyright © 2018年 dkpro. All rights reserved.
//

import Foundation

protocol DKUpdateProtocol {
    func update() -> (key: String, modelTime: Date?, action: [Int]?)
}

enum DKUpdateType: Int {
    case Null = 0       // 不需要更新
    case Network = 1    // 网络更新
    case Cached = 2     // 缓存更新
}

class DKUpdate {
    struct DKUpdateData {
        var type: DKUpdateType = .Network
        var time: Date?
        var action: Int?
    }

    private var queue = [String: DKUpdateData]()
    private var zone = [Int: DKUpdateData]()
    private let lock = NSLock()
    private let maxCacheSize = 1000

    func update(action: Int, type: DKUpdateType = .Network, time: Date? = Date()) -> Self {
        lock.lock()
        let data = DKUpdateData(type: type, time: time, action: action)
        zone[action] = data
        if zone.count > maxCacheSize {
            // 简单清理：移除一半
            let keysToRemove = zone.keys.prefix(zone.count / 2)
            for key in keysToRemove {
                zone.removeValue(forKey: key)
            }
        }
        lock.unlock()
        return self
    }

    func update(key: String, type: DKUpdateType = .Network, time: Date? = Date()) -> Self {
        lock.lock()
        let data = DKUpdateData(type: type, time: time, action: nil)
        queue[key] = data
        if queue.count > maxCacheSize {
            // 简单清理：移除一半
            let keysToRemove = queue.keys.prefix(queue.count / 2)
            for key in keysToRemove {
                queue.removeValue(forKey: key)
            }
        }
        lock.unlock()
        return self
    }

    func check(object: DKUpdateProtocol) -> (obj: DKUpdate, type: DKUpdateType)? {
        let total = object.update()
        lock.lock()
        defer { lock.unlock() }

        if let actions = total.action, !actions.isEmpty {
            // 检查zone中是否有匹配的action
            for action in actions {
                if let data = zone[action], let updateTime = data.time, let modelTime = total.modelTime {
                    if updateTime > modelTime {
                        return (self, data.type)
                    }
                }
            }
            return (self, .Network)
        } else {
            // 检查queue
            if let data = queue[total.key], let updateTime = data.time, let modelTime = total.modelTime {
                if updateTime > modelTime {
                    return (self, data.type)
                }
            }
            return (self, .Network)
        }
    }

    // Singleton
    static let shared = DKUpdate()

    private init() {}
}
