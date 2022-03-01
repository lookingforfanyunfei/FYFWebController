//
//  FYFJSBridgeManager.swift
//  FYFWebController
//
//  Created by 范云飞 on 2022/3/1.
//

import Foundation
import WebKit

/// JS调用OC
internal let kJSCallOCMethod = "jsCallNative"
/// 回调
internal let kOCCallBackJSMethod = "nativeCallback"
///OC主动调用
internal let kOCTriggerJSMethod = "triggerMessage"

/// 请求超时时间
internal let KS_REQUEST_TIMEOUT_INTERVAL = 10


class FYFJSBridgeManager:NSObject {
    
    /// jsBridge持有的webView
    fileprivate weak var webView:FYFWebView?
    /// webView 的唯一标识
    fileprivate var webViewID: String?
    

}
