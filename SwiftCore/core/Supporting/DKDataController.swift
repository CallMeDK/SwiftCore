//
//  DKDataController.swift
//  SwiftCore
//
//  Created by dkpro on 2018/6/9.
//  Copyright © 2018年 dkpro. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import ObjectMapper

class DKDataParams {
    var URL: String {
        return "https://www.apiopen.top/novelApi"
    }
    var type:Int!
    
    //默认请求参数
    private var nParams:Dictionary<String,Any> {
        var _params = Dictionary<String,AnyObject>()
        _params["version_os"] = DKSystem.shared.device.version as AnyObject
        _params["os"] = DKSystem.shared.device.sysName as AnyObject
        _params["bundleVersion"] = DKSystem.shared.app.build as AnyObject
        _params["version_pro"] = "1.0" as AnyObject
        _params["manufacturer"] = DKSystem.shared.device.model as AnyObject
        _params["language"] = DKSystem.shared.locale.language as AnyObject
        _params["model"] = DKSystem.shared.device.platform as AnyObject
        return _params
    }
    
    var params:Dictionary<String,AnyObject> = Dictionary<String,AnyObject>()
    
    init(type:Int, params p:Dictionary<String,AnyObject>?) {
        self.type = type
        self.params["requestType"] = type as AnyObject
        for (key, value) in nParams {
            self.params[key] = value as AnyObject
        }
        
        if let data = p {
            for (key, value) in data {
                self.params[key] = value as AnyObject
            }
        }
    }
}

typealias RequestBlock = ((_ result:Any?,_ error:NSError?) -> Void)?
class DKDataController {
    var queue:Dictionary<Int,Request> =  Dictionary<Int,Request>()
    func request(params:DKDataParams, anClass:AnyClass?, completed:(RequestBlock)) -> Request {
        let request = Alamofire.request(params.URL, method: HTTPMethod.post, parameters: params.params)
        print("请求地址：\(request.request?.url?.absoluteString ?? "当前请求无具体url")")
        print("请求参数：\(params.params)")
        request.responseData { (result) in
            if let datas = result.value {
                if anClass == nil { //请求没有传入解析模型
                    do {
                        let object = try JSONSerialization.jsonObject(with: datas, options: JSONSerialization.ReadingOptions.allowFragments)
                        completed?(object,nil)
                    }catch let aError as NSError {
                        completed?(datas,aError)
                    }
                } else { //请求传入了解析模型
                    do {
                        let json:JSON = try JSON.init(data: datas, options: JSONSerialization.ReadingOptions.allowFragments)
                        if let aClass = anClass as? DKAnalysisProtocol.Type {
                            if let code:Int = json["code"].rawValue as? Int , code != 200 {
                               let error = NSError.init(domain:  "请求返回错误代码", code: code, userInfo: nil)
                                completed?(nil,error)
                            } else {
                                if let result = aClass.model(json:json, error:nil) {
                                    completed?(result,nil)
                                } else {
                                    let error = NSError.init(domain:  "数据模型解析失败 <DKAnalysisProtocol>", code: 1001, userInfo: nil)
                                    completed?(datas,error)
                                }
                            }
                        } else if let aClass = anClass as? BaseMappable.Type{
                            //TODO: 可以加速code = 200的判断
                            let result = aClass.init(JSON: json.rawValue as! [String : Any])
                            completed?(result,nil)
                        } else {
                            let error = NSError.init(domain:  "数据模型不支持 DKAnalysisProtocol,BaseMappable", code: 1002, userInfo: nil)
                            completed?(datas,error)
                        }
                    } catch let bError as NSError {
                        do {
                            let object = try JSONSerialization.jsonObject(with: datas, options: JSONSerialization.ReadingOptions.allowFragments)
                            completed?(object,bError)
                        }catch let cError as NSError {
                            completed?(datas,cError)
                        }
                    }
                }
                
            } else {
                let error = NSError.init(domain:  "数据请求失败", code: 1001, userInfo: nil)
                completed?(nil,error)
            }
            
            self.cancel(type: params.type)
        }
        
        queue[params.type] = request
        return request
    }
    
    func cancel(type:Int? = nil) {
        if let _type = type , let request:Request = queue[_type] {
            request.cancel()
            queue.removeValue(forKey: _type)
        }else {
            for (_, request) in queue {
                request.cancel()
            }
            queue.removeAll()
        }
    }
    
    func cache(complated: (() -> Void)? = nil) -> Self {
        return self
    }
    
    func check(complated: ((_ type:DKUpdateType) -> Void)?) -> Self? {
        if let ob = self as? DKUpdateProtocol {
            if let rs = DKUpdate.shared.check(object: ob) {
                switch rs.type {
                case .Network:
                    complated?(DKUpdateType.Network)
                    return self
                case .Cached:
                    complated?(DKUpdateType.Cached)
                    return nil
                default:
                    break
                }
            }
        }
        return nil
    }
}

