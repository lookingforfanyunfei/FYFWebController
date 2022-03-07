//
//  FYFWebViewJSBridge.swift
//  FYFWebController
//
//  Created by 范云飞 on 2022/3/1.
//

import Foundation
import WebKit
import SwiftyJSON

// MARK: 字符串转字典
fileprivate extension String {
    
    func toDictionary() -> [String : Any] {
        
        var result = [String : Any]()
        guard !self.isEmpty else { return result }
        
        guard let dataSelf = self.data(using: .utf8) else {
            return result
        }
        
        if let dic = try? JSONSerialization.jsonObject(with: dataSelf,
                           options: .mutableContainers) as? [String : Any] {
            result = dic!
        }
        return result
    
    }
    
}

/// JS调用OC
let kJSCallOCMethod = "jsCallNative"
/// 回调
let kOCCallBackJSMethod = "nativeCallback"
///OC主动调用
let kOCTriggerJSMethod = "triggerMessage"

/// 请求超时时间
let KS_REQUEST_TIMEOUT_INTERVAL = 10

class FYFWebViewJSBridge:NSObject, WKScriptMessageHandler {
    
    /// jsBridge持有的webView对象
    weak var webView: FYFWebView?
    
    /// jsBridge持有的webView对象的id
    var webViewID: String
    
    init(webView: FYFWebView) {
        self.webView = webView
        self.webViewID = NSUUID.init().uuidString
        
        super.init()
        
        self.webView?.configuration.userContentController.add(self, name: kJSCallOCMethod)
    }
    
    func clear() {
        if self.webView != nil {
            self.webView?.configuration.userContentController.removeScriptMessageHandler(forName: kJSCallOCMethod)
            self.webView = nil
        }
    }
    
    deinit {
        self.clear()
    }
    
    /// 预加载，默认NSURLRequestReloadIgnoringCacheData，即没缓存
    /// - Parameter urlString: 资源地址
    func prepareLoadUrl(urlString: String) {
        self.prepareLoadUrl(urlString: urlString, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringCacheData)
    }
    
    func prepareLoadUrl(urlString: String, cachePolicy: NSURLRequest.CachePolicy) {
        /// 暂不支持加载本地文件
        let webUrl = URL.init(string: urlString)
        if webUrl != nil {
            let request = URLRequest.init(url: webUrl! as URL, cachePolicy: cachePolicy, timeoutInterval: TimeInterval(KS_REQUEST_TIMEOUT_INTERVAL))
            self.webView?.load(request)
        }
    }
    
    /// 原生回调js
    /// - Parameters:
    ///   - flowNo: 流水号
    ///   - param: 参数
    func iosCallbackJSFlowNo(flowNo: String, param: Any?) {
        if self.webView == nil || flowNo.isEmpty {
            return
        }
        
        if param == nil {
            return
        }
        
        let paramString: String = JSON.init(param ?? "").string ?? ""
        let methodString = kOCCallBackJSMethod
        let javaScriptString = methodString + "(" + "'" + flowNo + "'" + "," + paramString + ")"
        
                
        self.webView?.fyf_safeAsyncEvaluateJavaScriptString(script: javaScriptString, completion: {
            (result) in let json = JSON.init(result ?? "").string
            print("数据解析\(String(describing: json))")
        })
        
    }
    
    /// 原生主动调用js
    /// - Parameters:
    ///   - functionNo: 功能号
    ///   - param: 参数
    func iosTriggerJSFunctionNo(functionNo: String, param: Any?) {
        if self.webView == nil || functionNo.isEmpty {
            return
        }
        
        if param == nil {
            return
        }
        
        let paramString: String = JSON.init(param ?? "").string ?? ""
        let methodString = kOCTriggerJSMethod
        let javaScriptString = methodString + "(" + "'" + functionNo + "'" + "," + paramString + ")"
        self.webView?.fyf_safeAsyncEvaluateJavaScriptString(script: javaScriptString, completion: {
            (result) in if result != nil && result is Dictionary<String, Any?> {
                FYFJSInvokeCenter.shareInstance.jsCallBackNative(functionNo: functionNo, param: result)
            }
        })
    }

    //MARK: - WKScriptMessageHandler
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == kJSCallOCMethod {
            let arguments = message.body
            var userInfo:Dictionary<String, Any>?
            if arguments is Dictionary<String, Any> {
                userInfo = (arguments as! Dictionary)
            } else if (arguments is String) {
                userInfo = (arguments as! String).toDictionary()
            } else {
                
            }
            
            let funcNo:String? = userInfo?["funcNo"] as? String
            FYFJSInvokeCenter.shareInstance.invokePlugin(functionNo: funcNo ?? "" , param: userInfo)
        }
    }
}
