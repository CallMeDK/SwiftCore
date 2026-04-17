//
//  DKCache.swift
//  SwiftCore
//
//  Created by dkpro on 2018/6/7.
//  Copyright © 2018年 dkpro. All rights reserved.
//

import Foundation
import SQLite

public protocol DKCacheProtocol {
    func cacheKey() -> String?
    func unarchiver(json: String)
    func archiver() -> String?
}

public class DKCache {
    class DKTable {
        let filePath: String
        let cacheTableName = "cache"

        let key = Expression<String>("key")
        let datas = Expression<Data?>("datas")
        let type = Expression<Int>("type")

        private var db: Connection?

        init() {
            filePath = NSHomeDirectory().appending("/Documents/cache.sqlite")
            if !FileManager.default.fileExists(atPath: filePath) {
                do {
                    db = try Connection(filePath)
                    let cache = Table(cacheTableName)

                    try db!.run(cache.create { t in
                        t.column(key, primaryKey: true)
                        t.column(datas)
                        t.column(type)
                    })
                } catch let error as NSError {
                    print("创建缓存数据库失败 \(error.description)")
                    try? FileManager.default.removeItem(atPath: filePath)
                    db = nil
                }
            } else {
                do {
                    db = try Connection(filePath)
                } catch {
                    print("连接缓存数据库失败")
                    db = nil
                }
            }
        }

        func insert(key k: String, datas d: Data, type t: Int) throws {
            guard let db = db else { throw NSError(domain: "DKCache", code: 1, userInfo: [NSLocalizedDescriptionKey: "Database not available"]) }
            let caches = Table(cacheTableName)
            let insert = caches.insert(or: .replace, key <- k, datas <- d, type <- t)
            try db.run(insert)
        }
        func select(key k: String, type t: Int) throws -> Data? {
            guard let db = db else { throw NSError(domain: "DKCache", code: 1, userInfo: [NSLocalizedDescriptionKey: "Database not available"]) }
            let caches = Table(cacheTableName)
            let select = caches.select(datas).filter(key == k).filter(type == t)

            if let row = try db.prepare(select).first(where: { _ in true }) {
                return try row.get(datas)
            }
            return nil
        }
    }

    enum CacheType: Int {
        case model = 1
        case setting = 2
    }

    private let table: DKTable
    private var queue: [String: Data] = [:]
    private let queueLock = NSLock()
    private let maxQueueSize = 1000 // 最大内存缓存项数

    static let shared = DKCache()

    private init() {
        table = DKTable()
    }

    private func tKey(type: CacheType = .model, value: String) -> String {
        return "\(type.rawValue)$_\(value)"
    }

    func cache(key: String, datas: Data, type: CacheType) throws {
        let vkey = tKey(type: type, value: key)
        queueLock.lock()
        queue[vkey] = datas
        if queue.count > maxQueueSize {
            // 简单策略：移除最旧的项（这里随机移除一个，实际可实现LRU）
            if let keyToRemove = queue.keys.first {
                queue.removeValue(forKey: keyToRemove)
            }
        }
        queueLock.unlock()
        try table.insert(key: vkey, datas: datas, type: type.rawValue)
    }

    func cache(key: String, type: CacheType) -> Data? {
        let vkey = tKey(type: type, value: key)
        queueLock.lock()
        var _datas = queue[vkey]
        queueLock.unlock()

        if _datas == nil {
            do {
                _datas = try table.select(key: vkey, type: type.rawValue)
                if let data = _datas {
                    queueLock.lock()
                    queue[vkey] = data
                    if queue.count > maxQueueSize {
                        if let keyToRemove = queue.keys.first {
                            queue.removeValue(forKey: keyToRemove)
                        }
                    }
                    queueLock.unlock()
                }
            } catch {
                print("查询缓存异常: \(error)")
            }
        }
        return _datas
    }
}
