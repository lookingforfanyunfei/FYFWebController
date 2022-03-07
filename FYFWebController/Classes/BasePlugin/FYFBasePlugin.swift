//
//  FYFBasePlugin.swift
//  FYFWebController
//
//  Created by 范云飞 on 2022/3/1.
//

import Foundation

open class FYFBasePlugin: FYFJSInvokeNativeDelegate {
    
    /// 是否需要缓存插件，默认为true
    var isCache:Bool = true
    /// 请求流水号
    var flowNo: String?
    
    /// 原生回调js
    /// - Parameters:
    ///   - flowNo: 流水号
    ///   - param: 参数
    func iosCallbackJSFlowNo(flowNo: String, param: Any?) {
        DispatchQueue.main.async {
            let jsBridge = FYFJSBridgeManager.shareInstance.currentJsBridge()
            if jsBridge != nil {
                jsBridge?.iosCallbackJSFlowNo(flowNo: flowNo, param: param)
            }
        }
    }
    
    
    //MARK: - KSJSInvokeNativeDelegate
    func serverInvoke(param: Any?) {
        //交给子类实现
    }
    
}
