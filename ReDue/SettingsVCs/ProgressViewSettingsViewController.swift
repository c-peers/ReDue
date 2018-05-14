//
//  ProgressViewSettingsViewController.swift
//  RepeatingTasks
//
//  Created by Chase Peers on 9/1/17.
//  Copyright © 2017 Chase Peers. All rights reserved.
//

import UIKit
import Chameleon

class ProgressViewSettingsViewController: UITableViewController {
    
    var appData = AppData()
    
    var previousCellIndex: IndexPath?
    
    var progressStyle = ["Flat", "Circular"]
    
    var colors = Colors(main: HexColor("247BA0")!, bg: FlatWhite(), task1: HexColor("70C1B3")!, task2: HexColor("B2DBBF")!, progress: HexColor("FF1654")!)
    
// MARK: - UIViewController
    
    override func viewDidLoad() {
        
        self.title = "Progress View"
        
        //tableView.sectionIndexColor = UIColor.black
        
        colors = Colors.init(main: appData.mainColor!, bg: appData.bgColor!, task1: appData.taskColor1!, task2: appData.taskColor2!, progress: appData.progressColor!)
        
        darkness(check: colors.main)
        
        let darkerThemeColor = colors.bg
        tableView.backgroundColor = darkerThemeColor
        tableView.separatorColor = colors.bg.darken(byPercentage: Colors.colorLevel4)
        tableView.tableFooterView = UIView()
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //let cell = tableView.dequeueReusableCell(withIdentifier: "ProgressViewStyleCell", for: indexPath)
        
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
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if progressStyle[indexPath.row] == "Circular" {
            appData.usesCircularProgress = true
            appDelegate.appData.usesCircularProgress = true
        } else {
            appData.usesCircularProgress = false
            appDelegate.appData.usesCircularProgress = false
        }
        
        let data = DataHandler()
        data.saveAppSettings(appData)

    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = UIColor.clear
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return progressStyle.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProgressViewStyleCell", for: indexPath)
        
        let text = progressStyle[indexPath.row]
        cell.textLabel?.text = text
        
        if appData.usesCircularProgress && text == "Circular" {
            cell.accessoryType = .checkmark
            previousCellIndex = indexPath
        } else if !appData.usesCircularProgress && text == "Flat" {
            cell.accessoryType = .checkmark
            previousCellIndex = indexPath
        }

        let darkerThemeColor = colors.bg
        cell.backgroundColor = darkerThemeColor
        if appData.darknessCheck(for: darkerThemeColor) {
            cell.textLabel?.textColor = .white
        } else {
            cell.textLabel?.textColor = .black
        }
        
        return cell
    }
    
}
