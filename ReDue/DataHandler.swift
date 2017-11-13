//
//  DataHandler.swift
//  RepeatingTasks
//
//  Created by Chase Peers on 10/27/17.
//  Copyright © 2017 Chase Peers. All rights reserved.
//

import Foundation

class DataHandler {
    
    func save(_ tasks: [Task]) {
        
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
    
}
