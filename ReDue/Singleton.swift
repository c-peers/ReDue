//
//  Singleton.swift
//  RepeatingTasks
//
//  Created by Chase Peers on 8/10/17.
//  Copyright © 2017 Chase Peers. All rights reserved.
//

import Foundation
import UserNotifications
import AudioToolbox

class CountdownTimer: NSObject {
    
    var isEnabled = false
    var firedFromMainVC = false

    @objc dynamic var remainingTime = 0
    var run = Timer()
    
    var cell: TaskCollectionViewCell? = nil
    
    var startTime = Date().timeIntervalSince1970
    var endTime = Date().timeIntervalSince1970
    var currentTime = Date().timeIntervalSince1970
    
    @objc dynamic var elapsedTime = 0.0
    @objc dynamic var runningCompletedTime = 0.0
    
    //var taskData = TaskData()
    
    func startTimer(for view: Any?) {
        
        var test = [view]
        test.append("name")
        run = Timer.scheduledTimer(timeInterval: 1.0, target: self,
                                              selector: #selector(TaskCollectionViewCell.timerRunning), userInfo: view, repeats: true)
        
    }
    
    func stopTimer(for view: Any?) {
        run.invalidate()        
    }
    
    @objc func timerRunning() {
        
    }
    
    func formatTimer(for task: Task, from cell: TaskCollectionViewCell? = nil, ofType type: CellType? = nil) -> (String, Double) {
        // Used for initialization and when the task timer is updated

        currentTime = Date().timeIntervalSince1970
        print(task.completed)
        elapsedTime = task.completed

        if self.isEnabled && task.isRunning {
            elapsedTime += (currentTime - startTime)
        }
        
        let weightedTime = task.weightedTime
        let remainingTime = weightedTime - elapsedTime
        
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional

        if remainingTime < 60 {
            formatter.allowedUnits = [.minute, .second]
            formatter.zeroFormattingBehavior = .pad
        } else {
            formatter.allowedUnits = [.hour, .minute, .second]
            formatter.zeroFormattingBehavior = .default
        }
        
        var remainingTimeAsString = formatter.string(from: TimeInterval(remainingTime.rounded()))!
        
        if remainingTime <= 0 {
            remainingTimeAsString = "Complete"
        }
        
        if (cell != nil) {
            
            let currentProgress = 1 - Float(remainingTime)/Float(weightedTime)
            
            if type == .line {
                //TaskViewController.calculateProgress()
                //cell!.progressView.setProgress(currentProgress, animated: true)
            
            } else if type == .circular {
                cell!.circleProgressView.progress = Double(currentProgress)
            }
            
            print("Current progress is \(currentProgress)")
            
            cell!.taskTimeRemaining.text = remainingTimeAsString
            
        }
        
        return (remainingTimeAsString, remainingTime)
        
    }
    
    /* Returns whatever value returned from the above function (getRemainingTime)
     as a string. Pads 0: if there is less than 60 seconds */
    func getRemainingTimeAsString(withRemaining remaining: Double) -> String {
        
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        
        if remaining < 60 {
            formatter.allowedUnits = [.minute, .second]
            formatter.zeroFormattingBehavior = .pad
        } else {
            formatter.allowedUnits = [.hour, .minute, .second]
            formatter.zeroFormattingBehavior = .default
        }
        
        let remainingTimeAsString = formatter.string(from: TimeInterval(remaining.rounded()))!
        
        return remainingTimeAsString
    }

//    func getWeightedTime(for task: String) -> (Double, Double) {
//
//        let taskTime = taskData.taskTime
//        let rolloverMultiplier = taskData.rolloverMultiplier
//        let rolloverTime = taskData.rolloverTime
//
//        return (taskTime, taskTime + (rolloverTime * rolloverMultiplier))
//
//    }
    
    // MARK: - Audio and Vibration Functions
    
    func vibrate(for task: Task) {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate), nil)
        AudioServicesPlaySystemSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate), nil)
        _ = task.vibrateAlert.run
    }
    
    func playAudio(for task: Task) {
        
        guard let periodIndex = task.audioAlert.rawValue.index(of: ".") else { return }
        let indexAfterPeriod = task.audioAlert.rawValue.index(after: periodIndex)
        let fileName = task.audioAlert.rawValue[..<periodIndex]
        let fileType = task.audioAlert.rawValue[indexAfterPeriod...]//.suffix(from: periodIndex)
        
        print(String(fileName))
        print(String(fileType))

        if let soundUrl = Bundle.main.url(forResource: String(fileName), withExtension: String(fileType)) {
            var soundId: SystemSoundID = 0
            
            AudioServicesCreateSystemSoundID(soundUrl as CFURL, &soundId)
            
            AudioServicesAddSystemSoundCompletion(soundId, nil, nil, { (soundId, clientData) -> Void in
                AudioServicesDisposeSystemSoundID(soundId)
            }, nil)
            
            AudioServicesPlaySystemSound(soundId)
        }

    }
    
    func setAlertText(for audio: AudioAlert, and vibrate: VibrateAlert) -> String {
        
        var alertText = String()
        if audio != .none {
            guard let periodIndex = audio.rawValue.index(of: ".") else { return "" }
            let name = audio.rawValue.prefix(upTo: periodIndex).replacingOccurrences(of: "_", with: " ")
            alertText = "Play " + name
        }
        
        if vibrate != .none {
            alertText += (audio != .none) ? " and " : ""
            alertText += String(describing: vibrate) + " vibration"
        }
        
        if alertText.isEmpty {
            alertText = "None"
        }
        
        return alertText
        
    }
    
    // MARK: - Notification Functions
    
    func setFinishedNotification(for task: Task, atTime time: Double) {
        
        let randomSeed = Int(arc4random_uniform(14) % 7)
        let notification = UNMutableNotificationContent()
        notification.title = getAlertTitle(forType: .complete, withSeed: randomSeed)
        notification.body = getAlertBody(forType: .complete, withSeed: randomSeed, for: task.name)
        notification.sound = UNNotificationSound(named: task.audioAlert.rawValue)
        
        let id = task.name + "Complete"
        let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: time, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: notification, trigger: notificationTrigger)
        
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        
    }
    
    func cancelFinishedNotification(for task: String) {
        
        let id = task + "Complete"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        
        //        UNUserNotificationCenter.current().getPendingNotificationRequests { (notificationRequests) in
        //            var identifiers: [String] = []
        //            for notification:UNNotificationRequest in notificationRequests {
        //                if notification.identifier == id {
        //                    identifiers.append(notification.identifier)
        //                }
        //            }
        //            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        //        }
        
    }
    
    func setMissedTimeNotification(for task: String, at time: TimeInterval, withRemaining remainingTime: String) {
        
        let randomSeed = Int(arc4random_uniform(14) % 7)
        let notification = UNMutableNotificationContent()
        notification.title = getAlertTitle(forType: .missed, withSeed: randomSeed)
        notification.body = getAlertBody(forType: .missed, withSeed: randomSeed, for: task)
        
        let id = task + "Missed"
        let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: time, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: notification, trigger: notificationTrigger)
        
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        
    }
    
    func cancelMissedTimeNotification(for task: String) {
        
        let id = task + "Missed"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        
    }

}

