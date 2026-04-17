//
//  DKUpdate.swift
//  SwiftCore
//
//  Created by dkpro on 2018/6/7.
//  Copyright © 2018年 dkpro. All rights reserved.
//

import Foundation

/// Protocol for objects that can be updated.
public protocol DKUpdateProtocol {
    /// Returns the key, model time, and optional actions for update checking.
    func update() -> (key: String, modelTime: Date?, action: [Int]?)
}

/// Enum representing the type of update.
public enum DKUpdateType: Int {
    case none = 0       // No update needed
    case network = 1    // Network update
    case cached = 2     // Cached update
}

public class DKUpdate {
    struct DKUpdateData {
        var type: DKUpdateType = .network
        var time: Date?
        var action: Int?
    }

    private var queue = [String: DKUpdateData]()
    private var zone = [Int: DKUpdateData]()
    private let lock = NSLock()
    private let maxCacheSize = 1000

    /// Updates the zone with the given action.
    /// - Parameters:
    ///   - action: The action identifier.
    ///   - type: The type of update.
    ///   - time: The update time.
    /// - Returns: Self for chaining.
    public func update(action: Int, type: DKUpdateType = .network, time: Date? = Date()) -> Self {
        lock.lock()
        let data = DKUpdateData(type: type, time: time, action: action)
        zone[action] = data
        if zone.count > maxCacheSize {
            // Simple cleanup: remove oldest half
            let sortedKeys = zone.keys.sorted(by: { zone[$0]!.time ?? Date.distantPast < zone[$1]!.time ?? Date.distantPast })
            let keysToRemove = sortedKeys.prefix(zone.count / 2)
            for key in keysToRemove {
                zone.removeValue(forKey: key)
            }
        }
        lock.unlock()
        return self
    }

    /// Updates the queue with the given key.
    /// - Parameters:
    ///   - key: The key identifier.
    ///   - type: The type of update.
    ///   - time: The update time.
    /// - Returns: Self for chaining.
    public func update(key: String, type: DKUpdateType = .network, time: Date? = Date()) -> Self {
        lock.lock()
        let data = DKUpdateData(type: type, time: time, action: nil)
        queue[key] = data
        if queue.count > maxCacheSize {
            // Simple cleanup: remove oldest half
            let sortedKeys = queue.keys.sorted(by: { queue[$0]!.time ?? Date.distantPast < queue[$1]!.time ?? Date.distantPast })
            let keysToRemove = sortedKeys.prefix(queue.count / 2)
            for key in keysToRemove {
                queue.removeValue(forKey: key)
            }
        }
        lock.unlock()
        return self
    }

    /// Checks if an update is needed for the given object.
    /// - Parameter object: The object conforming to DKUpdateProtocol.
    /// - Returns: The type of update needed, or nil if no update.
    public func check(object: DKUpdateProtocol) -> DKUpdateType? {
        let total = object.update()
        lock.lock()
        defer { lock.unlock() }

        if let actions = total.action, !actions.isEmpty {
            // Check zone for matching actions
            for action in actions {
                if let data = zone[action], let updateTime = data.time, let modelTime = total.modelTime, updateTime > modelTime {
                    return data.type
                }
            }
            return .network
        } else {
            // Check queue
            if let data = queue[total.key], let updateTime = data.time, let modelTime = total.modelTime, updateTime > modelTime {
                return data.type
            }
            return .network
        }
    }

    /// Singleton instance.
    public static let shared = DKUpdate()

    private init() {}
}
