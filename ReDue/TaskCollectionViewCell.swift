//
//  TaskCollectionViewCell.swift
//  RepeatingTasks
//
//  Created by Chase Peers on 10/13/17.
//  Copyright © 2017 Chase Peers. All rights reserved.
//

import UIKit
import KDCircularProgress
import SwiftyBeaver
import Chameleon

class TaskCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var playStopButton: UIButton!
    @IBOutlet weak var taskNameField: UILabel!
    @IBOutlet weak var taskTimeRemaining: UILabel!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var buttonBackground: UIImageView!
    @IBOutlet weak var circleProgressView: KDCircularProgress!
    @IBOutlet weak var nextRunLabel: UILabel!
    
    weak var mainVC = TaskViewController()
    var appData = AppData()
    var task = Task()
    @objc var timer = CountdownTimer()
    
    let log = SwiftyBeaver.self
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    /* When the start button is pressed the following occurs
       change the button image, set the start time, start progress,
       start the timer and enable the notification timer */
    @objc func taskStartStopButtonPressed(sender: UIButton) {

        let id = reuseIdentifier
        
        if !timer.isEnabled {
            
            task.isRunning = true
            timer.isEnabled = true
            timer.firedFromMainVC = true
            
            setImage(as: #imageLiteral(resourceName: "Pause"))
            //let stencil = #imageLiteral(resourceName: "Pause").withRenderingMode(.alwaysTemplate)
            //cell.playStopButton.setImage(#imageLiteral(resourceName: "Pause"), for: .normal)
            //cell.playStopButton.tintColor = UIColor.white
            
            let weightedTime = task.weightedTime
            let elapsedTime = task.completed.rounded()
            let remainingTime = weightedTime - elapsedTime
            
            if id == "taskCollectionCell_Circle" {
                
                let currentProgress = 1 - remainingTime/weightedTime
                let currentAngle = currentProgress * 360
                
                circleProgressView.animate(fromAngle: currentAngle, toAngle: 359.9, duration: remainingTime as TimeInterval, relativeDuration: true, completion: nil)
            }
            
            timer.startTime = Date().timeIntervalSince1970
            
            mainVC?.selectedCell = self
            
            timer.setFinishedNotification(for: task.name, atTime: remainingTime)
            timer.run = Timer.scheduledTimer(timeInterval: 1.0, target: self,
                                                  selector: #selector(timerRunning), userInfo: nil,
                                                  repeats: true)
            
            
        } else {
            
            setImage(as: #imageLiteral(resourceName: "Play"))
            //cell.playStopButton.setImage(#imageLiteral(resourceName: "Play"), for: .normal)
            
            if id == "taskCollectionCell_Circle" {
                timerStopped(for: task, ofType: .circular)
            } else {
                timerStopped(for: task, ofType: .line)
            }
            
            timer.cancelFinishedNotification(for: task.name)
            
            if mainVC!.willResetTasks {
                mainVC!.resetTaskTimers()
            }
            
        }
        
    }
    
    /* If not running: returns time - completed
       If running:     returns the same - difference between now and timer.startTime
       class local elapsedTime is used because of KVO */
    func getReminingTime(at currentTime: Double, for task: Task) -> Double {
        
        var elapsedTime = task.completed
        if timer.isEnabled && task.isRunning {
            elapsedTime += (currentTime - timer.startTime)
        }

        return task.weightedTime - elapsedTime.rounded()
    }
    
    /* Separate from formatTimer because although very similar it's still different
       enough that combining the two would hurt readability
       Only run when KVO determines timer.runningCompletedTime has changed */
    func updateTimer(for task: Task, ofType type: CellType? = nil) { //}-> (String, Double) {
        // Used for initialization and when the task timer is updated
        
        let currentTime: Double
        //let elapsedTime = task.completed
        //timer.elapsedTime = elapsedTime
        
        //    timer.currentTime = Date().timeIntervalSince1970
        //    currentTime = timer.currentTime
            currentTime = Date().timeIntervalSince1970
        
        let remainingTime = getReminingTime(at: currentTime, for: task)
        let remainingTimeAsString = timer.getRemainingTimeAsString(withRemaining: remainingTime)

        if remainingTime > 0 {
            taskTimeRemaining.text = remainingTimeAsString
        } else {
            taskTimeRemaining.text = "Complete"
        }

        if type == .circular {
            let currentProgress = 1 - Float(remainingTime)/Float(task.weightedTime)
            circleProgressView.progress = Double(currentProgress)
        }
        
    }
        
    /* Sets the timeLabel and progress to the correct values
       after incrementing timer.elapsedTime
       Returns remaining time as both a string and double */
    func formatTimer(for task: Task, ofType type: CellType? = nil) -> (String, Double) {
        // Used for initialization and when the task timer is updated
        
        timer.currentTime = Date().timeIntervalSince1970
        print(task.completed)
        timer.elapsedTime = task.completed
        
        if timer.isEnabled && task.isRunning {
            timer.elapsedTime += (timer.currentTime - timer.startTime)
        }
        
        let remainingTime = task.weightedTime - timer.elapsedTime.rounded()
        var remainingTimeAsString = timer.getRemainingTimeAsString(withRemaining: remainingTime)
        
        if remainingTime <= 0 {
            remainingTimeAsString = "Complete"
        }
        
        let currentProgress = 1 - Float(remainingTime)/Float(task.weightedTime)
        
        if type == .line {
            //TaskViewController.calculateProgress()
            //cell!.progressView.setProgress(currentProgress, animated: true)
            
        } else if type == .circular {
            circleProgressView.progress = Double(currentProgress)
        }
        
        print("Current progress is \(currentProgress)")
        
        taskTimeRemaining.text = remainingTimeAsString
        
        return (remainingTimeAsString, remainingTime)
        
    }
    
    /*  */
    @objc func timerRunning() {
        
        let taskName = taskNameField.text!
        let id = reuseIdentifier
        
        let (_, timeRemaining) = formatTimer(for: task)
        print("Running in table cell")
        print("Time remaining is \(timeRemaining)")
        log.debug("Time remaining is \(timeRemaining)")
        
        if id == "taskCollectionCell_Line" {
            calculateProgress(ofType: .line)
        }
        
        if timeRemaining <= 0 {
            
            if id == "taskCollectionCell_Line" {
                timerStopped(for: task, ofType: .line)
            } else {
                timerStopped(for: task, ofType: .circular)
            }
            
            taskTimeRemaining.text = "Complete"
            
            setImage(as: #imageLiteral(resourceName: "Play"))
            //cell.playStopButton.setImage(#imageLiteral(resourceName: "Play"), for: .normal)
            playStopButton.isEnabled = false
            
            timer.cancelMissedTimeNotification(for: taskName)
            
        }
        
    }
    
    func timerStopped(for task: Task, ofType type: CellType) {
        
        timer.run.invalidate()
        timer.isEnabled = false
        timer.firedFromMainVC = false
        task.isRunning = false
        
        timer.endTime = Date().timeIntervalSince1970
        
        var elapsedTime = (timer.endTime - timer.startTime).rounded()
        
        if elapsedTime > task.weightedTime {
            elapsedTime = task.weightedTime
        }
        
        task.completed += elapsedTime
        
        if type == .circular {
            circleProgressView.pauseAnimation()
        }
        
        if task.completed >= task.weightedTime {
            
            if task.vibrateAlert != .none {
                timer.vibrate(for: task)
            }
            
            if task.audioAlert != .none {
                timer.playAudio(for: task)
            }
            
        }
        
        if let date = task.getAccessDate(lengthFromEnd: 0) {
            
            task.completedTimeHistory[date]! += elapsedTime
            
            let unfinishedTime = task.time - elapsedTime
            
            if unfinishedTime >= 0 {
                task.missedTimeHistory[date]! = unfinishedTime
            } else {
                task.missedTimeHistory[date]! = 0
            }
            
        }

        let resetTime = mainVC!.check.timeToReset(at: mainVC!.nextResetTime)
        
        let (remainingTimeString, _) = formatTimer(for: task)
        timer.setMissedTimeNotification(for: task.name, at: resetTime, withRemaining: remainingTimeString)
        
        mainVC!.saveData()

    }
    
    func setImage(as image: UIImage) {
        let stencil = image.withRenderingMode(.alwaysTemplate)
        playStopButton.setImage(stencil, for: .normal)
        playStopButton.tintColor = FlatWhite()
        
        //buttonBackground.alpha = 0.0
    }
    
    func calculateProgress(ofType type: CellType) {
        
        // Why do I have to do this here???
        // Doesn't work from other classes when using .xib
        let weightedTime = task.weightedTime
        var elapsedTime = task.completed
        if timer.isEnabled {
            elapsedTime += (timer.currentTime - timer.startTime)
        }
        let remainingTime = weightedTime - elapsedTime.rounded()
        
        if type == .line {
            let currentProgress = 1 - Float(remainingTime)/Float(weightedTime)
            progressView.setProgress(currentProgress, animated: true)
        } else {
            let currentProgress = 1 - remainingTime/weightedTime
            circleProgressView.progress = currentProgress
        }
        
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        print("View is tope view? \(self.isTopViewInWindow())")

        if !isTopViewInWindow() {
            return
        }

        guard let newValue = change?[.newKey] as? Double else { return }
        guard let oldValue = change?[.oldKey] as? Double else { return }

        var type: CellType = .line
        
        if let id = reuseIdentifier {
            if id == "taskCollectionCell_Circle" {
                type = .circular
            } else {
                type = .line
            }
        }
        
        if newValue != oldValue {
            updateTimer(for: task, ofType: type)
        }
        
    }

    func initializeObserver() {
        self.addObserver(self, forKeyPath: #keyPath(timer.runningCompletedTime), options: [.new, .old], context: nil)
    }
    
    func removeObserver() {
        self.removeObserver(self, forKeyPath: #keyPath(timer.runningCompletedTime))
    }
    
//    deinit {
//        self.removeObserver(self, forKeyPath: #keyPath(timer.runningCompletedTime))
//    }

}
