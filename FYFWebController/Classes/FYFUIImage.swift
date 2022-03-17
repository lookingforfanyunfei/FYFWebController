//
//  FYFUIImage.swift
//  FYFWebController-FYFWebController
//
//  Created by 范云飞 on 2022/3/16.
//

import UIKit

class FYFUIImage: NSObject {
        
    static var webImageBundle: Bundle? = nil

    class func webImageNamed(_ name: String?) -> UIImage? {
        if webImageBundle == nil {
            let currentBundle = Bundle.init(for: FYFUIImage.self)
            webImageBundle = Bundle(url: currentBundle.url(forResource: "FYFWebController", withExtension: "bundle")!)
        }
        return self.webImageNamed(name, in: webImageBundle)
    }

    class func webImageNamed(_ name: String?, in bundle: Bundle?) -> UIImage? {
        var resultImage: UIImage? = nil
        if let bundle = bundle {
            resultImage = UIImage(named: name ?? "", in: bundle, compatibleWith: nil)
        } else {
            resultImage = UIImage(named: name ?? "")
        }
        return resultImage
    }
}
