//
//  DKUpdate.swift
//  SwiftCore
//
//  Created by dkpro on 2018/6/7.
//  Copyright © 2018年 dkpro. All rights reserved.
//

import Foundation

protocol DKUpdateProtocol {
    func update() -> (key:String, modelTime:Date?, action:[Int]?)
}

enum DKUpdateType : Int {
    case Null = 0       //不需要更新
    case Network = 1    //网络更新
    case Cached = 2     //缓存更新
}

class DKUpdate {
    struct DKUpdateData {
        var type:DKUpdateType = DKUpdateType.Network
        var time:Date?
        var action:Int?
    }
    
    var queue:Dictionary = Dictionary<String, DKUpdateData>()
    var zone:Dictionary = Dictionary<Int, DKUpdateData>()
    
    func update(action:Int, type:DKUpdateType = DKUpdateType.Network, time:Date? = Date()) ->Self
    {
        let params = DKUpdateData(type:type, time:time, action:action)
        zone[action] = params
        return self
    }
    
    func update(key:String, type:DKUpdateType = DKUpdateType.Network, time:Date? = Date()) ->Self
    {
        let params = DKUpdateData(type: type, time: time, action:nil)
        queue[key] = params
        return self
    }
    
    func check(object:DKUpdateProtocol) ->(obj:DKUpdate, type:DKUpdateType)? {
        let total = object.update()
        if total.action == nil {
            if let params = queue[total.key] , let ntime = params.time , let mdate = total.modelTime {
                switch ntime.compare(mdate) {
                case .orderedAscending:
                    return nil
                case .orderedDescending:
                    return (self, params.type)
                default:
                    return nil
                }
            }
        }
        return (self, DKUpdateType.Network)
    }
    
    //单例
    static var instance: DKUpdate?
    
    class var shared: DKUpdate {
        DispatchQueue.once(token: "com.DKUpdate.dk") {
            instance = DKUpdate()
        }
        return DKUpdate.instance!
    }
}
