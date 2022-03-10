//
//  FYFWebViewController.swift
//  FYFWebController
//
//  Created by 范云飞 on 2022/3/1.
//

import UIKit
import WebKit
import FYFDefines
//import FYFWebComponent

fileprivate let FYFScheme = "FYF"
fileprivate let FYFShareFunctionNo = "100001"


/// 原生导航栏风格枚举
public enum FYFWebNativeNavBarStyle {
    case FYFWebNativeNavBarStyleDefault //默认
    case FYFWebNativeNavBarStyleWhite //白底
}

/// 导航栏封装完善的web容器
open class FYFWebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, UIGestureRecognizerDelegate {
    
    /// 是否使用native导航栏，默认为false，即webView自带导航栏
    public var isUserNativeNavBar: Bool = false
    /// native导航栏的标题
    public var navTitle: String?
    /// 展示导航栏分享按钮，true:展示，false:不展示
    public var showShareItem: Bool = false
    /// 原生导航栏风格，默认为FYFWebNativeNavBarStyleDefault
    public var navBarStyle: FYFWebNativeNavBarStyle = .FYFWebNativeNavBarStyleDefault
    /// webView url资源地址
    public var webViewUrl: String?
    
    
    /// 当前的webView
    fileprivate var webView: FYFWebView?
    /// 当前的jsBridge
    fileprivate var jsBridge: FYFWebViewJSBridge?
    /// 原生导航栏
    fileprivate var navView: UIView?
    /// 进度条
    fileprivate var progressView: UIProgressView?
    /// 刷新按钮
    fileprivate var refreshButton: UIButton?
    
    //MARK: - Life cycle
    
    deinit {
        FYFJSBridgeManager.shareInstance.clear(jsBridge: self.jsBridge!)
        self.webView?.removeObserver(self, forKeyPath: "estimatedProgress")
        self.webView?.removeObserver(self, forKeyPath: "title")
        self.webView?.removeObserver(self, forKeyPath: "canGoBack")
        
        NotificationCenter.default.removeObserver(self)
    
        self.webView?.navigationDelegate = nil
        self.webView = nil
        self.jsBridge = nil
    }
    
    /// 初始化方法
    /// - Parameter webViewUrl: url
    public init(webViewUrl: String) {
        self.webViewUrl = webViewUrl
        
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        
        self.jsBridge = FYFJSBridgeManager.shareInstance.createBridgeForWebView(webView: self.webView!)
        self.webView?.addObserver(self, forKeyPath: "estimatedProgress", options: NSKeyValueObservingOptions.new, context: nil)
        self.webView?.addObserver(self, forKeyPath: "title", options: NSKeyValueObservingOptions.new, context: nil)
        self.webView?.addObserver(self, forKeyPath: "canGoBack", options: NSKeyValueObservingOptions.new, context: nil)
        
        if self.isUserNativeNavBar {
            self.title = self.navTitle
        } else {
            self.view.addSubview(self.navView!)
        }
    }
    
//    func addNavationRightItem {
//        if self.showShareItem {
//            let shareItem =
//        }
//    }
    
    //MARK: - WKNavigationDelegate
    
    //MARK: - WKUIDelegate
    
    //MARK: - UIGestureRecognizerDelegate
    
    //MARK: - Getters
    lazy var headerView: UIView = {
        let navView = UIView()
        navView.backgroundColor = .white
        navView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.height, height: CGFloat(FYFSafeArea_NavBarHeight))
        return navView
    }()
}


extension FYFWebViewController {
    /// 设置动态显示隐藏导航栏
    /// - Parameter show true:显示， false:隐藏
    public func setNativeNavigationBarShow(show: Bool) {
        
    }
    
    /// 返回上一级
    public func goBack() {
        
    }
}
