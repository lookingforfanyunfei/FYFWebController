//
//  FYFWebView.swift
//  FYFWebController
//
//  Created by 范云飞 on 2022/3/1.
//

import Foundation
import WebKit

typealias CompletionBlock = ((_ result: Any?) -> Void)?

class FYFWebView: WKWebView {
    
    /// webView关联的FYFWebViewController
     weak var holderObject: AnyObject?
}

extension FYFWebView {
    
    /// 安全执行js
    /// - Parameter script: 要执行的js代码
    func fyf_safeAsyncEvaluateJavaScriptString(script: String) {
        fyf_safeAsyncEvaluateJavaScriptString(script: script, completion:nil )
    }
    
    /// 安全执行js
    /// - Parameters:
    ///   - script: 要执行的js代码
    ///   - completion: js执行完成的回调
    func fyf_safeAsyncEvaluateJavaScriptString(script:String, completion: CompletionBlock) {
        if !Thread.isMainThread {
            fyf_safeAsyncEvaluateJavaScriptString(script: script, completion: completion)
            
            return
        }
        
        if script.isEmpty {
            print("invalid script")
            if (completion != nil) {
                completion?("")
            }
        }
        
        evaluateJavaScript(script) { result, error in
            if error == nil {
                if completion != nil {
                    
                    var resultObj:Any = ""
                    
                    if result == nil || result is NSNull {
                        resultObj = ""
                    } else if result is NSNumber {
                        resultObj = (result as! NSNumber).stringValue
                    } else if result is NSObject {
                        resultObj = result as Any
                    } else {
                        print("evaluate js return type: \(NSStringFromClass(result as! AnyClass)), js:\(script)")
                    }
                    
                    if completion != nil {
                        completion?(resultObj)
                    }
                }
            } else {
                print("evaluate js error: \(error.debugDescription) \(script)")
                if completion != nil {
                    completion?("")
                }
            }
        }
    }
}
