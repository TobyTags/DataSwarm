//
//  AppDelegate.swift
//  DataSwarm
//
//  Created by Toby on 18/06/2023.
//

import UIKit
import Firebase
import CoreMotion
import BackgroundTasks
import CoreLocation
import UserNotificationsUI
import FirebaseMessaging
import BackgroundTasks


@main
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    var locationManager: CLLocationManager?
    var viewController: ViewController!
    var timer: Timer?
    var window: UIWindow?
    var isBackgroundTaskActive = false
    var backgroundtastactive = false
    var token: Any?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Access the current scene delegate and retrieve the root view controller
        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
            if let viewController = sceneDelegate.window?.rootViewController as? ViewController {
                self.viewController = viewController
            } else {
                print("Could not cast rootViewController to ViewController")
            }
        }
        
        // Register your background task identifier
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.yourapp.backgroundtask", using: nil) { task in
            self.performBackgroundTask(task)
        }
        
        FirebaseApp.configure()
        
        // Initialize Core Location
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestAlwaysAuthorization()
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        
        // Set allowsBackgroundLocationUpdates to true to enable continuous background location updates
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager!.pausesLocationUpdatesAutomatically = false
        
        // Perform your task (e.g., location updates)
        locationManager?.startUpdatingLocation()
        
        //declaring background task
        
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { success, _ in
            guard success else {
                print("HI there")
                return
            }
            
            print("Succsess in APNS registry")
            
        }
        
        application.registerForRemoteNotifications()
        scheduleBackgroundTask()
        
        
        scheduleBackgroundTask()
        
        startBackgroundTask()
        
        Messaging.messaging().subscribe(toTopic: "DataSwarm") { error in
            print("Subscribed to DataSwarm topic")
        }
        
        
        print("didFinishLaunching")
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("HI there 2")
        locationManager?.startUpdatingLocation()
    }
    
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Set the APNS device token
        Messaging.messaging().apnsToken = deviceToken
        
        // Retrieve the FCM token
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error retrieving FCM token: \(error)")
            } else if let token = token {
                print("FCM Token: \(token)")
                self.token = token
            }
        }
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        messaging.token { token, _ in
            guard let token = token else {
                return
            }
            print("FCM Token 2222: \(token)")
        }
    }
    
    
    
    func applicationrun(_ application: UIApplication) {
        locationManager?.startUpdatingLocation()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("App did enter background")
        locationManager?.startUpdatingLocation()
        scheduleBackgroundTask()
        
        while true {
            let url = URL(string: "https://europe-west2-dataswarm-c97d2.cloudfunctions.net/SilentPush")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let payload = ["FCM": token]
            if let jsonData = try? JSONSerialization.data(withJSONObject: payload) {
                request.httpBody = jsonData
            }

            let semaphore = DispatchSemaphore(value: 0) // Create a semaphore

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                } else {
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("Response: \(responseString)")
                    }
                }
                semaphore.signal() // Signal the semaphore to indicate that the task is done
            }.resume()

            // Wait for the request to complete, or a specified timeout
            let timeout = DispatchTime.now() + .seconds(30) // Adjust the timeout as needed
            if semaphore.wait(timeout: timeout) == .timedOut {
                print("Request timed out")
            }
            print("sent")
            exit(0)
        }
        
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Stop location updates and end the background task
        //locationManager?.stopUpdatingLocation()
        isBackgroundTaskActive = false
        
        print("App will enter foreground")
    }
    
    func performBackgroundTask(_ task: BGTask) {
        // Define your background task logic here
        // This is where you can perform tasks like fetching data, updating content, etc.
        locationManager?.startUpdatingLocation()
        // Reschedule the task to run again
        scheduleBackgroundTask()
    }
    
    func scheduleBackgroundTask() {
        let request = BGAppRefreshTaskRequest(identifier: "com.yourapp.backgroundtask")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 30) // 15 minutes from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background task request submitted successfully.")
        } catch {
            print("Error scheduling background task: \(error.localizedDescription)")
        }
    }
    
    
    // Function to start a background task ---- not actualy being used rn
    func startBackgroundTask() {
        print("called")
        UIApplication.shared.beginBackgroundTask(withName: "Background Location Task") {
            self.startBackgroundTask()
            print("ood")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager?.startUpdatingLocation()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        locationManager?.startUpdatingLocation()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        let url = URL(string: "https://europe-west2-dataswarm-c97d2.cloudfunctions.net/SilentPush")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = ["FCM": token]
        if let jsonData = try? JSONSerialization.data(withJSONObject: payload) {
            request.httpBody = jsonData
        }

        let semaphore = DispatchSemaphore(value: 0) // Create a semaphore

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            } else {
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Response: \(responseString)")
                }
            }
            semaphore.signal() // Signal the semaphore to indicate that the task is done
        }.resume()

        // Wait for the request to complete, or a specified timeout
        let timeout = DispatchTime.now() + .seconds(30) // Adjust the timeout as needed
        if semaphore.wait(timeout: timeout) == .timedOut {
            print("Request timed out")
        }
    }
}
    
    
    
    
    
    /*
     
     @main
     class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {
     
     let backgroundRefreshIdentifier = "com.DataSwarm.backgroundRefresh"
     
     var backgroundTask: UIBackgroundTaskIdentifier = .invalid
     var locationManager: CLLocationManager?
     var viewController: ViewController!
     var timer: Timer?
     
     func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
     
     // Register for background app refresh using BGAppRefreshTask
     BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundRefreshIdentifier, using: nil) { task in
     self.handleBackgroundAppRefresh()
     }
     
     UNUserNotificationCenter.current().delegate = self
     application.registerForRemoteNotifications()
     
     FirebaseApp.configure()
     // Initialize your app
     
     timer = Timer()
     
     // Access the current scene delegate and retrieve the root view controller
     if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
     if let viewController = sceneDelegate.window?.rootViewController as? ViewController {
     self.viewController = viewController
     } else {
     print("Could not cast rootViewController to ViewController")
     }
     }
     
     // Initialize Core Location
     locationManager = CLLocationManager()
     locationManager?.delegate = self
     locationManager?.requestAlwaysAuthorization()
     locationManager?.desiredAccuracy = kCLLocationAccuracyBest
     locationManager?.allowsBackgroundLocationUpdates = true
     
     // Start continuous location updates
     locationManager?.startUpdatingLocation()
     
     print("didFinishLaunching")
     return true
     }
     
     // Background fetch handler
     func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
     handleBackgroundAppRefresh()
     }
     
     // Background fetch task handler
     func handleBackgroundAppRefresh() {
     // Start continuous location updates
     locationManager?.startUpdatingLocation()
     
     // Invalidate existing timers if they exist
     timer?.invalidate()
     
     var oldtimeT: Decimal = 0
     
     timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
     guard let self = self else { return }
     
     let timeT = self.viewController.readtime()
     
     if timeT != oldtimeT {
     self.viewController.allsave()
     oldtimeT = timeT
     }
     }
     
     //calling all data gathering function once
     viewController.readAndSaveAllData()
     viewController.seconddata()
     
     timer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: true) { [weak self] _ in
     self?.viewController.sendDataButtonPressed()
     }
     }
     
     func applicationDidEnterBackground(_ application: UIApplication) {
     // Start continuous location updates
     locationManager?.startUpdatingLocation()
     
     print("App did enter background")
     
     
     scheduleSilentLocalNotification()
     }
     
     func applicationWillEnterForeground(_ application: UIApplication) {
     // Stop location updates and end the background task
     locationManager?.stopUpdatingLocation()
     if self.backgroundTask != .invalid {
     application.endBackgroundTask(self.backgroundTask)
     self.backgroundTask = .invalid
     }
     
     print("App will enter foreground")
     
     do {
     // Request a background refresh task
     let request = BGAppRefreshTaskRequest(identifier: backgroundRefreshIdentifier)
     request.earliestBeginDate = Date(timeIntervalSinceNow: 10) // Schedule the task to run in 1 minute
     try BGTaskScheduler.shared.submit(request)
     
     print("Scheduled background refresh task")
     } catch {
     print("Error scheduling background refresh task: \(error)")
     }
     }
     
     func applicationWillTerminate(_ application: UIApplication) {
     //scheduleSilentLocalNotification()
     }
     
     func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
     print("Hi")
     }
     
     
     func scheduleSilentLocalNotification() {
     let content = UNMutableNotificationContent()
     content.userInfo = ["wakeUpBackground": true]
     let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: true)
     let request = UNNotificationRequest(identifier: "com.DataSwarm.silentNotification", content: content, trigger: trigger)
     
     UNUserNotificationCenter.current().add(request) { error in
     if let error = error {
     print("Error scheduling silent local notification: \(error)")
     } else {
     print("Scheduled silent local notification")
     }
     }
     }
     
     
     
     
     
     
     
     
     // MARK: UISceneSession Lifecycle
     
     func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
     // Called when a new scene session is being created.
     // Use this method to select a configuration to create the new scene with.
     return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
     }
     
     func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
     // Called when the user discards a scene session.
     // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
     // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
     }
     
     //seeing what state the app is in
     func applicationWillResignActive(_ application: UIApplication) {
     print("App will resign active")
     }
     
     func applicationDidBecomeActive(_ application: UIApplication) {
     print("App did become active")
     }
     
     }
     
     
     
     
     
     
     // <-- local schedualed notifications code -->
     
     // step 1: prermissions
     let center = UNUserNotificationCenter.current()
     center.requestAuthorization(options: [.alert, .sound])
     { (granted, error) in
     }
     
     // step 2: Create notification content
     let content = UNMutableNotificationContent()
     content.title = "Hey you did it well kinda"
     content.body = "look at meee"
     
     //step 3 make trigger
     let date = Date().addingTimeInterval(10)
     let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
     
     let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
     
     //step 4 make request
     let uuidString = UUID().uuidString
     let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
     
     //step 5 register request with notification center
     center.add(request) { (error) in
     print("there is an error \(String(describing: error))")
     }
     */
