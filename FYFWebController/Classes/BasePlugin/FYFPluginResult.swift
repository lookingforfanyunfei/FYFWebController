//
//  FYFPluginResult.swift
//  FYFWebController
//
//  Created by 范云飞 on 2022/3/1.
//

import Foundation

public enum FYFPluginErrorCode: Int {
    case FYFPluginErrorCodeSuccess = 0 //成功
    case FYFPluginErrorCodeNotExist = -1 //不存在对应的插件
    case FYFPluginErrorCodeIllegalInputParams = -2 //不合法的入参
    case FYFPluginErrorCodeIllegalRequestFailure = -3 //网络请求失败
    case FYFPluginErrorCodeIllegalServerResponse = -4 //服务器返回的信息解析失败
    case FYFPluginErrorCodeFailed = -5 //消息号处理失败
    case FYFPluginErrorCodePermissions = -6 //域名权限不足
    case FYFPluginErrorCodeUserPermissions = -7 //系统权限不足
    case FYFPluginErrorCodeDefault = -999 //消息号处理失败
}

open class FYFPluginResult {
    
    /// 错误号
    public var errorCode: FYFPluginErrorCode?
    /// 错误信息
    public var errorInfo: String?
    /// 结果集
    public var results: AnyObject?
    
    init() {
        self.errorCode = FYFPluginErrorCode.FYFPluginErrorCodeDefault
        self.errorInfo = "消息号处理失败"
        self.results = nil
    }

}
