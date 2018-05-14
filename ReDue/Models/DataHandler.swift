//
//  DataHandler.swift
//  RepeatingTasks
//
//  Created by Chase Peers on 10/27/17.
//  Copyright © 2017 Chase Peers. All rights reserved.
//

import Foundation

/* Handles saving and loading of taks and app-wide settings. */
class DataHandler {
    
    func saveTasks(_ tasks: [Task]) {
        
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(tasks, toFile: Task.taskURL.path)
        
        if isSuccessfulSave {
            print("Tasks saved")
        } else {
            print("Couldn't save tasks")
        }
        
    }
    
    func loadTasks() -> [Task]? {
        print("Tasks loaded")
        return NSKeyedUnarchiver.unarchiveObject(withFile: Task.taskURL.path) as? [Task]
    }
    
    func saveAppSettings(_ settings: AppData) {
        
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(settings, toFile: AppData.appURL.path)
        
        if isSuccessfulSave {
            print("Settings saved")
        } else {
            print("Couldn't save settings")
        }
        
    }
    
    func loadAppSettings() -> AppData? {
        print("App settings loaded")
        return NSKeyedUnarchiver.unarchiveObject(withFile: AppData.appURL.path) as? AppData
    }

    
}
