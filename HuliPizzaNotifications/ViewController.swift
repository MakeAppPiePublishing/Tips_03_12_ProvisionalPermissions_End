//
//  HuliPizzaNotification
//
//  A Demo for iOS Development Tips Weekly
//  by Steven Lipton (C)2018, All rights reserved
//  For videos go to http://bit.ly/TipsLinkedInLearning
//  For code go to http://bit.ly/AppPieGithub
//
//  This code is adapted from the course **Learning iOS Notifications**
//  go to http://bit.ly/LocalNotificationsLinkedIn for more
//  info on this code.
//  ViewController.swift
//  HuliPizzaNotification
//
//  Created by Steven Lipton on 1/10/17.
//  Copyright © 2017 Steven Lipton. All rights reserved.
//

import UIKit
import UserNotifications

class ViewController: UIViewController,UNUserNotificationCenterDelegate {
    
    @IBOutlet weak var stackView: UIStackView!
    var pizzaNumber = 0
    let pizzaSteps = ["Make pizza", "Roll Dough", "Add Sauce", "Add Cheese", "Add Ingredients", "Bake", "Done"]
    var isGrantedNotificationAccess = false
    func updatePizzaStep(request:UNNotificationRequest){
        if request.identifier.hasPrefix("message.pizza"){
            var stepnumber = request.content.userInfo["step"] as! Int
            stepnumber = (stepnumber + 1 ) % pizzaSteps.count
            let updatedContent = makePizzaContent()
            updatedContent.body = pizzaSteps[stepnumber]
            updatedContent.userInfo["step"] = stepnumber
            updatedContent.subtitle = request.content.subtitle
            addNotification(trigger: request.trigger, content: updatedContent, identifier: request.identifier)
            
        }
        
    }
    
    func makePizzaContent() -> UNMutableNotificationContent{
        let content = UNMutableNotificationContent()
        content.title = "A Timed Pizza Step"
        content.body = "Making Pizza"
        content.userInfo = ["step":0]
        content.categoryIdentifier = "pizza.steps.category"
        
        return content
    }
    
    func addNotification(trigger:UNNotificationTrigger?, content:UNMutableNotificationContent, identifier:String){
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request){
            (error) in
            if let error = error {
                print("error adding notification" + error.localizedDescription)
            }
        }
        
    }
    
    @IBAction func schedulePizza(_ sender: UIButton) {
        if isGrantedNotificationAccess{
            let content = UNMutableNotificationContent()
            content.title = "A Scheduled Pizza"
            content.body = "Time to make a Pizza!!!!"
            content.categoryIdentifier = "snooze.category"
            let unitFlags:Set<Calendar.Component> = [.minute,.hour,.second]
            var date = Calendar.current.dateComponents(unitFlags, from: Date())
            date.second = date.second! + 15
            
            
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: false)
            addNotification(trigger: trigger, content: content, identifier: "message.scheduled")
        }
    }
    @IBAction func makePizza(_ sender: UIButton) {
        if isGrantedNotificationAccess{
            let content = makePizzaContent()
            pizzaNumber += 1
            content.subtitle = "Pizza \(pizzaNumber)"
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5.0, repeats: false)
            //let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60.0, repeats: true)
            addNotification(trigger: trigger, content: content, identifier: "message.pizza.\(pizzaNumber)")
        }
    }
    
    @IBAction func nextPizzaStep(_ sender: UIButton) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
            if let request = requests.first{
                if request.identifier.hasPrefix("message.pizza"){
                    self.updatePizzaStep(request: request)
                } else {
                    let content = request.content.mutableCopy() as! UNMutableNotificationContent
                    self.addNotification(trigger: request.trigger!, content: content, identifier: request.identifier)
                }
            }
        }
    }
    
    @IBAction func viewPendingPizzas(_ sender: UIButton) {
        UNUserNotificationCenter.current().getPendingNotificationRequests {
            (requestList) in
            print("\(Date()) --> \(requestList.count) requests pending")
            for request in requestList{
                print("\(request.identifier) body:\(request.content.body)")
            }
        }
    }
    
    @IBAction func viewDeliveredPizzas(_ sender: UIButton) {
        UNUserNotificationCenter.current().getDeliveredNotifications { (notifications) in
            print("\(Date()) ----\(notifications.count) delivered")
            for notification in notifications{
                print("\(notification.request.identifier)  \(notification.request.content.body)")
            }
        }
    }
    
    @IBAction func removeNotification(_ sender: UIButton) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
            if let request = requests.first{
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [request.identifier])
            }
        }
        
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.badge,.sound, .provisional]) { (granted, error) in
            self.isGrantedNotificationAccess = granted
            if !granted {
                //add alert to complain to user
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        // Code added for iOS Developer Tips
        // Will be explained in a upcoming tip, but causes all buttons
        // in the stackview to be round with a yellow highlight.
        // do it here bcuse this uses width.
        for arrangedSubview in stackView.arrangedSubviews{
            let radius = arrangedSubview.frame.height / 2.0
            if let button = arrangedSubview as? UIButton{
                arrangedSubview.layer.cornerRadius = radius
                //normally I'd set button colors only once, but to prevent distraction from lesson it is here. 
                button.setTitleColor(UIColor(named: "Sunglow"), for: .highlighted)
            }
        }
    }
    
    //MARK: - Delegates
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert,.sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let action = response.actionIdentifier
        let request = response.notification.request
        if action == "next.step.action"{
            updatePizzaStep(request: request)
        }
        if action == "stop.action"{
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [request.identifier])
            
        }
        
        if action == "snooze.action"{
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 7.0, repeats: false)
            let newRequest = UNNotificationRequest(identifier: request.identifier, content: request.content, trigger: trigger)
            UNUserNotificationCenter.current().add(newRequest, withCompletionHandler: { (error) in
                if error != nil {
                    print("\(error?.localizedDescription ?? "Unknown")")
                }
            })
        }
        if action == "text.input"{
            let textResponse = response as!UNTextInputNotificationResponse
            let newContent = request.content.mutableCopy() as! UNMutableNotificationContent
            newContent.subtitle = textResponse.userText
            addNotification(trigger: request.trigger, content: newContent, identifier: request.identifier)
        }
        completionHandler()
    }
    
    
    
    
    
    
    
    
    
    
    
}















