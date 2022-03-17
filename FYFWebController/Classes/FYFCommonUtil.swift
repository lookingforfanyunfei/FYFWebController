//
//  FYFCommonUtil.swift
//  FYFDeviceInfo
//
//  Created by 范云飞 on 2022/3/17.
//

import UIKit

class FYFCommonUtil {
    
    class func getClassFromString(_ className: String) -> AnyClass! {
        /// get namespace
        let namespace = Bundle.main.infoDictionary!["CFBundleExecutable"] as! String
        
        /// get 'anyClass' with classname and namespace
        let cls: AnyClass? = NSClassFromString("\(namespace).\(className)") ?? nil
        
        // return AnyClass!
        return cls
    }
}


// MARK: 字符串转字典
extension String {
    
    func toDictionary() -> [String : Any] {
        
        var result = [String : Any]()
        guard !self.isEmpty else { return result }
        
        guard let dataSelf = self.data(using: .utf8) else {
            return result
        }
        
        if let dic = try? JSONSerialization.jsonObject(with: dataSelf,
                                                       options: .mutableContainers) as? [String : Any] {
            result = dic
        }
        return result
        
    }
    
}
