//
//  FYFJSInvokeCenter.swift
//  FYFWebController
//
//  Created by 范云飞 on 2022/3/1.
//

import Foundation

let FYFPluginPrefix = "FYFPlugin"

/// js调用原生的触发类型
class FYFJSInvokeCenter {
    
    /// 功能号到插件名的映射
    var functionNoToPluginNameMap: Dictionary<String, String>!
    
    /// 功能号到插件对象的映射
    var functionNoToPluginObjectMap: Dictionary<String, FYFBasePlugin?>!
    
    /// 单例
    static let shareInstance = FYFJSInvokeCenter.init()
    
    init() {
        self.functionNoToPluginNameMap = Dictionary()
        self.functionNoToPluginObjectMap = Dictionary()
    }
    
    /// js调用native方法入口
    /// - Parameters:
    ///   - functionNo: 功能号
    ///   - param: 参数
    func invokePlugin(functionNo: String, param: Any?) {
        invokeNative(functionNo: functionNo, param: param)
    }
    
    /// js回调原生
    /// - Parameters:
    ///   - functionNo: 功能号
    ///   - param: 参数
    func jsCallBackNative(functionNo: String, param: Any?) {
        invokeNative(functionNo: functionNo, param: param)
    }
    
    func invokeNative(functionNo: String, param: Any?) {
        if functionNo.isEmpty {
            return
        }
        
        var parameters = param
        if parameters == nil {
            parameters = Dictionary<String, Any>()
        }
        
        var pluginName = self.functionNoToPluginNameMap[functionNo]
        if pluginName == nil {
            //根据功能号和前缀拼接pluginName规则，例如：KSPLugin100000
            pluginName = FYFPluginPrefix + functionNo
            self.functionNoToPluginNameMap[pluginName!] = functionNo
        }
        
        let pluginClass:FYFBasePlugin.Type?  = FYFCommonUtil.getClassFromString(pluginName!) as? FYFBasePlugin.Type

        /// 判断是否存在实例插件类型
        if pluginClass != nil {
            var pluginInstance = self.functionNoToPluginObjectMap[functionNo] ?? nil
            if pluginInstance == nil {
                pluginInstance = pluginClass!.init()
                if pluginInstance?.isCache == true {
                    self.functionNoToPluginObjectMap[functionNo] = pluginInstance
                }
            }

            pluginInstance?.flowNo = (parameters as! Dictionary<String, Any>)["flowNo"] as? String
            pluginInstance?.serverInvoke(param: parameters)
        } else {
            let error: String = "插件[" + pluginName! + "]对应的类不存在!"
            print(error)
        }
    }
}
