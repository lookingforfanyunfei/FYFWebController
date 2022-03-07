//
//  FYFJSInvokeNativeDelegate.swift
//  FYFWebController
//
//  Created by 范云飞 on 2022/3/1.
//

import Foundation

protocol FYFJSInvokeNativeDelegate {
    
    /// js调用原生的协议方法
    /// - Parameter param: 参数
    func serverInvoke(param: Any?)

}
