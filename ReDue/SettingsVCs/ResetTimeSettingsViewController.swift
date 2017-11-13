//
//  ResetTimeSettingsViewController.swift
//  RepeatingTasks
//
//  Created by Chase Peers on 8/31/17.
//  Copyright © 2017 Chase Peers. All rights reserved.
//

import UIKit
import Chameleon

class ResetTimeSettingsViewController: UITableViewController {

    var appData = AppData()
    
    var previousCellIndex: IndexPath?
    
    var resetTimes = ["12:00 AM", "1:00 AM", "2:00 AM", "3:00 AM", "4:00 AM"]
    var resetTimes24H = ["0:00", "1:00", "2:00", "3:00", "4:00"]
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        
        self.title = "Reset Time"
        
        let darkerThemeColor = appData.appColor.darken(byPercentage: 0.25)
        tableView.backgroundColor = darkerThemeColor
        tableView.separatorColor = appData.appColor.darken(byPercentage: 0.6)

        //tableView.sectionIndexColor = UIColor.black
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "ResetTimeCell", for: indexPath)
//        
//        if let cell = tableView.cellForRow(at: indexPath as IndexPath) {
//            
//            cell.selectionStyle = .none
//            
//            if cell.accessoryType == .checkmark{
//                cell.accessoryType = .none
//            }
//            else{
//                cell.accessoryType = .checkmark
//            }
//        }
//        cell.textLabel?.text = resetTimes[indexPath.row]
        
        if let cell = tableView.cellForRow(at: indexPath as IndexPath) {
            
            if let index = previousCellIndex {
                let previousCell = tableView.cellForRow(at: index)
                previousCell?.accessoryType = .none
            }
            if cell.accessoryType == .checkmark{
                cell.accessoryType = .none
            }
            else{
                cell.accessoryType = .checkmark
                previousCellIndex = indexPath
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        appData.resetOffset = resetTimes[indexPath.row]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        appDelegate.appData.resetOffset = resetTimes[indexPath.row]
        
        print(appDelegate.appData.resetOffset)
        appDelegate.appData.save()
        

    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resetTimes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResetTimeCell", for: indexPath)
        
        let text = resetTimes[indexPath.row]
        cell.textLabel?.text = text
        
        let offset = appData.resetOffset

        if offset == text {
            cell.accessoryType = .checkmark
            previousCellIndex = indexPath
        }
        let darkerThemeColor = appData.appColor.darken(byPercentage: 0.25)
        cell.backgroundColor = darkerThemeColor
        if appData.darknessCheck(for: darkerThemeColor) {
            cell.textLabel?.textColor = .white
        } else {
            cell.textLabel?.textColor = .black
        }
        
        return cell
    }

}
