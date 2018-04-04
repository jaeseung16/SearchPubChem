//
//  WebPubChemViewController.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 3/8/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import UIKit
import WebKit

class WebPubChemViewController: UIViewController {
    // MARK: - Properties
    // Outlets
    @IBOutlet weak var webView: WKWebView!
    
    // Variables
    var url: URL!
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.navigationDelegate = self
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

extension WebPubChemViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}
