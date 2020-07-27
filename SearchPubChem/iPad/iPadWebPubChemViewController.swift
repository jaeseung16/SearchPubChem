//
//  iPadWebPubChemViewController.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 7/27/20.
//  Copyright © 2020 Jae Seung Lee. All rights reserved.
//

import UIKit

import UIKit
import WebKit

class iPadWebPubChemViewController: UIViewController {
    // MARK: - Properties
    // Outlets
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var reloadBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var stopBarButtonItem: UIBarButtonItem!
    
    // Variables
    var url: URL!
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
        loadContent()
        enableStopBarButton(true)
    }
    
    func enableStopBarButton(_ yes: Bool) {
        reloadBarButtonItem.isEnabled = !yes
        stopBarButtonItem.isEnabled = yes
    }
    
    func showNetworkIndicator(_ yes: Bool) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = yes
        navigationItem.hidesBackButton = yes
        activityIndicatorView.isHidden = !yes
        
        enableStopBarButton(yes)
    }
    
    func loadContent() {
        let request = URLRequest(url: url, timeoutInterval: 15)
        webView.load(request)
        
        showNetworkIndicator(true)
    }
    
    // Actions
    @IBAction func stopLoading(_ sender: UIBarButtonItem) {
        webView.stopLoading()
        showNetworkIndicator(false)
    }
    
    @IBAction func reload(_ sender: UIBarButtonItem) {
        loadContent()
    }
}

extension iPadWebPubChemViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        showNetworkIndicator(false)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showNetworkIndicator(false)
        
        let title = "Cannot load the webpage"
        let message = "It seems that there is a problem with the network or the PubChem server"
        presentAlert(title: title, message: message)
    }
}
