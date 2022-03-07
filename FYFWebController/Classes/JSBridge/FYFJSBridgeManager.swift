//
//  FYFJSBridgeManager.swift
//  FYFWebController
//
//  Created by 范云飞 on 2022/3/1.
//

import UIKit
import Foundation
import WebKit

/// jsBridge 管理类
class FYFJSBridgeManager {
    
    /// webViewID到jsBridge映射的map
    var webViewIDToJsBridgeMap: Dictionary<String, FYFWebViewJSBridge>
    
    /// 当前运行的webView的Id（nsuuid）
    var currentWebViewID:String!
    
    /// 单例
    static let shareInstance = FYFJSBridgeManager.init()
    
    init() {
        self.webViewIDToJsBridgeMap = Dictionary()
    }
    
    /// 创建一个JSBridge对象
    /// - Parameter webView: 绑定的webView
    /// - Returns: FYFWebViewJSBridge实例
    func createBridgeForWebView(webView: FYFWebView) -> FYFWebViewJSBridge {
        let jsBridge = FYFWebViewJSBridge.init(webView: webView)
        FYFJSBridgeManager.shareInstance.registor(jsBridge: jsBridge)
        return jsBridge
    }
    
    /// 获取当前正在运行浏览器对象
    /// - Returns: description
    func currentJsBridge() -> FYFWebViewJSBridge? {
        return self.webViewIDToJsBridgeMap[self.currentWebViewID] ?? nil
    }
    
    /// 获取当前正在运行浏览器对象关联的控制器
    /// - Returns: description
    func currentWebViewController() -> FYFWebViewController? {
        let currentJsBridge = self.currentJsBridge()
        let holder = currentJsBridge?.webView?.holderObject
        if holder is UIViewController {
            return (holder as! FYFWebViewController)
        }
        return nil
    }
    
    /// 注册浏览器对象
    /// - Parameter jsBridge: jsBridge description
    func registor(jsBridge: FYFWebViewJSBridge) {
        self.webViewIDToJsBridgeMap[jsBridge.webViewID] = jsBridge
        self.currentWebViewID = jsBridge.webViewID
    }
    
    /// 卸载浏览器对象
    /// - Parameter jsBridge: jsBridge description
    func unregistor(jsBridge: FYFWebViewJSBridge) {
        self.webViewIDToJsBridgeMap.removeValue(forKey: jsBridge.webViewID)
    }

    /// 清楚浏览器对象
    /// - Parameter jsBridge: jsBridge description
    func clear(jsBridge: FYFWebViewJSBridge) {
        self.webViewIDToJsBridgeMap.removeValue(forKey: jsBridge.webViewID)
        jsBridge.clear()
    }
    
    /// 原生主动调用js
    /// - Parameters:
    ///   - functionNo: 功能号
    ///   - param: param description
    func iosTriggerJS(functionNo: String, param: Any?) {
        let jsBridge = FYFJSBridgeManager.shareInstance.currentJsBridge()
        if jsBridge != nil {
            jsBridge?.iosTriggerJSFunctionNo(functionNo: functionNo, param: param)
        }
    }
}
