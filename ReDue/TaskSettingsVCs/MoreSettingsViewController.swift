//
//  AppSettingsViewController.swift
//  RepeatingTasks
//
//  Created by Chase Peers on 8/28/17.
//  Copyright © 2017 Chase Peers. All rights reserved.
//

import Foundation
import UIKit
import Chameleon
import SwiftyBeaver

class MoreSettingsViewController: UITableViewController {
    
    //MARK: - Outlets
    
    @IBOutlet weak var selectedAudioLabel: UILabel!
    @IBOutlet weak var selectedVibrateLabel: UILabel!
    
    //MARK: - Properties
    
    var selectedAudioAlert: AudioAlert = .none
    var selectedVibrateAlert: VibrateAlert = .none
    
    let log = SwiftyBeaver.self
    
    var appData = AppData()
    var task: Task?
    
    var colors = Colors(main: HexColor("247BA0")!, bg: FlatWhite(), task1: HexColor("70C1B3")!, task2: HexColor("B2DBBF")!, progress: HexColor("FF1654")!)
    
    //MARK: - View and Basic Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = ""
        
        if let task = task {
            selectedAudioAlert = task.audioAlert
            selectedVibrateAlert = task.vibrateAlert
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setTextColor()
        setTheme()
        let navVC = navigationController
        let parentVC = navVC?.parent as! MoreSettingsParentViewController
        parentVC.doneButton.isHidden = false
        parentVC.bottomConstraint.constant = 70
        parentVC.view.layoutIfNeeded()
        
        setSettings()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationItem.title = ""
        let navVC = navigationController
        let parentVC = navVC?.parent as! MoreSettingsParentViewController
        parentVC.doneButton.isHidden = true
        parentVC.bottomConstraint.constant = 10
        parentVC.reloadInputViews()
        parentVC.view.layoutIfNeeded()
    }
    
    func setSettings() {
        selectedAudioLabel.text = ""
        selectedVibrateLabel.text = ""
        
        if selectedAudioAlert != .none {
            let value = getAlertText(from: selectedAudioAlert.rawValue)
            selectedAudioLabel.text = value
        }
        
        if selectedVibrateAlert != .none {
            let value = getAlertText(from: selectedVibrateAlert.rawValue)
            selectedVibrateLabel.text = value
        }
    }
    
    func getAlertText(from text: String) -> String {

        if let periodIndex = text.index(of: ".") {
            let value = text.prefix(upTo: periodIndex).replacingOccurrences(of: "_", with: " ")
            return value
        } else if text != "none" {
            return text
        } else {
            return ""
        }
        
    }
    
    //MARK: - Table Functions
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                performSegue(withIdentifier: "audioAlertSettingsSegue", sender: self)
            } else if indexPath.row == 1 {
                performSegue(withIdentifier: "vibrateAlertSettingsSegue", sender: self)
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if appData.isNightMode {
            cell.contentView.backgroundColor = FlatBlack()
            cell.accessoryView?.backgroundColor = FlatBlack()
            cell.accessoryView?.tintColor = FlatGray()
        } else {
            let darkerThemeColor = colors.darkMain //appData.appColor.darken(byPercentage: 0.25)
            cell.backgroundColor = darkerThemeColor
            //cell.textLabel?.backgroundColor = darkerThemeColor
            //cell.detailTextLabel?.backgroundColor = darkerThemeColor
            //cell.accessoryView?.tintColor = UIColor.gray
            
            if appData.darknessCheck(for: darkerThemeColor) {
                cell.textLabel?.textColor = .white
                cell.detailTextLabel?.textColor = .white
            } else {
                cell.textLabel?.textColor = .black
                cell.detailTextLabel?.textColor = .black
            }
        }
        
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let themeView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 40))
        
        let headerColor = colors.darkMain //colors.bg.darken(byPercentage: 0.3) //appData.appColor.darken(byPercentage: 0.2)
        themeView.backgroundColor = headerColor
        
        let label = UILabel(frame: CGRect(x: 10, y: 5, width: view.frame.size.width, height: 25))
        if appData.darknessCheck(for: headerColor) {
            label.textColor = .white
        } else {
            label.textColor = .black
        }
        themeView.addSubview(label)
        
        return themeView
    }

    //MARK: - Theme/Color Functions

    func setTextColor() {
        
        let navigationBar = navigationController?.navigationBar
        let toolbar = navigationController?.toolbar
        
        let bgColor = navigationBar?.barTintColor
        
        if appData.darknessCheck(for: bgColor) {
            navigationBar?.tintColor = .white
            navigationBar?.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
            toolbar?.tintColor = .white
            setStatusBarStyle(.lightContent)
        } else {
            navigationBar?.tintColor = .black
            navigationBar?.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.black]
            toolbar?.tintColor = .black
            setStatusBarStyle(.default)
        }
        
    }
    
    private func setTheme() {
        
        colors = Colors.init(main: appData.mainColor!, bg: appData.bgColor!, task1: appData.taskColor1!, task2: appData.taskColor2!, progress: appData.progressColor!)
        
        view.backgroundColor = colors.darkMain
        
        navigationController?.navigationBar.isHidden = true
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = colors.darkMain
        navigationController?.toolbar.barTintColor = colors.darkMain
        
        let darkerThemeColor = colors.darkMain //appData.appColor.darken(byPercentage: 0.25)
        tableView.backgroundColor = darkerThemeColor
        tableView.tableFooterView = UIView(frame: .zero)
        //tableView.separatorColor =  colors.bg.darken(byPercentage: 0.5) //appData.appColor.darken(byPercentage: 0.6)
        
        if appData.darknessCheck(for: darkerThemeColor) {
            setStatusBarStyle(.lightContent)
            //setColorLabel.textColor = .white
        } else {
            setStatusBarStyle(.default)
            //setColorLabel.textColor = .black
        }

        tableView.reloadData()
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "audioAlertSettingsSegue" {
            let audioAlertSettingsVC = segue.destination as! AudioAlertSettingsViewController
            audioAlertSettingsVC.appData = appData
            if selectedAudioAlert != .none {
                audioAlertSettingsVC.selectedAudio = selectedAudioAlert
            } else if let task = task {
                audioAlertSettingsVC.selectedAudio = task.audioAlert
            }
        } else if segue.identifier == "vibrateAlertSettingsSegue" {
            let  vibrateAlertSettingsVC = segue.destination as! VibrateAlertSettingsViewController
            vibrateAlertSettingsVC.appData = appData
            if selectedVibrateAlert != .none {
                vibrateAlertSettingsVC.selectedVibration = selectedVibrateAlert
            } else if let task = task {
                vibrateAlertSettingsVC.selectedVibration = task.vibrateAlert
            }
        }
        
    }
    
}
