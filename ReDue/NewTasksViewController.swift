//
//  NewTasksViewController.swift
//  RepeatingTasks
//
//  Created by Chase Peers on 6/16/17.
//  Copyright © 2017 Chase Peers. All rights reserved.
//

import UIKit
import Chameleon
import SkyFloatingLabelTextField
import Presentr

class NewTasksViewController: UIViewController, UIScrollViewDelegate {

    //MARK: - Outlets

    //@IBOutlet weak var scrollView: UIScrollView!
    //@IBOutlet weak var newTaskView: UIView!
    //@IBOutlet weak var statusBarView: UIView!
    @IBOutlet weak var occurrenceLabel: UILabel!
    
    @IBOutlet weak var taskNameTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var taskLengthTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var occurrenceRateTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var alertTextField: SkyFloatingLabelTextField!
    
    @IBOutlet weak var sunday: UIButton!
    @IBOutlet weak var monday: UIButton!
    @IBOutlet weak var tuesday: UIButton!
    @IBOutlet weak var wednesday: UIButton!
    @IBOutlet weak var thursday: UIButton!
    @IBOutlet weak var friday: UIButton!
    @IBOutlet weak var saturday: UIButton!
    
    @IBOutlet weak var createButton: UIButton!
    
    //MARK: - Properties
    
    // Used to corretly show the keyboard and scroll the view into place
    var activeTextField: SkyFloatingLabelTextField?
    var textFieldArray = [SkyFloatingLabelTextField]()
    var keyboardOffset:CGFloat = 0.0
    
    var audioAlert: AudioAlert = .none
    var vibrateAlert: VibrateAlert = .off /*.none*/ 
    
    // For occurrence
    var taskDays = ["Sunday": false, "Monday": false, "Tuesday": false, "Wednesday": false, "Thursday": false, "Friday": false, "Saturday": false]
    
    // For pickerview
    //class Picker {
        var hours = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"]
        var minutes: [String] = ["0"]
        var selectedHours = "0"
        var selectedMinutes = "0"
        var frequency = [1: "week", 2: "other week", 3: "3rd week", 4: "4th week", 5: "5th week", 6: "6th week", 7: "7th week", 8: "8th week"]
        
        var pickerData: [[String]] = []
        var selectedFromPicker: UILabel!

        var timePickerView = UIPickerView()
        var frequencyPickerView = UIPickerView()
    //}
    
    var tasks = [String]()
    var taskFrequency = 0.0
    
    
    var appData = AppData()
    
    var check = Check()
    
    let addPresenter: Presentr = {
        let width = ModalSize.fluid(percentage: 0.8)
        let height = ModalSize.fluid(percentage: 0.8)
        let center = ModalCenterPosition.center
        let customType = PresentationType.custom(width: width, height: height, center: center)
        
        let customPresenter = Presentr(presentationType: customType)
        //let customPresenter = Presentr(presentationType: .popup)
        
        customPresenter.transitionType = .coverVertical
        customPresenter.dismissTransitionType = .coverVertical
        customPresenter.roundCorners = true
        customPresenter.cornerRadius = 10.0
        customPresenter.backgroundColor = UIColor.lightGray
        customPresenter.backgroundOpacity = 0.5
        customPresenter.dismissOnSwipe = false
        customPresenter.blurBackground = true
        customPresenter.blurStyle = .regular
        customPresenter.keyboardTranslationType = .moveUp
        
        let opacity: Float = 0.5
        let offset = CGSize(width: 2.0, height: 2.0)
        let radius = CGFloat(3.0)
        let shadow = PresentrShadow(shadowColor: .black, shadowOpacity: opacity, shadowOffset: offset, shadowRadius: radius)
        customPresenter.dropShadow = shadow
        
        return customPresenter
    }()
    
    var colors = Colors(main: HexColor("247BA0")!, bg: FlatWhite(), task1: HexColor("70C1B3")!, task2: HexColor("B2DBBF")!, progress: HexColor("FF1654")!)

