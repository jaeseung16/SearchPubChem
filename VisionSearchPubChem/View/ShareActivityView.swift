//
//  ShareActivityView.swift
//  VisionSearchPubChem
//
//  Created by Jae Seung Lee on 3/16/24.
//  Copyright © 2024 Jae Seung Lee. All rights reserved.
//

import SwiftUI

struct ShareActivityView: UIViewControllerRepresentable {
    let url: URL
    let applicationActivities: [UIActivity]?
    
    @Binding var failedToRemoveItem: Bool
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: applicationActivities)
        
        activityViewController.completionWithItemsHandler = { (activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, activityError: Error?) in
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                failedToRemoveItem = true
            }
        }
        
        return activityViewController
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        
    }

}
