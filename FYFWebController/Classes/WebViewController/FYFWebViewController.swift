//
//  FYFWebViewController.swift
//  FYFWebController
//
//  Created by 范云飞 on 2022/3/1.
//

import UIKit
import WebKit
import SnapKit
import FYFSwfitDefines
import FYFDeviceInfo


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
    public var webViewUrl: String? {
        set {
            if newValue == nil {
                return
            }
            self.privateWebViewUrl = newValue
            
            self.jsBridge?.prepareLoadUrl(urlString: newValue!)
        }
        get {
            return self.privateWebViewUrl
        }
    }
    
    fileprivate var privateWebViewUrl: String?
    
    /// 当前的webView
    fileprivate var webView: FYFWebView?
    
    /// 设置UserAgent
    /// - Parameter webView: <#webView description#>
    func setWebViewUA(_ webView: FYFWebView?) {
        /// 此部分内容需要放到setWebUI内
        let version: String = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        let customUA: String = "KingStar/APP/iOS/" + version
        if #available(iOS 12.0, *) {
            /// 由于iOS2的UA改为异步，所以不管在js还是客户端第一次加载都获取不到，所以此时需要先设置好再去获取（1、如下设置，2、现在AppDelegate中设置到本地）
            let userAgent: String = webView?.value(forKey: "applicationNameForUserAgent") as! String
            let newUserAgent = userAgent + customUA
            if !newUserAgent.contains(customUA) {
                webView?.setValue(newUserAgent, forKey: "applicationNameForUserAgent")
            }
        }
        
        webView?.evaluateJavaScript("navigator.userAgent", completionHandler: { result, error in
            let userAgent:String = result as! String
            let nsRange = NSString(string: userAgent).range(of: customUA)
            if nsRange.location != NSNotFound {
                return
            }
            
            let newUserAgent: String = userAgent.appending(customUA)
            if !newUserAgent.isEmpty {
                let dictionary: [String: String] = ["UserAgent": newUserAgent]
                UserDefaults.standard.register(defaults: dictionary)
                UserDefaults.standard.synchronize()
            }
            /// 不添加一下代码则只是在本地更改UA, 网页并未同步更改
            if #available(iOS 9.0, *) {
                webView?.customUserAgent = newUserAgent
            } else {
                webView?.setValue(newUserAgent, forKey: "applicationNameForUserAgent")
            }
            //加载请求必须同步在设置UA的后面
        })
    }
    
    /// 当前的jsBridge
    fileprivate var jsBridge: FYFWebViewJSBridge?
    /// 原生导航栏
    fileprivate lazy var navView: UIView? = {
        let navView = UIView()
        navView.backgroundColor = .white
        navView.frame = CGRect(x: 0, y: 0, width: FYFViewDefine.FYFScreenHeight, height: FYFViewDefine.FYFNavigationBarFullHeight)
        
        let backButton = UIButton()
        backButton.frame = CGRect(x: 0, y: FYFViewDefine.FYFSysStatusBarHeight, width: 40, height: FYFViewDefine.FYFNavigationBarHeight)
        backButton.setImage(FYFUIImage.webImageNamed("fyf_appicon_navback"), for: .normal)
        backButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        
        navView.addSubview(backButton)
        return navView
    }()
    
    /// 进度条
    fileprivate lazy var progressView: UIProgressView? = {
        let progressView = UIProgressView()
        if self.isUserNativeNavBar {
            progressView.frame = CGRect(x: 0, y: FYFViewDefine.FYFNavigationBarFullHeight - 1, width: FYFViewDefine.FYFScreenWidth, height: 2)
        } else {
            progressView.frame = CGRect(x: 0, y: -1, width: FYFViewDefine.FYFScreenWidth, height: 2)
        }
        progressView.transform =  CGAffineTransform(scaleX: 1.0, y: 0.5);
        progressView.progressTintColor = UIColor.hexColor(hexColor: 0x00BF13, alpha: 1)
        
        return progressView
    }()
    
    /// 刷新按钮
    fileprivate lazy var refreshButton: UIButton? = {
        let refreshButton = UIButton()
        refreshButton.setImage(FYFUIImage.webImageNamed("fyf_web_refresh_icon"), for: .normal)
        refreshButton.addTarget(self, action: #selector(refreshClick), for: .touchUpInside)
        self.view.addSubview(refreshButton)
        
        refreshButton.snp.makeConstraints { make in
            make.right.equalTo(-20)
            make.width.height.equalTo(60)
            if #available(iOS 11.0, *) {
                make.bottom.equalTo(self.view.snp_bottom).offset(-150)
            } else {
                make.bottom.equalTo(self.view).offset(-150)
            }
        }
        
        return refreshButton
    }()
    
    //MARK: - Life cycle
    
    deinit {
        FYFJSBridgeManager.shareInstance.clear(jsBridge: self.jsBridge)
//        self.webView?.removeObserver(self, forKeyPath: "estimatedProgress")
//        self.webView?.removeObserver(self, forKeyPath: "title")
//        self.webView?.removeObserver(self, forKeyPath: "canGoBack")
        
        NotificationCenter.default.removeObserver(self)
    
        self.webView?.navigationDelegate = nil
        self.webView = nil
        self.jsBridge = nil
    }
    
    /// 初始化方法
    /// - Parameter webViewUrl: url
    public init(webViewUrl: String) {
        super.init(nibName: nil, bundle: nil)
        self.webViewUrl = webViewUrl
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !self.isUserNativeNavBar {
            self.navigationController?.setNavigationBarHidden(false, animated: animated)
        }
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !self.isUserNativeNavBar {
            self.navigationController?.setNavigationBarHidden(true, animated: animated)
        }
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 17)]
        
        FYFJSBridgeManager.shareInstance.registor(jsBridge: self.jsBridge)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        
        self.createWebView()
        
        self.jsBridge = FYFJSBridgeManager.shareInstance.createBridgeForWebView(webView: self.webView)
