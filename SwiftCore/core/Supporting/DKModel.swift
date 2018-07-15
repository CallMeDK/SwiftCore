//
//  DKModel.swift
//  SwiftCore
//
//  Created by dkpro on 2018/6/10.
//  Copyright © 2018年 dkpro. All rights reserved.
//

import Foundation
import SwiftyJSON
import ObjectMapper

protocol DKAnalysisProtocol {
    static func model(json:JSON?, error:NSError?)->AnyObject?
}

class DKModel: Mappable, DKCacheProtocol {
    var modelDate:Date? = Date()

    private var _cacheKey: String?
    init() {}
    
    init(params:Dictionary<String, AnyObject>?) {
        Mapper().map(JSONObject: params, toObject: self)
    }
    
    //Mappable
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        modelDate  <-  (map["modelDate"],DateTransform())

    }
    
    func toString() -> String? {
        return Mapper().toJSONString(self, prettyPrint: false)
    }
    
    //DKCacheProtocol
    func cacheKey() -> String? {
        return _cacheKey
    }
    
    func unarchiver(json: String) {
        if let j:String = json {
            Mapper().map(JSONString: j, toObject: self)
        }
    }
    
    func archiver() -> String? {
        return Mapper().toJSONString(self, prettyPrint: false)
    }
    
    //cache
    func cache(key:String) -> Self? {
        _cacheKey = key
        if let _datas:Data = DKCache.shared.cache(key: key, type: DKCache.CacheType.model) {
            if let json = String(data: _datas, encoding: String.Encoding.utf8) {
                unarchiver(json: json)
            }
            return self
        }
        return nil
    }
    
    func save(key: inout String?) -> Void {
        if key == nil {
            key = cacheKey()
        }
        
        if key != nil {
            if let datas = self.archiver()?.data(using: String.Encoding.utf8) {
                do {
                    try DKCache.shared.cache(key: key!, datas:datas, type:DKCache.CacheType.model)
                } catch let error as NSError {
                    print(error)
                }
            }else {
                print("DKCache.cache:model archiver() 失败 key=\(key)")
            }
        } else {
            print("不支持缓存协议")
        }
    }
    
}

class DKModels: DKModel {
    var next:Bool = false
    
   override func mapping(map: Map) {
        modelDate  <-  (map["modelDate"],DateTransform())
        next             <-  map["next"]
    }
}