    //MARK: - View and Basic Functions

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Array of textfields for easier setup and color changing
        textFieldArray = [taskNameTextField, taskLengthTextField, occurrenceRateTextField, alertTextField]
        
        for textField in textFieldArray {
            autoResizePlaceholderText(for: textField)
            setDelegate(for: textField)
        }
        
        alertTextField.inputView = UIView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

        //******************************
        // Theme
        //******************************
        
        setTheme()
        
        //******************************
        // Pickerview initialization start
        //******************************

        for number in 1...59 {
            
            minutes.append(String(number))
            
        }
        
        print(minutes)
        pickerData = [hours, minutes]
        
        let pickerToolBar = UIToolbar()
        pickerToolBar.barStyle = UIBarStyle.default
        pickerToolBar.isTranslucent = true
        pickerToolBar.barTintColor = colors.main //appData.appColor
        //pickerToolBar.tintColor = UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1)
        pickerToolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(donePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.plain, target: self, action: #selector(cancelPicker))
        
        pickerToolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        
        pickerToolBar.isUserInteractionEnabled = true
        
        
        timePickerView.dataSource = self
        timePickerView.delegate = self
        taskLengthTextField.inputView = timePickerView
        taskLengthTextField.inputAccessoryView = pickerToolBar
        
        //******************************
        // Occurrence rate start
        //******************************
        
        let decimalPadToolBar = UIToolbar.init()
        decimalPadToolBar.sizeToFit()
        let decimalDoneButton = UIBarButtonItem.init(barButtonSystemItem: .done, target: self, action: #selector(doneOccurrence))
        decimalPadToolBar.items = [decimalDoneButton]
        
        //occurrenceRateTextField.keyboardType = .numberPad
        frequencyPickerView.dataSource = self
        frequencyPickerView.delegate = self
        frequencyPickerView.tag = 1
        occurrenceRateTextField.inputView = frequencyPickerView
        occurrenceRateTextField.inputAccessoryView = pickerToolBar
        //occurrenceRateTextField.inputAccessoryView = decimalPadToolBar
        
        //******************************
        // Occurrence rate initialization finished
        //******************************

        let themeColor = colors.main //appData.appColor
        
        if appData.darknessCheck(for: themeColor) {
            
            pickerToolBar.tintColor = UIColor.white
            decimalPadToolBar.tintColor = UIColor.white
            
        } else {
            
            pickerToolBar.tintColor = UIColor.black
            decimalPadToolBar.tintColor = UIColor.black

        }

        //******************************
        // Day selection start
        //******************************

        prepareDayButtons(for: sunday)
        prepareDayButtons(for: monday)
        prepareDayButtons(for: tuesday)
        prepareDayButtons(for: wednesday)
        prepareDayButtons(for: thursday)
        prepareDayButtons(for: friday)
        prepareDayButtons(for: saturday)
        
        createButton.layer.borderColor = colors.main.cgColor //appData.appColor.cgColor
        createButton.layer.borderWidth = 2
        createButton.layer.cornerRadius = 10.0
        
        createButton.setTitleColor(colors.main /*appData.appColor*/, for: .normal)
        
    }
    
    func prepareDayButtons(for button: UIButton) {
        
        let darkerThemeColor = colors.darkMain //appData.appColor.darken(byPercentage: 0.25)
        if appData.darknessCheck(for: darkerThemeColor) {
            button.setTitleColor(.white, for: .normal)
        } else {
            button.setTitleColor(.black, for: .normal)
        }
        
        button.layer.borderWidth = 1
        button.layer.borderColor = colors.main.cgColor //appData.appColor.cgColor
        button.tag = 0
    }
    
    func autoResizePlaceholderText(for textField: SkyFloatingLabelTextField) {
        for  subView in textField.subviews {
            if let label = subView as? UILabel {
                label.minimumScaleFactor = 0.3
                label.adjustsFontSizeToFitWidth = true
            }
        }
    }
    
    func setDelegate(for textField: SkyFloatingLabelTextField) {
        textField.delegate = self
    }
    
    func setTheme() {
        
        colors = Colors.init(main: appData.mainColor!, bg: appData.bgColor!, task1: appData.taskColor1!, task2: appData.taskColor2!, progress: appData.progressColor!)

        //let themeColor = colors.main
        
        let darkerThemeColor = colors.darkMain
        view.backgroundColor = darkerThemeColor
        
//        if appData.isNightMode {
//            //NightNight.theme = .night
//        } else {
//            //NightNight.theme = .normal
//        }
//
        if appData.darknessCheck(for: darkerThemeColor) {

            for textField in textFieldArray {
                setTextFieldColor(for: textField, as: .white)
            }
            occurrenceLabel.textColor = .white
            //            setStatusBarStyle(.lightContent)

        } else {
            
            for textField in textFieldArray {
                setTextFieldColor(for: textField, as: .black)
            }
            occurrenceLabel.textColor = .black
//            setStatusBarStyle(.default)

        }

    }
    
    func setTextFieldColor(for textField: SkyFloatingLabelTextField, as color: UIColor) {
        textField.textColor = color
        textField.titleColor = color
        textField.selectedTitleColor = color
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "createdTaskUnwindSegue" {
            
            let vc = segue.destination as! TaskViewController
            
            let taskName = taskNameTextField.text!
            
            var taskTime = 0.0
            
            if selectedHours != "0" {
                
                let hoursAsInt = Int(selectedHours)
                
                if selectedMinutes != "0" {
                    let minutesAsInt = Int(selectedMinutes)
                    taskTime = Double(hoursAsInt! * 3600 + minutesAsInt! * 60)
                } else {
                    taskTime = Double(hoursAsInt! * 3600)
                }
                
            } else if selectedMinutes != "0" {
                let minutesAsInt = Int(selectedMinutes)
                taskTime = Double(minutesAsInt! * 60)
            }
            
            let currentWeek = check.currentWeek
            let newTask = Task(name: taskName, time: taskTime, days: taskDays, multiplier: 1.0, rollover: 0.0, frequency: taskFrequency, completed: 0.0, runWeek: currentWeek, audioAlert: audioAlert, vibrateAlert: vibrateAlert)
            
            //vc.initializeCheck()
            vc.check.ifTaskWillRunToday(newTask)
            
            vc.tasks.append(newTask)
            vc.taskNames.append(taskName)

        }
    }
    
    func preparePresenter(ofHeight height: Float, ofWidth width: Float) {
        let width = ModalSize.fluid(percentage: width)
        let height = ModalSize.fluid(percentage: height)
        let center = ModalCenterPosition.center
        let customType = PresentationType.custom(width: width, height: height, center: center)
        
        addPresenter.presentationType = customType
        
    }
    
    func presentAlertSettingsVC() {
        let moreSettingsVC = self.storyboard?.instantiateViewController(withIdentifier: "MoreSettingsVC") as! MoreSettingsParentViewController
        let moreSettingsTable = self.storyboard?.instantiateViewController(withIdentifier: "MoreSettingsTableVC") as! MoreSettingsViewController
        moreSettingsTable.appData = appData
        moreSettingsVC.appData = appData
        moreSettingsVC.presentingVC = self

        switch appData.deviceType {
        case .legacy:
            preparePresenter(ofHeight: 0.5, ofWidth: 0.9)
        case .normal:
            preparePresenter(ofHeight: 0.4, ofWidth: 0.8)
        case .large:
            preparePresenter(ofHeight: 0.4, ofWidth: 0.8)
        case .X:
            preparePresenter(ofHeight: 0.4, ofWidth: 0.8)
        }

        customPresentViewController(addPresenter, viewController: moreSettingsVC, animated: true, completion: nil)
    }
    
    //MARK: - Button Actions/Functions
    
    func buttonAction(for button: UIButton) {
        
        let themeColor = colors.main //appData.appColor
        let darkerThemeColor = colors.darkMain
        
        if button.tag == 0 {
            UIView.animate(withDuration: 0.5, animations: { () -> Void in
                button.layer.backgroundColor = themeColor.cgColor
                //button.setTitleColor(UIColor.white, for: .normal)
            })
            button.tag = 1
        } else {
            UIView.animate(withDuration: 0.5, animations: { () -> Void in
                button.layer.backgroundColor = darkerThemeColor.cgColor
                //button.setTitleColor(UIColor.black, for: .normal)
            })
            button.tag = 0
        }
    
    }
    
    @IBAction func sundayTapped(_ sender: UIButton) {

        if sunday.tag == 0 {
            taskDays["Sunday"] = true
        } else {
            taskDays["Sunday"] = false
        }

        buttonAction(for: sender)
        
    }
    
    @IBAction func mondayTapped(_ sender: UIButton) {

        if monday.tag == 0 {
            taskDays["Monday"] = true
        } else {
            taskDays["Monday"] = false
        }

        buttonAction(for: sender)
        
    }
    
    @IBAction func tuesdayTapped(_ sender: UIButton) {

        if tuesday.tag == 0 {
            taskDays["Tuesday"] = true
        } else {
            taskDays["Tuesday"] = false
        }
        
        buttonAction(for: sender)
        
    }
    
    @IBAction func wednesdayTapped(_ sender: UIButton) {

        if wednesday.tag == 0 {
            taskDays["Wednesday"] = true
        } else {
            taskDays["Wednesday"] = false
        }
        
        buttonAction(for: sender)
        
    }
    
    @IBAction func thursdayTapped(_ sender: UIButton) {

        if thursday.tag == 0 {
            taskDays["Thursday"] = true
        } else {
            taskDays["Thursday"] = false
        }
        
        buttonAction(for: sender)
        
    }
    
    @IBAction func fridayTapped(_ sender: UIButton) {

        if friday.tag == 0 {
            taskDays["Friday"] = true
        } else {
            taskDays["Friday"] = false
        }
        
        buttonAction(for: sender)
        
    }
    
    @IBAction func saturdayTapped(_ sender: UIButton) {

        if saturday.tag == 0 {
            taskDays["Saturday"] = true
        } else {
            taskDays["Saturday"] = false
        }
        
        buttonAction(for: sender)
        
    }
    
    @IBAction func createTask(_ sender: Any) {

        if appData.isFullVersion || tasks.count < 2 {
            taskVerification()
        } else {
            popAlert(alertType: .upgradeNeeded)
        }
        
    }
    
    func taskVerification() {
        
        let taskNameWasEntered = taskNameTextField.hasText
        let taskTimeWasEntered = { return (self.selectedHours != "0" || self.selectedMinutes != "0") }
        let frequencyWasEntered = occurrenceRateTextField.hasText
        let taskDaysWereEntered = !taskDays.isEmpty

        if tasks.index(of: taskNameTextField.text!) != nil {
            
            taskNameTextField.errorMessage = "This name already exists"
            popAlert(alertType: .duplicate)
            
        } else if taskNameWasEntered && taskTimeWasEntered() && frequencyWasEntered && taskDaysWereEntered {
            
            performSegue(withIdentifier: "createdTaskUnwindSegue", sender: self)
            
        } else {
            
            if !taskNameWasEntered {
                taskNameTextField.errorMessage = "Please enter a name"
            }
            
            if !taskTimeWasEntered() {
                taskLengthTextField.errorMessage = "Please enter a time"
            }
            
            if !frequencyWasEntered {
                occurrenceRateTextField.errorMessage = "Please enter the frequency of the task"
            }
            
            popAlert(alertType: .empty)
            
        }

    }
    
    func popAlert(alertType: AlertType) {
        
        let message: String
        if alertType == .empty {
            message = "Please fill out all fields before creating task"
        } else if alertType == .duplicate {
            message = "A task with this name already exists"
        } else {
            message = "Upgrade to premium version to add more tasks."
        }
        
        let alertController = UIAlertController(title: "Warning",
                                                message: message,
                                                preferredStyle: UIAlertControllerStyle.alert)
        
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default){ (action: UIAlertAction) in
            print("Hello")
        }
        
        alertController.addAction(okAction)
        
        present(alertController,animated: true,completion: nil)
        
    }
    
