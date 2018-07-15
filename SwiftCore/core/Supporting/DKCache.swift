//
//  DKCache.swift
//  SwiftCore
//
//  Created by dkpro on 2018/6/7.
//  Copyright © 2018年 dkpro. All rights reserved.
//

import Foundation
import SQLite

protocol DKCacheProtocol {
    func cacheKey() -> String?
    func unarchiver(json:String)
    func archiver() -> String?
}

class DKCache {
    class DKTable {
        var filePath: String {
            return NSHomeDirectory().appending("/Documents/cache.sqlite")
        }
        let c_tname = "cache"
        let c_vname = "version"

        let key = Expression<String>("key")
        let datas = Expression<Data?>("datas")
        let type = Expression<Int>("type")
        
        let table = Expression<String>("table")
        let vraw = Expression<Int>("version")
        
        init() {
            if !FileManager.default.fileExists(atPath: filePath) {
                do {
                    let db = try Connection(filePath)
                    let cache = Table(c_tname)
                    
                    try db.run(cache.create { t in
                        t.column(key, primaryKey: true)
                        t.column(datas)
                        t.column(type)
                    })
                    
                    let version = Table(c_vname)
                    try db.run(version.create{ t in
                        t.column(table, primaryKey: true)
                        t.column(vraw)
                    })

                    let insert = version.insert(or: .replace, table <- c_tname, vraw <- 1)
                    try db.run(insert)
                } catch let error as NSError {
                    print("创建缓存数据库失败 \(error.description)")
                    try! FileManager.default.removeItem(atPath: filePath)
                }
            }
        }
        
        func insert(key k:String,datas d:Data,type t:Int) throws {
            let db = try Connection(filePath)
            let caches = Table(c_tname)
            let insert = caches.insert(or: .replace, key <- k, datas <- d, type <- t)
            try db.run(insert)
        }
        
        func select(key k:String, type t:Int) throws -> Data? {
            let db = try Connection(filePath)
            let caches = Table(c_tname)
            let select = caches.select(datas).filter(key == k).filter(type == t)
            
            if let row = try? db.prepare(select).first(where: { (rows) -> Bool in
                return true
            }) {
                return try! row?.get(datas)
            }
            return nil
        }
    }
    
    enum CacheType:Int {
        case model = 1
        case setting = 2
    }
    
    let table:DKTable = DKTable()
    var queue:Dictionary<String,Data> = Dictionary<String,Data>()

    static var instance: DKCache?
    
    class var shared: DKCache {
        DispatchQueue.once(token: "com.DKCache.dk") {
            instance = DKCache()
        }
        return DKCache.instance!
    }
    
    func tKey(type:CacheType=CacheType.model , value:String)->String {
        return "\(type.rawValue)$_\(value)"
    }
    
    func cache(key:String, datas:Data, type:CacheType) throws {
        let vkey = tKey(type: type, value:key)
        queue[vkey] = datas
        do {
            try table.insert(key: vkey, datas: datas, type: type.rawValue)
        } catch let error {
            throw error
        }
    }
    
    func cache(key:String, type:CacheType) ->Data? {
        let vkey = tKey(type: type, value:key)
        var _datas = queue[vkey]
        
        if _datas == nil {
            do {
                _datas = try table.select(key: vkey, type: type.rawValue)
            } catch {
                print("查询缓存异常")
            }
        }
        return _datas
    }
}
