//
//  AlertSettingsViewController.swift
//  ReDue
//
//  Created by Chase Peers on 11/28/17.
//  Copyright © 2017 Chase Peers. All rights reserved.
//

import UIKit
import Chameleon

class AlertSettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var alertTable: UITableView!
    @IBOutlet weak var completeButton: UIButton!
    
    var previouslySelectedHeaderIndex: Int?
    var selectedHeaderIndex: Int?
    var selectedItemIndex: Int?
    
    var task: Task?
    var appData = AppData()
    
    var selectedAudio: AudioAlert?
    var selectedVibration: VibrateAlert?
    
    var presentingVC = UIViewController()
    
    var cells: DynamicTableCells!
    
    override func viewDidLoad() {
        cells = DynamicTableCells()
        tableSetup()
        setTheme()
        alertTable.delegate = self
        alertTable.dataSource = self
        alertTable.estimatedRowHeight = 45
        alertTable.rowHeight = UITableViewAutomaticDimension
        alertTable.allowsMultipleSelection = true
        alertTable.tableFooterView = UIView(frame: .zero)
        
        completeButton.layer.borderColor = appData.appColor.cgColor
        completeButton.layer.borderWidth = 2
        completeButton.layer.cornerRadius = 10.0
        completeButton.setTitleColor(appData.appColor, for: .normal)

        completeButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        
    }
    
    @objc func buttonTapped() {
        
        let timer = CountdownTimer()
        var text = String()
        
        if let _ = task {
            let vc = presentingVC as! TaskSettingsViewController
            if let audioAlert = selectedAudio, let vibrateAlert = selectedVibration {
                vc.task.audioAlert = audioAlert
                vc.audio = audioAlert
                vc.task.vibrateAlert = vibrateAlert
                vc.vibrate = vibrateAlert
                
                text = timer.setAlertText(for: audioAlert, and: vibrateAlert)
                //text = String(describing: audioAlert)
            }
//            if let vibrateAlert = selectedVibration {
//                vc.task.vibrateAlert = vibrateAlert
//                vc.vibrate = vibrateAlert
//                if text.isEmpty {
//                    text = String(describing: vibrateAlert)
//                } else {
//                    text += " and " + String(describing: vibrateAlert)
//                }
//            }
            vc.alertTextField.text = text
            vc.didValuesChange(added: text, to: vc.alertTextField)
            vc.resignResponder()
        } else {
            let vc = presentingVC as! NewTasksViewController
            if let audioAlert = selectedAudio, let vibrateAlert = selectedVibration {
                vc.audioAlert = audioAlert
                vc.vibrateAlert = vibrateAlert

                text = timer.setAlertText(for: audioAlert, and: vibrateAlert)
                //text = String(describing: audioAlert)
            }
//            if let vibrateAlert = selectedVibration {
//                if text.isEmpty {
//                    text = String(describing: vibrateAlert)
//                } else {
//                    text += " and " + String(describing: vibrateAlert)
//                }
//            }
            vc.alertTextField.text = text
            vc.resignResponder()
        }
        
        dismiss(animated: true, completion: nil)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        alertTable.reloadData()
    }
    
    func tableSetup() {
        
        let audioArray = AudioAlert.allValues
        let vibrateArray = VibrateAlert.allValues
        
        cells.append(DynamicTableCells.HeaderItem(value: "Play a sound"))
        for audio in audioArray {
            guard let periodIndex = audio.rawValue.index(of: ".") else { break }
            let name = audio.rawValue.prefix(upTo: periodIndex).replacingOccurrences(of: "_", with: " ")
            cells.append(DynamicTableCells.Item(value: name, type: .audio))
        }
        
        cells.append(DynamicTableCells.HeaderItem(value: "Vibrate"))
        for vibration in vibrateArray {
            cells.append(DynamicTableCells.Item(value: vibration.rawValue, type: .vibration))
        }
//        cells.append(DynamicTableCells.HeaderItem(value: "Title 3"))
//        cells.append(DynamicTableCells.HeaderItem(value: "Title 4"))
        
    }
    
    private func setTheme() {

        let darkerThemeColor = appData.appColor.darken(byPercentage: 0.25)
        
        view.backgroundColor = darkerThemeColor
        //view.tintColor = darkerThemeColor
        alertTable.backgroundColor = darkerThemeColor
        alertTable.separatorColor = .clear //appData.appColor.darken(byPercentage: 0.6)
        
        if appData.darknessCheck(for: darkerThemeColor) {
            setStatusBarStyle(.lightContent)
        } else {
            setStatusBarStyle(.default)
        }
        
        alertTable.reloadData()
    }

    //MARK: - Table View Functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = cells.items[indexPath.row]
        let value = item.value

        if let _ = task {
            if item.type == .audio && task!.audioAlert.rawValue.contains(value.replacingOccurrences(of: " ", with: "_")) {
                item.isChecked = true
            } else if item.type == .vibration && task!.vibrateAlert.rawValue.contains(value) {
                item.isChecked = true
            }
        }
        let isChecked = item.isChecked
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "alertCell") as? AlertSettingsTableCell {
            
            let darkerThemeColor = appData.appColor.darken(byPercentage: 0.25)
            cell.backgroundColor = darkerThemeColor
            
            if appData.darknessCheck(for: darkerThemeColor) {
                cell.headerLabel.textColor = .white
                cell.settingLabel.textColor = .white
            } else {
                cell.headerLabel.textColor = .black
                cell.settingLabel.textColor = .black
            }

            if item as? DynamicTableCells.HeaderItem != nil {
                cell.headerLabel.text = value
                cell.settingLabel.text = ""
                cell.accessoryType = .none
            } else {
                
//                let (width, height) = (CGFloat(100), CGFloat(20))
//                let settingsText = UILabel(frame: CGRect(x: (/*(cell.frame.height / 2) - CGFloat(height / 2)*/ 22), y: (cell.frame.width - 20 - width), width: width, height: height))
//                settingsText.text = value
//                settingsText.translatesAutoresizingMaskIntoConstraints = false
//                cell.contentView.addSubview(settingsText)
                
//                let leadingSpaceConstraint: NSLayoutConstraint = NSLayoutConstraint(item: settingsText, attribute: .trailing, relatedBy: .equal, toItem: cell, attribute: .trailing, multiplier: 1, constant: 20);
//
//                let centerConstraint: NSLayoutConstraint = NSLayoutConstraint(item: settingsText, attribute: .centerY, relatedBy: .equal, toItem: cell, attribute: .centerY, multiplier: 1, constant: 0); //Constant is the spacing between
//                cell.contentView.addConstraint(leadingSpaceConstraint)
//                cell.contentView.addConstraint(centerConstraint)

                cell.headerLabel.text = ""
                cell.settingLabel.text = value
                
                if isChecked {
                    cell.accessoryType = .checkmark
                } else {
                    cell.accessoryType = .none
                }
            }
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = cells.items[indexPath.row]
        
        if item is DynamicTableCells.HeaderItem {
            return 60
        } else if (item.isHidden) {
            return 0
        } else {
            return UITableViewAutomaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = cells.items[indexPath.row]
        
        if item is DynamicTableCells.HeaderItem {
            if selectedHeaderIndex == nil {
                selectedHeaderIndex = indexPath.row
            } else {
                previouslySelectedHeaderIndex = selectedHeaderIndex
                selectedHeaderIndex = indexPath.row
            }
            
            if let previouslySelectedHeaderIndex = previouslySelectedHeaderIndex {
                cells.collapse(previouslySelectedHeaderIndex)
            }
            
            if previouslySelectedHeaderIndex != selectedHeaderIndex {
                cells.expand(selectedHeaderIndex!)
            } else {
                selectedHeaderIndex = nil
                previouslySelectedHeaderIndex = nil
            }
            
            alertTable.beginUpdates()
            alertTable.endUpdates()
            
        } else {
            if indexPath.row != selectedItemIndex {
                let cell = alertTable.cellForRow(at: indexPath) as? AlertSettingsTableCell
                cell?.accessoryType = .checkmark
                
                // Uncheck previously selected cell if it's from the same settings group
                if let selectedItemIndex = selectedItemIndex {
                    guard let previousCell = alertTable.cellForRow(at: IndexPath(row: selectedItemIndex, section: 0)) else { return }
                    let previousItem = cells.items[selectedItemIndex]
                    let currentItem = cells.items[indexPath.row]
                    if previousItem.type == currentItem.type {
                        previousCell.accessoryType = .none
                        cells.items[selectedItemIndex].isChecked = false
                    }
                }
                
                selectedItemIndex = indexPath.row
                let selectedItem = cells.items[selectedItemIndex!]
                selectedItem.isChecked = true

                let enumIndex = selectedItemIndex! - selectedHeaderIndex! - 1

                switch selectedItem.type {
                case .audio:
                    selectedAudio = AudioAlert.allValues[enumIndex]
                case .vibration:
                    selectedVibration = VibrateAlert.allValues[enumIndex]
                default:
                    print("Header should never run code here!")
                }
                
                cells.items[selectedHeaderIndex!].value = (cell?.settingLabel.text)!
                alertTable.reloadRows(at: [IndexPath(row: selectedHeaderIndex!, section: 0)] , with: .fade)
                cells.collapse(selectedHeaderIndex!)
                alertTable.beginUpdates()
                alertTable.endUpdates()

            }
        }
    }
    
}

// MARK: - Alert Table Cell

class AlertSettingsTableCell: UITableViewCell {
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var settingLabel: UILabel!

}
