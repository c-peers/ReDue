    //
//  TaskChecker.swift
//  RepeatingTasks
//
//  Created by Chase Peers on 10/27/17.
//  Copyright © 2017 Chase Peers. All rights reserved.
//

import Foundation
import SwiftyBeaver

class Check {
    
    var appData = AppData()
    let log = SwiftyBeaver.self
    
    var currentWeek: Int = {
        let today = Date()
        var calendar = Calendar.current
        let timeZoneID = TimeZone.current.identifier
        let timeZone = TimeZone.abbreviationDictionary.first { $0.value == timeZoneID }
        calendar.timeZone = TimeZone(abbreviation: timeZone!.key)!
        let currentWeekOfYear = calendar.component(.weekOfYear, from: today)
        
        print("Current week of year is #\(currentWeekOfYear)")
        
        return currentWeekOfYear
    }()
    
    func ifTaskWillRunToday(_ task: Task) {

        let date = offsetDate(appData.taskCurrentTime, by: appData.resetOffset)
        let isThisWeek = taskWeek(for: task, at: date)
        let isThisDayofWeek = taskDays(for: task, at: date)
        
        task.isToday = (isThisWeek && isThisDayofWeek) ? true : false
    
        if task.isToday {
            log.info("\(task.name) will run today")
        } else {
            log.info("\(task.name) will not run today")
        }
        
    }
    
    func taskDays(for task: Task, at date: Date) -> Bool {
        
        let dayOfWeekString = dayFor(date)
        print("Today is \(dayOfWeekString)")
        
        return task.days[dayOfWeekString]!
        
    }
    
    func dayFor(_ date: Date) -> String {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        
        return dateFormatter.string(from: date)
    }
    
    func taskWeek(for task: Task, at date: Date) -> Bool {
        //let weekOfYear = calendar.component(.weekOfYear, from: date)
        log.debug("Current week number is \(currentWeek) and the task run week is \(task.runWeek)")
        return task.runWeek == currentWeek
    }
    
    func runWeek(for task: Task, at date: Date) {
        
        print("Task run week is \(task.runWeek) before check")
        log.debug("Task run week is \(task.runWeek) before check")
        
        var calendar = Calendar.current
        let timeZoneID = TimeZone.current.identifier
        let timeZone = TimeZone.abbreviationDictionary.first { $0.value == timeZoneID }
        calendar.timeZone = TimeZone(abbreviation: timeZone!.key)!
        let weekOfYear = calendar.component(.weekOfYear, from: date)
        
        let frequency = task.frequency
        let lastRunWeek = task.runWeek
        let nextRunWeek = lastRunWeek + Int(frequency)
        
        if weekOfYear == nextRunWeek {
            task.runWeek = nextRunWeek
        }
        
        print("and \(task.runWeek) after check")
        log.debug("and \(task.runWeek) after check")

    }

    func changeOfWeek(between start: Date, and end: Date) -> Bool {
        
        var calendar = Calendar.current
        let timeZoneID = TimeZone.current.identifier
        let timeZone = TimeZone.abbreviationDictionary.first { $0.value == timeZoneID }
        calendar.timeZone = TimeZone(abbreviation: timeZone!.key)!
        let startWeek = calendar.component(.weekOfYear, from: start)
        let endWeek = calendar.component(.weekOfYear, from: end)

        print("Previous run was on \(startWeek) week and current run is on \(endWeek) week")
        log.debug("Previous run was on \(startWeek) week and current run is on \(endWeek) week")

        return startWeek != endWeek
        
    }
    
    func daysBetweenTwoDates(start: Date, end: Date) -> Int {
        
        // Get both the time zone offset and app reset offset in seconds
        let timeZoneOffset = TimeZone.current.secondsFromGMT(for: start)
        let appOffset = (offsetAsInt(for: appData.resetOffset) * 3600)
        let offset = timeZoneOffset + appOffset
        
        let calendar = Calendar.current
        guard let offsetStart = calendar.date(byAdding: .second, value: offset, to: start) else {
            return 0
        }
        guard let offsetEnd = calendar.date(byAdding: .second, value: offset, to: end) else {
            return 0
        }

        guard let start = calendar.ordinality(of: .day, in: .era, for: offsetStart) else {
            return 0
        }
        guard let end = calendar.ordinality(of: .day, in: .era, for: offsetEnd) else {
            return 0
        }

        print("There are \(end - start) days between last and current run")
        log.debug("There are \(end - start) days between last and current run")

        return end - start
    }
    
