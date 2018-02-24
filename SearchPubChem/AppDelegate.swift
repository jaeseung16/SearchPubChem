//
//  AppDelegate.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 1/15/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let dataController = DataController(modelName: "PubChemSolution")
    let stack = CoreDataStack(modelName: "PubChemSolution")!
 
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        dataController.load()
        
        let tabBarController = window?.rootViewController as! UITabBarController
        let navigationViewController = tabBarController.viewControllers![0] as! UINavigationController
        let chemicalTableViewController = navigationViewController.topViewController as! ChemicalTableViewController
        chemicalTableViewController.dataController = dataController
        
        checkIfFirstLaunch()

        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        saveData()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
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

// MARK: - Convenient functions
extension AppDelegate {
    func checkIfFirstLaunch() {
        if UserDefaults.standard.bool(forKey: "HasLaunchedBefore") {
            print("Not First Launch")
        } else {
            UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
            UserDefaults.standard.synchronize()
            preloadData()
        }
    }
    
    func saveViewContext() {
        do {
            try dataController.viewContext.save()
        } catch {
            print("Error whie saving in AppDelegate")
        }
    }
    
    
    func saveData() {
        do {
            try dataController.viewContext.save()
        } catch {
            print("Error while saving")
        }
    }
    
    
    func preloadData() {
        do {
            try dataController.dropAllData()
        } catch {
            print("Error while dropping all objects in DB")
        }
        
        let water = Compound(context: dataController.viewContext)
        water.name = "water"
        water.formula = "H2O"
        water.molecularWeight = 18.015
        water.cid = "962"
        water.nameIUPAC = "oxidane"
        water.partitionCoefficient = -0.5
        water.image = UIImagePNGRepresentation(UIImage(named: "Water")!)!
        water.created = Date()
        
        let sodiumChloride = Compound(context: dataController.viewContext)
        sodiumChloride.name = "sodium chloride"
        sodiumChloride.formula = "NaCl"
        sodiumChloride.molecularWeight = 58.44
        sodiumChloride.cid = "5234"
        sodiumChloride.nameIUPAC = "sodium chloride"
        sodiumChloride.image = UIImagePNGRepresentation(UIImage(named: "NaCl")!)
        sodiumChloride.created = Date()
        
        let amounts = [water.name!: 1.0, sodiumChloride.name!: 0.05]
        
        let saltyWater = Solution(context: dataController.viewContext)
        saltyWater.name = "salty water"
        saltyWater.compounds = NSSet(array: [water, sodiumChloride])
        saltyWater.amount = amounts as NSObject
        saltyWater.created = Date()
        
        //saltyWater.addToCompounds([water, sodiumChloride])
    }
}
