//
//  MoreSettingsParentViewController.swift
//  ReDue
//
//  Created by Chase Peers on 2/20/18.
//  Copyright © 2018 Chase Peers. All rights reserved.
//

import UIKit
import Chameleon

class MoreSettingsParentViewController: UIViewController {

    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var doneButton: UIButton!
    
    var presentingVC = UIViewController()
    
    var task: Task?
    var appData = AppData()
    
    var colors = Colors(main: HexColor("247BA0")!, bg: FlatWhite(), task1: HexColor("70C1B3")!, task2: HexColor("B2DBBF")!, progress: HexColor("FF1654")!)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setTheme()
        
        doneButton.setTitle("  Done  ", for: .normal)
        doneButton.setTitleColor(colors.main /*appData.appColor*/, for: .normal)
        doneButton.layer.borderColor = colors.main.cgColor //appData.appColor.cgColor
        doneButton.layer.borderWidth = 2
        doneButton.layer.cornerRadius = 10.0
    }
    
    private func setTheme() {
        
        colors = Colors.init(main: appData.mainColor!, bg: appData.bgColor!, task1: appData.taskColor1!, task2: appData.taskColor2!, progress: appData.progressColor!)
        
        let darkerThemeColor = colors.darkMain
        view.backgroundColor = darkerThemeColor

        if appData.darknessCheck(for: darkerThemeColor) {
            setStatusBarStyle(.lightContent)
        } else {
            setStatusBarStyle(.default)
        }
        
    }

    @IBAction func doneButtonTapped(_ sender: UIButton) {
     
        let timer = CountdownTimer()
        var text = String()
        
        let childNAV = childViewControllers[0] as! UINavigationController
        let childVC = childNAV.viewControllers[0] as! MoreSettingsViewController
        let selectedAudio = childVC.selectedAudioAlert
        let selectedVibration = childVC.selectedVibrateAlert
        
        if let _ = task {
            let vc = presentingVC as! TaskSettingsViewController
            vc.task.audioAlert = selectedAudio
            vc.audio = selectedAudio
            vc.task.vibrateAlert = selectedVibration
            vc.vibrate = selectedVibration

            text = timer.setAlertText(for: selectedAudio, and: selectedVibration)
            //text = String(describing: audioAlert)

            vc.alertTextField.text = text
            vc.didValuesChange(added: text, to: vc.alertTextField)
            vc.resignResponder()
        } else {
            let vc = presentingVC as! NewTasksViewController
            vc.audioAlert = selectedAudio
            vc.vibrateAlert = selectedVibration

            text = timer.setAlertText(for: selectedAudio, and: selectedVibration)
            //text = String(describing: audioAlert)

            vc.alertTextField.text = text
            vc.resignResponder()
        }
        
        dismiss(animated: true, completion: nil)
        
    }
}
