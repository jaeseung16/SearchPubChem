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
        navigationItem.hidesBackButton = true
        
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

extension WebPubChemViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        navigationItem.hidesBackButton = false
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        self.navigationItem.hidesBackButton = false
        
        let alert = UIAlertController(title: "Cannot load the webpage", message: "It seems that there is a problem with the network or the PubChem server", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
