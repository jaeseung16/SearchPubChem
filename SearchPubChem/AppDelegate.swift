//
//  AppDelegate.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 1/15/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import UIKit
import SwiftUI

//@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let dataController = DataController(modelName: "PubChemSolution")
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        checkIfFirstLaunch()
        if let tabBarController = window?.rootViewController as? UITabBarController {
            configure(tabBarController)
            print("iPhone")
        } else if let splitViewController = window?.rootViewController as? UISplitViewController {
            configure(splitViewController)
            print("iPad")
        }
               
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        saveData()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        saveData()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

// MARK: - Convenient methods
extension AppDelegate {
    func saveData() {
        do {
            try dataController.viewContext.save()
        } catch {
            NSLog("Error while saving by AppDelegate")
        }
    }
    
    func checkIfFirstLaunch() {
        print("checkIfFirstLaunch()")
        if !UserDefaults.standard.bool(forKey: "HasLaunchedBefore") {
            print("First Launch")
            UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
            UserDefaults.standard.synchronize()
            //preloadData()
            //saveData()
        }
    }
    
    func configure(_ tabBarController: UITabBarController) {
        let viewControllers = tabBarController.viewControllers!
        
        for viewController in viewControllers {
            guard let navigationViewController = viewController as? UINavigationController else {
                break
            }
            
            if let topViewController = navigationViewController.topViewController as? CompoundTableViewController {
                navigationViewController.setViewControllers(
                    [UIHostingController(rootView:
                                            CompoundListView()
                                            .environment(\.managedObjectContext, dataController.viewContext)
                                            .environmentObject(SearchPubChemViewModel()))],
                                                                                 animated: false)
                                                             
            } else if let topViewController = navigationViewController.topViewController as? SolutionTableViewController {
                topViewController.dataController = dataController
            }
        }
    }
    
    func configure(_ splitViewController: UISplitViewController) {
        let viewControllers = splitViewController.viewControllers
        
        print("viewControllers=\(viewControllers)")
        
        guard let navigationViewController = viewControllers.first as? UINavigationController else {
            return
        }
        
        guard let topViewController = navigationViewController.topViewController as? iPadMasterTableViewController else {
            return
        }
        
        topViewController.dataController = dataController
    }
    
    func preloadData() {
        do {
            try dataController.dropAllData()
        } catch {
            NSLog("Error while dropping all objects in DB")
        }
        
        // Example Compound 1: Water
        let water = Compound(context: dataController.viewContext)
        water.name = "water"
        water.firstCharacterInName = "W"
        water.formula = "H2O"
        water.molecularWeight = 18.015
        water.cid = "962"
        water.nameIUPAC = "oxidane"
        water.image = UIImage(named: "Water")!.pngData()!
        
        // Example Compound 2: Sodium Chloride
        let sodiumChloride = Compound(context: dataController.viewContext)
        sodiumChloride.name = "sodium chloride"
        sodiumChloride.firstCharacterInName = "S"
        sodiumChloride.formula = "NaCl"
        sodiumChloride.molecularWeight = 58.44
        sodiumChloride.cid = "5234"
        sodiumChloride.nameIUPAC = "sodium chloride"
        sodiumChloride.image = UIImage(named: "NaCl")!.pngData()
        
        
        // Example Solution: Sodium Chloride Aqueous Solution
        let waterIngradient = SolutionIngradient(context: dataController.viewContext)
        waterIngradient.compound = water
        waterIngradient.amount = 1.0
        
        let sodiumChlorideIngradient = SolutionIngradient(context: dataController.viewContext)
        sodiumChlorideIngradient.compound = sodiumChloride
        sodiumChlorideIngradient.amount = 0.05
        
        let saltyWater = Solution(context: dataController.viewContext)
        waterIngradient.solution = saltyWater
        sodiumChlorideIngradient.solution = saltyWater

        // Load additional compounds
        let recordLoader = RecordLoader(dataController: dataController)
        recordLoader.loadRecords()
        
    }
}