    //MARK: - Keyboard Functions
    
    func registerForKeyboardNotifications(){
        //Adding notifies on keyboard appearing
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func deregisterFromKeyboardNotifications(){
        //Removing notifies on keyboard appearing
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc func keyboardWasShown(notification: NSNotification){
        //Need to calculate keyboard exact size due to Apple suggestions
        print("Keyboard was shown")

        if let keyboardScreenFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardLocalFrame = self.view.convert(keyboardScreenFrame, from: nil)
            var aRect = self.view.frame
            
            aRect.size.height -= keyboardLocalFrame.size.height
            
            guard let textfield = activeTextField else { return }
            
            let textFieldOrigin = textfield.frame.origin
            let keyBoardOrigin = keyboardLocalFrame.origin

            if !aRect.contains(textfield.frame.origin) && (textFieldOrigin.y > keyBoardOrigin.y){
                
                keyboardOffset = textFieldOrigin.y - keyBoardOrigin.y + 50
                //let xValue = self.view.frame.origin.x
                //let yValue = self.view.frame.origin.y
                UIView.animate(withDuration: 0.4, delay: 0.0, options: [], animations: {
                    // Add the transformation in this block
                    //self.view.transform = CGAffineTransform(translationX: xValue, y: yValue - self.keyboardOffset)
                    self.view.frame.origin.y -= self.keyboardOffset //(keyboardSize?.height)!

                }, completion: nil)

            }
        }
        
        print(taskLengthTextField.isFirstResponder)
        
    }
    
    @objc func keyboardWillBeHidden(notification: NSNotification){
        //Once keyboard disappears, restore original positions

        if self.view.frame.origin.y <= 0 {
            //let xValue = self.view.frame.origin.x
            UIView.animate(withDuration: 0.4, delay: 0.0, options: [], animations: {
                // Add the transformation in this block
                //self.view.transform = CGAffineTransform(translationX: xValue, y: self.keyboardOffset)
                self.view.frame.origin.y += self.keyboardOffset //(keyboardSize?.height)!
            }, completion: nil)
        }

        self.view.endEditing(true)
        
    }
    
}

//******************************
//UIPickerView functions
//******************************

//MARK: - Picker View Delegate

extension NewTasksViewController: UIPickerViewDelegate, UIPickerViewDataSource {

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if pickerView.tag == 0 {
            
            selectedHours = pickerData[0][timePickerView.selectedRow(inComponent: 0)]
            selectedMinutes = pickerData[1][timePickerView.selectedRow(inComponent: 1)]
            
            if selectedHours == "0" && selectedMinutes != "0" {
                taskLengthTextField.text = selectedMinutes + " minutes"
            } else if selectedHours != "0" && selectedMinutes  == "0" {
                taskLengthTextField.text = selectedHours + " hours"
            } else if selectedHours != "0" && selectedMinutes != "0" {
                taskLengthTextField.text = selectedHours + " hours " + selectedMinutes + " minutes"
            } else {
                taskLengthTextField.text = ""
            }
            
            selectedFromPicker = pickerView.view(forRow: row, forComponent: component) as! UILabel
            
            pickerView.reloadAllComponents()
            
        } else {
            
            taskFrequency = Double(row + 1)
            occurrenceRateTextField.text = "Every " + frequency[row + 1]!
            selectedFromPicker = pickerView.view(forRow: row, forComponent: component) as! UILabel
            
        }
        
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 0 {
            return pickerData[component].count
        } else {
            if component == 0 {
                return 1
            } else {
                return frequency.count
            }
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView.tag == 0 {
            return pickerData[component][row]
        } else {
            if component == 0 {
                return "Every"
            } else {
                return frequency[row + 1]
            }
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return CGFloat(100.0)
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        
        let pickerLabel = UILabel()
        
        if pickerView.tag == 0 {
            
            let text = pickerData[component][row]
            
            pickerLabel.text = text
            //pickerLabel.textAlignment = NSTextAlignment.center
            pickerLabel.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
            pickerLabel.layer.masksToBounds = true
            pickerLabel.layer.cornerRadius = 5.0
            
            if let lb = pickerView.view(forRow: row, forComponent: component) as? UILabel {
                
                selectedFromPicker = lb
                //selectedFromPicker.backgroundColor = UIColor.orange
                //selectedFromPicker.textColor = UIColor.white
                if component == 0 {
                    selectedFromPicker.text = text + " hours"
                } else if component == 1 {
                    selectedFromPicker.text = text + " minutes"
                }
                
            }
            
        } else {
            
            if component == 0 {
                pickerLabel.text = "Every"
            } else {
                let text = frequency[row + 1]!
                pickerLabel.text = text
            }
            
            //            if let lb = pickerView.view(forRow: row, forComponent: component) as? UILabel {
            //
            //                let text = frequency[row + 1]!
            //                selectedFromPicker = lb
            //                if component == 0 {
            //                    selectedFromPicker.text = "Every"
            //                } else if component == 1 {
            //                    selectedFromPicker.text = text
            //                }
            //
            //            }
        }
        
        return pickerLabel
        
    }
    
    @objc func donePicker() {
        if activeTextField == occurrenceRateTextField && occurrenceRateTextField.text == "" {
            taskFrequency = 1
            occurrenceRateTextField.text = "Every week"
        }
        resignResponder()
    }
    
    @objc func cancelPicker() {
        resignResponder()
        cancelTextField()
    }
    
    func resignResponder() {
        
        if let currentTextField = activeTextField {
            switch currentTextField {
            case taskLengthTextField:
                taskLengthTextField.resignFirstResponder()
            case occurrenceRateTextField:
                occurrenceRateTextField.resignFirstResponder()
            default:
                break
            }
        } else {
            taskLengthTextField.resignFirstResponder()
            occurrenceRateTextField.resignFirstResponder()
        }
        
    }
    
    func cancelTextField() {
        
        if let currentTextField = activeTextField {
            switch currentTextField {
            case taskLengthTextField:
                taskLengthTextField.text = ""
            case occurrenceRateTextField:
                occurrenceRateTextField.text = ""
            default:
                break
            }
        }
        
    }

}

//******************************
//UITextField functions
//******************************

//MARK: - Text Field Delegate

extension NewTasksViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if let floatingText = textField as? SkyFloatingLabelTextField {
    
            if textField.text == "" {
                floatingText.errorMessage = ""
            }
            
            if floatingText == occurrenceRateTextField {
                
                // We only want the last character input to be in this field
                // current characters will be removed and the last input character will be added
                
                if string == "." || string == "0" {
                    return false
                } else {
                    if string == "1" {
                        textField.text = "Every week"
                    } else {
                        textField.text = "Every " + string + " weeks"
                    }
                    print(textField.text!)
                    taskFrequency = Double(string)!
                    return false
                }
                
            }
        }
        
        return true
            
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        activeTextField = textField as? SkyFloatingLabelTextField
        if activeTextField == alertTextField {
            textField.resignFirstResponder()
            presentAlertSettingsVC()
            return false
        }
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField){
    }
    
    func textFieldDidEndEditing(_ textField: UITextField){
        activeTextField = nil
    }
    
    @objc func doneOccurrence() {
        occurrenceRateTextField.resignFirstResponder()
    }
    
}
