//
//  ViewController.swift
//  FYFWebController
//
//  Created by 786452470@qq.com on 03/01/2022.
//  Copyright (c) 2022 786452470@qq.com. All rights reserved.
//

import UIKit
import FYFWebController
import SnapKit


class ViewController: UIViewController {

    var webViewController: FYFWebViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let htmlButton = UIButton()
        htmlButton.setTitle("原生文件", for: .normal)
        htmlButton.setTitleColor(.black, for: .normal)
        htmlButton.addTarget(self, action: #selector(htmlClick), for: .touchUpInside)
        self.view.addSubview(htmlButton)
        htmlButton.snp.makeConstraints { make in
            make.centerX.equalTo(self.view)
            make.top.equalTo(self.view).offset(300)
            make.size.equalTo(CGSize(width: 80, height: 30))
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func htmlClick() {
        
        let webVC: FYFWebViewController = FYFWebViewController.init(webViewUrl: "https://luna.gtjaqh.com/news-static/html/2021/0825/af7c33e841a0e3bc02cabf66b590e2e5.html")
//        let webVC: FYFWebViewController = FYFWebViewController.init(webViewUrl: "https://www.baidu.com/")
        webVC.isUserNativeNavBar = true
        webVC.showShareItem = true
        self.navigationController?.pushViewController(webVC, animated: true)
    }
}