//        self.webView?.addObserver(self, forKeyPath: "estimatedProgress", options: NSKeyValueObservingOptions.new, context: nil)
//        self.webView?.addObserver(self, forKeyPath: "title", options: NSKeyValueObservingOptions.new, context: nil)
//        self.webView?.addObserver(self, forKeyPath: "canGoBack", options: NSKeyValueObservingOptions.new, context: nil)
        
        if self.isUserNativeNavBar {
            self.title = self.navTitle
        } else {
            self.view.addSubview(self.navView!)
        }
        
        self.addNavigationLeftItem()
        self.addNavigationRightItem()
        
        self.view.addSubview(self.webView!)
        self.view.addSubview(self.progressView!)
        self.addRefreshButton()
        
        if self.webViewUrl != nil {
            self.jsBridge?.prepareLoadUrl(urlString: self.webViewUrl!)
        }
        
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(changeOrientation), name: UIWindow.didBecomeHiddenNotification, object: nil)
        
        let pluginClass: FYFBasePlugin.Type? = NSClassFromString("FYFBasePlugin") as? FYFBasePlugin.Type
        
        print(pluginClass)
        
    }
    
    func createWebView() {
        self.webView = FYFWebView()
        self.webView?.holderObject = self
        if self.isUserNativeNavBar {
            self.webView?.frame = CGRect(x: 0, y: FYFViewDefine.FYFNavigationBarFullHeight, width: FYFViewDefine.FYFScreenWidth, height: FYFViewDefine.FYFScreenHeight - FYFViewDefine.FYFNavigationBarFullHeight)
        } else {
            self.webView?.frame = CGRect(x: 0, y: 0, width: FYFViewDefine.FYFScreenWidth, height: FYFViewDefine.FYFScreenHeight)
        }
        self.webView?.backgroundColor = .white
        self.webView?.isOpaque = false
        self.webView?.navigationDelegate = self
        self.webView?.uiDelegate = self
        self.webView?.allowsBackForwardNavigationGestures = false
        self.webView?.scrollView.isScrollEnabled = true
        self.webView?.scrollView.bounces = false
        
        if #available(iOS 11.0, *) {
            self.webView?.scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            self.automaticallyAdjustsScrollViewInsets = false
        }
        
        self.setWebViewUA(self.webView!)
    }
    
    //MARK: - WKNavigationDelegate
    public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let serverTrust: SecTrust = challenge.protectionSpace.serverTrust!
        let exceptions: CFData = SecTrustCopyExceptions(serverTrust)
        SecTrustSetExceptions(serverTrust, exceptions)
        
        completionHandler(.useCredential,URLCredential.init(trust: serverTrust))
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url: URL? = navigationAction.request.url ?? nil
        let scheme = url?.scheme
        if scheme == FYFScheme {
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        let screenInfojs = "var h5InitData = {}; h5InitData.screen_info = " + "'" + FYFDeviceHelper.fyf_getSystemName() + "'" + " ;" + "h5InitData.status_bar_padding = " + "'" + String(FYFViewDefine.FYFSysStatusBarHeight) + "'" + ";"
        self.webView?.fyf_safeAsyncEvaluateJavaScriptString(script: screenInfojs)
        
        self.navView?.isHidden = false
        self.progressView?.isHidden = false
        self.view.bringSubviewToFront(self.progressView!)
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        /// 浏览器导航栏是白色，会出现闪烁，价格延迟效果
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.navView?.isHidden = true
        }
        
        /// 禁止web内长按图片放大功能
        webView.evaluateJavaScript("document.documentElement.style.webkitTouchCallout='none';", completionHandler: nil)
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        self.progressView?.isHidden = true
        self.webView?.scrollView.isScrollEnabled = true
        self.showErrorViewWithError(error: error)
    }
    
    func showErrorViewWithError(error: Error) {
        var message = "页面出错了，请稍后再试"
        if !error.localizedDescription.isEmpty {
            message = error.localizedDescription
        }
        print(message)
        
        /// 可以再次添加错误占位图，并进行重试
    }
    
    
    //MARK: - WKUIDelegate
    
    /// web界面中有弹出警告框时调用
    /// - Parameters:
    ///   - webView: 实现该代理的webView
    ///   - message: 警告框中的内容
    ///   - frame: <#frame description#>
    ///   - completionHandler: 警告框选择之后回调
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert: UIAlertController = UIAlertController.init(title: "", message: message, preferredStyle: .alert)
        let action: UIAlertAction =  UIAlertAction.init(title: "确定", style: .destructive) { action in
            completionHandler()
        }
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
    
    /// web界面中有确认框是调用
    /// - Parameters:
    ///   - webView: 实现该代理的webView
    ///   - message: 确认框中的内容
    ///   - frame: <#frame description#>
    ///   - completionHandler: 确认框选择之后回调
    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert: UIAlertController = UIAlertController.init(title: "", message: message, preferredStyle: .alert)
        let cancelAction: UIAlertAction = UIAlertAction.init(title: "取消", style: .cancel) { action in
            completionHandler(false)
        }
        
        let confirmAction: UIAlertAction = UIAlertAction.init(title: "确定", style: .destructive) { action in
            completionHandler(true)
        }
        
        alert.addAction(cancelAction)
        alert.addAction(confirmAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        ///解决内部链接无法打开问题
        if !navigationAction.targetFrame!.isMainFrame {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    //MARK: - UIGestureRecognizerDelegate
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if self.webView?.canGoBack == true {
            return false
        }
        return true
    }
    
    //MARK: - KVO Progress
    
//    func observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change context:(nullable void *)context;
    
    //MARK: - Actions
    
    @objc func close() {
        if self.navigationController?.viewControllers.count == 1 {
            self.navigationController?.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc func shareClick() {
        /// 主动调用js获取分享信息，然后在js回调结果中唤起分享组件
        FYFJSBridgeManager.shareInstance.iosTriggerJS(functionNo: FYFShareFunctionNo, param: nil)
    }
    
    @objc func refreshClick() {
        let stringCount = self.webView?.url?.absoluteString.count
        
        if stringCount == nil {
            return
        }
        if stringCount! > 0 {
            self.webView?.reload()
        }
    }
    
    func addNavigationLeftItem() {
        self.navigationItem.leftBarButtonItem = nil
        let leftView: UIView = UIView()
        let backButton: UIButton = self.createButtonWithImageOffset(offset: -10.0, imageName: "fyf_web_back_icon", selector: #selector(goBack))
        backButton.frame = CGRect(x: 0.0, y: 0.0, width: 32.0, height: FYFViewDefine.FYFNavigationBarHeight)
        leftView.addSubview(backButton)
        var leftViewW = 32.0
        if self.webView?.canGoBack == true {
            let closeButton: UIButton = self.createButtonWithImageOffset(offset: -2.0, imageName: "fyf_web_close_icon", selector: #selector(closeCurrentWebView))
            closeButton.frame = CGRect(x: 28.0, y: 0.0, width: 32.0, height: FYFViewDefine.FYFNavigationBarHeight)
            leftView.addSubview(closeButton)
            leftViewW = 60.0
        }
        leftView.frame = CGRect(x: 0.0, y: 0.0, width: leftViewW, height: FYFViewDefine.FYFNavigationBarHeight)
        let leftBarButtonItem: UIBarButtonItem = UIBarButtonItem()
        leftBarButtonItem.customView = leftView
        self.navigationItem.leftBarButtonItem = leftBarButtonItem
    }
    
    func addNavigationRightItem() {
        if self.showShareItem {
            let shareItem: UIBarButtonItem = UIBarButtonItem()
            shareItem.image = FYFUIImage.webImageNamed("fyf_web_share_icon")
            shareItem.style = UIBarButtonItem.Style.plain
            shareItem.target = self
            shareItem.action = #selector(shareClick)
            self.navigationItem.rightBarButtonItem = shareItem
        }
    }
    
    func addRefreshButton() {
        #if DEBUG
        self.view.addSubview(self.refreshButton!)
        
        #elseif DEBUG
        
        #else
        
        #endif
    }
    
    /// 这个方法让H5直接关闭当前webView, 无论H5里面进入基层H5页面
    @objc func closeCurrentWebView() {
        if (self.presentingViewController != nil) && self.navigationController?.viewControllers.count == 1 {
            self.dismiss(animated: true) {
                
            }
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc func changeOrientation() {
        /// iOS13以下导航栏会向上偏移，需要给他恢复到原来的位置
        var navFrame: CGRect = (self.navigationController?.navigationBar.frame)!
        navFrame.origin.y = FYFViewDefine.FYFStatusBarHeight
        self.navigationController?.navigationBar.frame = navFrame
        
        /// 强制归正到竖屏： 不然会影响外部页面布局
        let selector = NSSelectorFromString("setOrientation:")
        if UIDevice.current.responds(to: selector) {
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        }
    }
    
    func createButtonWithImageOffset(offset: CGFloat, imageName: String, selector: Selector) -> UIButton {
        let button:UIButton = UIButton()
        button.imageEdgeInsets = UIEdgeInsets.init(top: 0.0, left: offset, bottom: 0.0, right: 0.0)
        button.setImage(FYFUIImage.webImageNamed(imageName), for: .normal)
        button.addTarget(self, action: selector, for: UIControl.Event.touchUpInside)
        return button
    }
}


extension FYFWebViewController {
    /// 设置动态显示隐藏导航栏
    /// - Parameter show true:显示， false:隐藏
    public func setNativeNavigationBarShow(show: Bool) {
        if self.isUserNativeNavBar != show {
            self.isUserNativeNavBar = show
            if self.isUserNativeNavBar {
                self.webView?.frame = CGRect(x: 0.0, y: FYFViewDefine.FYFNavigationBarFullHeight, width: FYFViewDefine.FYFScreenWidth, height: FYFViewDefine.FYFScreenHeight - FYFViewDefine.FYFNavigationBarFullHeight)
            } else {
                self.webView?.frame = CGRect(x: 0.0, y: FYFViewDefine.FYFStatusBarHeight, width: FYFViewDefine.FYFScreenWidth, height: FYFViewDefine.FYFScreenHeight)
            }
        }
        self.view.setNeedsLayout()
        self.navigationController?.setNavigationBarHidden(!show, animated: false)
    }
    
    /// 返回上一级
    @objc public func goBack() {
        let backListCount = self.webView?.backForwardList.backList.count ?? 0
        if self.webView?.canGoBack == true || backListCount > 0 {
            /// 单一个 canGoBack不准确
            self.webView?.goBack()
        } else {
            self.closeCurrentWebView()
        }
    }
}