// MARK: - Alert Text Functions

extension CountdownTimer {
    
    func getAlertTitle(forType type: AlertType, withSeed seed: Int) -> String {
        let completionTitleArray = ["Task Complete", "Good Show", "Great Job", "Awesome", "Amazing", "Oh yeah", "Finished"]
        let missedTitleArray = ["Oh no", "Oops", "Uh oh", "Drats", "Too bad", "Whoopise", "Nooooooooooooo"]
        
        if type == .missed {
            return missedTitleArray[seed]
        } else {
            return completionTitleArray[seed]
        }
        
    }
    
    func getAlertBody(forType type: AlertType, withSeed seed: Int, for task: String) -> String {
        let completionBodyArray = ["Great job! You've completed \(task).",
            "You finished \(task) old chap.",
            "Take a break, you're done with \(task)",
            "\(task) has been vanquished. Rock on.",
            "Wow, you completed \(task)",
            "\(task) is no more.",
            "No more \(task) necessary for you today",
            "Who's a good little task finisher? You are! \(task) is done."]
        let missedBodyArray = ["You didn't complete \(task) and had \(remainingTime) remaining.",
            "\(task) - \(remainingTime) was left over but the day is over. Busy day today?",
            "\(task) - Looks like we didn't make our goal for today. Don't fret, there's always next time.",
            "\(task) - So close but so far. Try again next time.",
            "\(task) - And it looks like we're out of time, folks. Unfortunately there was still \(remainingTime) on the clock.",
            "\(task) - You ran out of time.",
            "\(task) - You tried but it just wasn't meant to be. Let's regroup and try harder next time."]
        if type == .missed {
            return missedBodyArray[seed]
        } else {
            return completionBodyArray[seed]
        }
        
    }
    
}


class Shared: NSObject {
    
    // These are the properties you can store in your singleton
//    var data: TaskData
//    var settings: AppData
    var timer: [CountdownTimer]
    
    // Here is how you would get to it without there being a global collision of variables.
    // , or in other words, it is a globally accessable parameter that is specific to the
    // class.
    static var instance = Shared()
    //static let data = TaskData()
    private override init() {
//        data = TaskData()
//        settings = AppData()
        timer = [CountdownTimer]()
    }
    
//    if willResetTimer {
//        resetTaskTimers()
//    }
//
//    saveData()

}