    func timeToReset(at resetTime: Date) -> TimeInterval {
        let calendar = Calendar.current
        let differenceComponents = calendar.dateComponents([.hour, .minute, .second], from: Date(), to: resetTime)
        let timeDifference = TimeInterval((differenceComponents.hour! * 3600) + (differenceComponents.minute! * 60) + differenceComponents.second!)
        return timeDifference
    }
    
    func resetTimePassed(between then: Date, and now: Date, with reset: Date) -> Bool {
        
        if reset > then && reset < now {
            return true
        } else {
            return false
        }
        
    }
    
    func missedDays(in task: Task, between start: Date, and end: Date) {
        
        var date = task.getHistory(at: start)
        
        let daysBetween = daysBetweenTwoDates(start: start, end: end)
        
        if daysBetween < 1 {
            return
        }
        
        // Run through all the days in between
        // the previous run and today
        for day in 0..<daysBetween {
            
            // day 0 is the last time the app was ran
            // so we need to use the correct time in the dictionary
            if day == 0, let previousDate = date { //}!= nil {
                let taskTime = task.taskTimeHistory[previousDate]
                let completedTime = task.completedTimeHistory[previousDate]
                let unfinishedTime = taskTime! - completedTime!
                
                if unfinishedTime >= 0 {
                    task.missedTimeHistory[previousDate] = unfinishedTime
                } else {
                    task.missedTimeHistory[previousDate] = 0
                }
                
            } else {
                
                date = Calendar.current.date(byAdding: .day, value: day, to: start)
                
                let dateExistsInDict = task.isHistoryPresent(for: date!)
                
                if taskDays(for: task, at: date!) && dateExistsInDict == true {
                    task.addHistory(date: date!)
                }
                
                let taskTime = task.taskTimeHistory[date!]
                let completedTime = task.completedTimeHistory[date!]
                
                if (taskTime != nil) && (completedTime != nil) {
                    task.missedTimeHistory[date!] = taskTime! - completedTime!
                }
            }
            
        }
        
    }
    
    /*
     Checks if last time accessed is the same day or not.
     If it is the same day then do nothing.
     Otherwise create history dicionary with today's date.
     */
    
    func access(for task: Task, upTo currentDay: Date) -> Bool {
        
        let offsetString = appData.resetOffset
        
        if let previousAccess = task.previousDates.last { //taskData.taskAccess?.last {
            
            // Both give day of week as an int. Check if values match
            let previousAccessDay = getDay(for: previousAccess, with: offsetString)
            let currentAccessDay = getDay(for: currentDay, with: offsetString)
            
            if previousAccessDay != currentAccessDay {
                task.addHistory(date: currentDay)
                return false
            }
            
            return true
            
        } else {
            task.addHistory(date: currentDay)
            return false
        }
        
    }
    
    func getDay(for date: Date, with offset: String) -> Int {
        
        var resetOffset = DateComponents()
        resetOffset.hour = -offsetAsInt(for: offset)
        
        let date = Calendar.current.date(byAdding: resetOffset, to: date)
        let offsetDay = Calendar.current.component(.weekday, from: date!)
        
        return offsetDay
        
    }
    
    func offsetDates() {
        let offsetString = appData.resetOffset
        let lastUsed = appData.taskLastTime
        appData.taskLastTime = offsetDate(lastUsed, by: offsetString)
    }
    
    func offsetDate(_ date: Date, by offset: String) -> Date {
        
        let offsetInt = offsetAsInt(for: offset)
        let offsetDate = Calendar.current.date(byAdding: .hour, value: -offsetInt, to: date)
        
        return offsetDate!
        
    }
    
    func offsetAsInt(for offset: String) -> Int {
        
        let offsetTime = offset.components(separatedBy: ":")[0]
        var offset = Int(offsetTime)
        if offset == 12 {
            offset = 0
        }
        return offset!
        
    }
    
    func secondsToHoursMinutesSeconds(from seconds: Int) -> (Int, Int, Int) {
        
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) & 60)
        
    }
    
}
