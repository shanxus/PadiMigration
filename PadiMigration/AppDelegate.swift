//
//  AppDelegate.swift
//  FastQuantum
//
//  Created by Shan on 2018/3/5.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit
import Firebase
import GoogleMobileAds
import FirebaseMessaging
import FirebaseInstanceID
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        application.registerForRemoteNotifications()
        
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { (_, _) in
            
        }
        Messaging.messaging().delegate = self
        
        FirebaseApp.configure()
        GADMobileAds.configure(withApplicationID: "ca-app-pub-1195213068628759/6310070367")
        return true
    }
 
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        Messaging.messaging().shouldEstablishDirectChannel = false
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

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        print("got called")
        if let temp = userActivity.webpageURL {
            let handled = DynamicLinks.dynamicLinks().handleUniversalLink(temp, completion: { (dynamicLink, error) in
                
                if let url = dynamicLink?.url {
                    print("got url: ", url)
                    if Auth.auth().isSignIn(withEmailLink: url.absoluteString) {
                        if let account = UserDefaults.standard.string(forKey: "Email") {
                            print("pass isSignIn")
                            print("account email:", account)
                            Auth.auth().signIn(withEmail: account, link: url.absoluteString, completion: { (user, error) in
                                if error != nil {
                                    print("error when try to sign in: ", error?.localizedDescription ?? "")
                                } else {
                                    let topVC = GeneralService.findTopVC()
                                    if let tabView = topVC.storyboard?.instantiateViewController(withIdentifier: "tabView") as? UITabBarController {
                                        topVC.present(tabView, animated: true, completion: {
                                            if let currentUser = Auth.auth().currentUser {                                                
                                                let id = currentUser.uid
                                                let email = currentUser.email!
                                                let name = email.components(separatedBy: "@").first!
                                                GeneralService.createUserInDB(userID: id, email: email, name: name)
                                                
                                                UIApplication.shared.registerForRemoteNotifications()
                                            }
                                        })
                                    }
                                }
                            })
                        }
                    }
                }
            })
            return handled
        }
        return false
    }
 
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {return}
        GeneralService.storeUserMessageToken(userID: currentUserID, token: fcmToken)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert])
    }
        
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print(remoteMessage.appData)
    }
}








