//
//  AlertSettingsViewController.swift
//  ReDue
//
//  Created by Chase Peers on 11/28/17.
//  Copyright © 2017 Chase Peers. All rights reserved.
//

import UIKit
import Chameleon

class AudioAlertSettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var alertTable: UITableView!
    
    var previousCellIndex: IndexPath?
    var selectedColor: UIColor?
    var selectedTheme: String?
    var selectedEnum: ThemeColors?

    var task: Task?
    var appData = AppData()
    
    var selectedAudio: AudioAlert = .none
    
    var colors = Colors(main: HexColor("247BA0")!, bg: FlatWhite(), task1: HexColor("70C1B3")!, task2: HexColor("B2DBBF")!, progress: HexColor("FF1654")!)

    //MARK: - View Functions
    
    override func viewDidLoad() {
        
        self.title = "Audio Alert"
        
        setTheme()
        alertTable.delegate = self
        alertTable.dataSource = self
        alertTable.estimatedRowHeight = 45
        alertTable.rowHeight = UITableViewAutomaticDimension
        alertTable.allowsMultipleSelection = true
        alertTable.tableFooterView = UIView(frame: .zero)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = false
        alertTable.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = true
    }
    
    //MARK: - Button Functions
    
    func returnToMainMenu() {
        
        let vc = navigationController?.viewControllers[0] as! MoreSettingsViewController
        vc.selectedAudioAlert = selectedAudio
        
        if let _ = task {
            vc.task?.audioAlert = selectedAudio
        }
        
        navigationController?.popViewController(animated: true)
        
    }
    
    //MARK: - Setup Functions
    
    private func setTheme() {

        colors = Colors.init(main: appData.mainColor!, bg: appData.bgColor!, task1: appData.taskColor1!, task2: appData.taskColor2!, progress: appData.progressColor!)
        
        let darkerThemeColor = colors.darkMain
        
        view.backgroundColor = darkerThemeColor
        //view.tintColor = darkerThemeColor
        alertTable.backgroundColor = darkerThemeColor
        alertTable.separatorColor = .clear
        
        if appData.darknessCheck(for: darkerThemeColor) {
            setStatusBarStyle(.lightContent)
        } else {
            setStatusBarStyle(.default)
        }
        
        alertTable.reloadData()
    }
    
    //MARK: - Table View Functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AudioAlert.allValues.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let value: String
        let alertFullText = AudioAlert.allValues[indexPath.row].rawValue
        if let periodIndex = alertFullText.index(of: ".") {
            value = alertFullText.prefix(upTo: periodIndex).replacingOccurrences(of: "_", with: " ")
        } else {
            value = "none"
        }
        var isChecked = false
        
        if selectedAudio != .none && alertFullText == selectedAudio.rawValue {
                isChecked = true
        }
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "audioAlertCell") as? AudioAlertSettingsTableCell {
            
            let darkerThemeColor = colors.darkMain
            cell.backgroundColor = darkerThemeColor
            
            if appData.darknessCheck(for: darkerThemeColor) {
                cell.headerLabel.textColor = .white
                cell.settingLabel.textColor = .white
            } else {
                cell.headerLabel.textColor = .black
                cell.settingLabel.textColor = .black
            }
            
            cell.headerLabel.text = ""
            cell.settingLabel.text = value
            
            if isChecked {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

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
        
        selectedAudio = AudioAlert.allValues[indexPath.row]
        task?.audioAlert = selectedAudio
        
        returnToMainMenu()
        
    }
    
}

// MARK: - Audio Alert Table Cell

class AudioAlertSettingsTableCell: UITableViewCell {
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var settingLabel: UILabel!

}
