//
//  TaskSettingsViewController.swift
//  RepeatingTasks
//
//  Created by Chase Peers on 8/21/17.
//  Copyright © 2017 Chase Peers. All rights reserved.
//

import UIKit
import Chameleon
import SkyFloatingLabelTextField
import SwiftyBeaver

class TaskSettingsViewController: UIViewController {

    //MARK: - Outlets
    
    //@IBOutlet weak var scrollView: UIScrollView!
    //@IBOutlet weak var bgView: UIView!
    
    @IBOutlet weak var taskNameTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var taskLengthTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var occurrenceRateTextField: SkyFloatingLabelTextField!

    @IBOutlet weak var occurrenceLabel: UILabel!

    @IBOutlet weak var rolloverRateLabel: UILabel!
    @IBOutlet weak var rolloverSlider: UISlider!
    @IBOutlet weak var rolloverSliderValueLabel: UILabel!
    
    @IBOutlet weak var sunday: UIButton!
    @IBOutlet weak var monday: UIButton!
    @IBOutlet weak var tuesday: UIButton!
    @IBOutlet weak var wednesday: UIButton!
    @IBOutlet weak var thursday: UIButton!
    @IBOutlet weak var friday: UIButton!
    @IBOutlet weak var saturday: UIButton!
    
    @IBOutlet weak var completeButton: UIButton!
    @IBOutlet weak var completeButtonConstraint: NSLayoutConstraint!
    
    //MARK: - Properties
    
    var task = Task()
    var taskName = ""
    var taskTime = 0.0
    var taskDays = [""]
    var frequency = 0.0
    var multiplier = 1.0
    
    var originalTime = 0.0
    var originalDays = [""]
    var originalFrequency = 0.0
    var originalMultiplier = 0.0
    
    var valuesChanged = false
    
    var appData = AppData()

    let timer = CountdownTimer()
    
    let log = SwiftyBeaver.self
    
    // Used to corretly show the keyboard and scroll the view into place
    var activeTextField: UITextField?
    var textFieldArray = [SkyFloatingLabelTextField]()
    
    // For pickerview
    var hours = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"]
    var minutes: [String] = ["0"]
    var selectedHours = "0"
    var selectedMinutes = "0"
    
    var frequencyData = [1: "week", 2: "other week", 3: "3rd week", 4: "4th week", 5: "5th week", 6: "6th week", 7: "7th week", 8: "8th week"]
    
    var pickerData: [[String]] = []
    var selectedFromPicker: UILabel!
    
    var taskNames = [String]()
    
    var timePickerView = UIPickerView()
    var frequencyPickerView = UIPickerView()
    let pickerViewDatasource = TaskTimePicker()
    
    //MARK: - View and Basic Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Array of textfields for easier setup and color changing
        textFieldArray = [taskNameTextField, taskLengthTextField, occurrenceRateTextField]
        
        setTheme()

        taskNameTextField.delegate = self
        taskLengthTextField.delegate = self
        occurrenceRateTextField.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        //let iOSDefaultBlue = UIButton(type: UIButtonType.system).titleColor(for: .normal)!
        //rolloverSlider.tintColor = FlatSkyBlueDark()
        rolloverSlider.minimumValue = 0.0
        rolloverSlider.maximumValue = 2.5
        
        //******************************
        // Day selection start
        //******************************
        
        prepareDayButton(sunday)
        prepareDayButton(monday)
        prepareDayButton(tuesday)
        prepareDayButton(wednesday)
        prepareDayButton(thursday)
        prepareDayButton(friday)
        prepareDayButton(saturday)
        
        setValues()
        
        //******************************
        // Pickerview initialization start
        //******************************
        
        for number in 1...12 {
            
            minutes.append(String(number * 5))
            
        }
        
        pickerData = [hours, minutes]

        let pickerToolBar = UIToolbar()
        pickerToolBar.barStyle = UIBarStyle.default
        pickerToolBar.isTranslucent = true
        pickerToolBar.barTintColor = appData.appColor
        pickerToolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(donePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.plain, target: self, action: #selector(cancelPicker))
        
        pickerToolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        
        pickerToolBar.isUserInteractionEnabled = true
                
        timePickerView.dataSource = self
        timePickerView.delegate = self
        timePickerView.tag = 0
        //timePickerView.selectRow(<#T##row: Int##Int#>, inComponent: <#T##Int#>, animated: <#T##Bool#>)
        taskLengthTextField.inputView = timePickerView
        taskLengthTextField.inputAccessoryView = pickerToolBar
        
        //timePickerView.selectRow(0, inComponent: 0, animated: true)
        //timePickerView.selectRow(0, inComponent: 1, animated: true)
        
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
        frequencyPickerView.selectRow(Int(frequency - 1), inComponent: 0, animated: true)
        occurrenceRateTextField.inputView = frequencyPickerView
        occurrenceRateTextField.inputAccessoryView = pickerToolBar
        //occurrenceRateTextField.inputAccessoryView = decimalPadToolBar
        
        //******************************
        // Occurrence rate initialization finished
        //******************************

        
        let themeColor = appData.appColor
        
        if appData.darknessCheck(for: themeColor) {
            
            pickerToolBar.tintColor = UIColor.white
            decimalPadToolBar.tintColor = UIColor.white
            
        } else {
            
            pickerToolBar.tintColor = UIColor.black
            decimalPadToolBar.tintColor = UIColor.black
            
        }
        
        completeButton.layer.borderColor = appData.appColor.cgColor
        completeButton.layer.borderWidth = 2
        completeButton.layer.cornerRadius = 10.0
        
        completeButton.setTitleColor(appData.appColor, for: .normal)

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if valuesChanged {
            saveTaskData()
        }
    }
    
    func didValuesChange(added newString: String? = nil, to field: SkyFloatingLabelTextField? = nil) {
        
        var nameChanged = (taskNameTextField.text == task.name) ? false : true
        var timeChanged = (taskTime == originalTime) ? false : true
        let daysChanged = (taskDays == originalDays) ? false : true
        var frequencyChanged = (frequency == originalFrequency) ? false : true
        let rolloverChanged = (multiplier == originalMultiplier) ? false : true

        if let string = newString, let textField = field {
            
            let text = textField.text! + string
            
            switch textField {
            case occurrenceRateTextField:
                frequencyChanged = !compare(occurrenceRateTextField, with: text)
            case taskNameTextField:
                nameChanged = !compare(taskLengthTextField, with: text)
            case taskLengthTextField:
                timeChanged = !compare(occurrenceRateTextField, with: text)
            default:
                break
            }
            
        }
        
        let finalCheck = nameChanged || timeChanged || daysChanged || frequencyChanged || rolloverChanged
        print(finalCheck)
        
        if finalCheck {
            completeButton.setTitle("Save Changes", for: .normal)
            changeSize(of: completeButtonConstraint, to: 150)
            valuesChanged = true
        } else {
            completeButton.setTitle("Cancel", for: .normal)
            changeSize(of: completeButtonConstraint, to: 80)
            valuesChanged = false
        }
        
    }
    
    func changeSize(of constraint: NSLayoutConstraint,to size: CGFloat) {
        UIView.animate(withDuration: 0.3) {
            constraint.constant = size
        }
    }
    
    func saveTaskData() {
        
        let multiplier = Double(rolloverSlider.value)
        
        let nameChanged = (taskNameTextField.text == task.name) ? false : true
        let timeChanged = (taskTime == originalTime) ? false : true
        let daysChanged = (taskDays == originalDays) ? false : true
        let frequencyChanged = (frequency == originalFrequency) ? false : true
        let rolloverChanged = (multiplier == originalMultiplier) ? false : true

        if let newTaskName = taskNameTextField.text {
            if nameChanged {
                log.info("Original name was \(task.name)")
                task.name = newTaskName
                log.info("Task name changed to \(task.name)")
            }
        }
        
        if rolloverChanged {
            log.info("Task multiplier was \(task.multiplier)")
            task.multiplier = multiplier
            log.info("Task multiplier changed to \(task.multiplier)")
        }
        
        if daysChanged {
            log.info("Task days was \(task.days)")
            task.days = taskDays
            log.info("Task days changed to \(task.days)")
        }
        
        if frequencyChanged {
            log.info("Task frequency was \(task.frequency)")
            task.frequency = frequency
            log.info("Task frequency changed to \(task.frequency)")
        }
        
        if timeChanged {
            log.info("Task time was \(task.time)")
            log.info("Weighted time was \(task.weightedTime)")
            task.time = taskTime
            task.setWeightedTime()
            log.info("Task time changed to \(task.time)")
            log.info("New weighted time is \(task.weightedTime)")
        }

        //        if let frequency = occurrenceRateTextField.text {
//            taskData.taskFrequency = Double(frequency)!
//            occurranceRate = Double(frequency)!
//        }
        
        // Some fuckery to get the parent VC
        let nav = self.presentingViewController as? UINavigationController
        let i = nav?.viewControllers.count
        let vc = nav?.viewControllers[i! - 1] as! TaskDetailViewController

        vc.title = task.name
        vc.task = task
        vc.saveData()
        _ = vc.formatTimer()
        
    }
    
    //MARK: - Setup Functions
    
    func setTheme() {
        
        let themeColor = appData.appColor
        let darkerThemeColor = themeColor.darken(byPercentage: 0.25)
        
        view.backgroundColor = darkerThemeColor
        //scrollView.backgroundColor = darkerThemeColor
        //bgView.backgroundColor = darkerThemeColor
        
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
            rolloverRateLabel.textColor = .white
            rolloverSliderValueLabel.textColor = .white
            //            setStatusBarStyle(.lightContent)
            
        } else {
            
            for textField in textFieldArray {
                setTextFieldColor(for: textField, as: .black)
            }
            occurrenceLabel.textColor = .black
            rolloverRateLabel.textColor = .black
            rolloverSliderValueLabel.textColor = .black
            //            setStatusBarStyle(.default)
            
        }
        
    }
    
    func setTextFieldColor(for textField: SkyFloatingLabelTextField, as color: UIColor) {
        textField.textColor = color
        textField.titleColor = color
        textField.selectedTitleColor = color
    }
    
    func prepareDayButton(_ button: UIButton) {
        button.layer.borderWidth = 1
        button.layer.borderColor = appData.appColor.cgColor
        button.tag = 0
    }
    
    func setValues() {
        
        taskName = task.name
        taskTime = task.time
        taskDays = task.days
        frequency = task.frequency
        multiplier = task.multiplier
        
        originalTime = taskTime
        originalDays = taskDays
        originalFrequency = frequency
        originalMultiplier = multiplier
        
        taskNameTextField.text = task.name
        taskLengthTextField.text = setTaskTime()
        
        if Int(frequency) == 1 {
            occurrenceRateTextField.text = "Every week"
        } else {
            let freq = Int(frequency)
            occurrenceRateTextField.text = "Every " + String(freq) + " weeks"
        }
        
        rolloverSlider.value = Float(multiplier)
        let sliderValueAsString = String(rolloverSlider.value)
        rolloverSliderValueLabel.text = sliderValueAsString + "x of leftover time added to next task"
        print(rolloverSliderValueLabel.text!)
        for day in taskDays {
            
            switch day {
            case "Sunday":
                sunday.tag = 1
                setButtonOn(for: sunday)
            case "Monday":
                monday.tag = 1
                setButtonOn(for: monday)
            case "Tuesday":
                tuesday.tag = 1
                setButtonOn(for: tuesday)
            case "Wednesday":
                wednesday.tag = 1
                setButtonOn(for: wednesday)
            case "Thursday":
                thursday.tag = 1
                setButtonOn(for: thursday)
            case "Friday":
                friday.tag = 1
                setButtonOn(for: friday)
            case "Saturday":
                saturday.tag = 1
                setButtonOn(for: saturday)
            default:
                break
            }
            
        }
        
    }
    
    func setTaskTime() -> String {
        
        let hours = Int(taskTime / 3600)
        let minutes = Int(taskTime.truncatingRemainder(dividingBy: 3600) / 60)
        
        let timeString: String
        
        if hours < 1 && minutes > 0 {
            timeString = String(minutes) + " minutes"
        } else if hours > 0 && minutes < 1 {
            timeString = String(hours) + " hours"
        } else {
            timeString = String(hours) + " hours " + String(minutes) + " minutes"
        }
        
        return timeString
        
    }
    
    //MARK: - Button Actions/Functions
    
    @IBAction func sliderChanged(_ sender: UISlider) {
        
        let toRound = Int(sender.value * 10)
        sender.setValue(Float(toRound) / 10, animated: true)
        print(sender.value)
        
        rolloverSliderValueLabel.text = String(sender.value) + "x of leftover time added to next task"
        multiplier = Double(sender.value)
        didValuesChange()
        
    }
    
    func setButtonOn(for button: UIButton) {
        button.layer.backgroundColor = self.appData.appColor.cgColor
        button.setTitleColor(UIColor.white, for: .normal)
    }
    
    func buttonAction(for button: UIButton) {
        
        let themeColor = appData.appColor
        let darkerThemeColor = themeColor.darken(byPercentage: 0.25)
        
        if button.tag == 0 {
            UIView.animate(withDuration: 0.5, animations: { () -> Void in
                button.layer.backgroundColor = themeColor.cgColor
                button.setTitleColor(UIColor.white, for: .normal)
            })
            button.tag = 1
        } else {
            UIView.animate(withDuration: 0.5, animations: { () -> Void in
                button.layer.backgroundColor = darkerThemeColor?.cgColor
                button.setTitleColor(UIColor.black, for: .normal)
            })
            button.tag = 0
        }
        
        didValuesChange()

    }
    
    @IBAction func sundayTapped(_ sender: UIButton) {

        if sunday.tag == 0 {
            taskDays.append("Sunday")
        } else {
            taskDays = taskDays.filter { $0 != "Sunday" }
        }
        
        buttonAction(for: sender)

    }
    
    @IBAction func mondayTapped(_ sender: UIButton) {

        if monday.tag == 0 {
            taskDays.append("Monday")
        } else {
            taskDays = taskDays.filter { $0 != "Monday" }
        }
        
        buttonAction(for: sender)
        
    }
    
    @IBAction func tuesdayTapped(_ sender: UIButton) {
        
        if tuesday.tag == 0 {
            taskDays.append("Tuesday")
        } else {
            taskDays = taskDays.filter { $0 != "Tuesday" }
        }
        
        buttonAction(for: sender)
    
    }
    
    @IBAction func wednesdayTapped(_ sender: UIButton) {
        
        if wednesday.tag == 0 {
            taskDays.append("Wednesday")
        } else {
            taskDays = taskDays.filter { $0 != "Wednesday" }
        }
        
        buttonAction(for: sender)
    
    }
    
    @IBAction func thursdayTapped(_ sender: UIButton) {
        
        if thursday.tag == 0 {
            taskDays.append("Thursday")
        } else {
            taskDays = taskDays.filter { $0 != "Thursday" }
        }
        
        buttonAction(for: sender)
    
    }
    
    @IBAction func fridayTapped(_ sender: UIButton) {
        
        if friday.tag == 0 {
            taskDays.append("Friday")
        } else {
            taskDays = taskDays.filter { $0 != "Friday" }
        }
        
        buttonAction(for: sender)
    
    }
    
    @IBAction func saturdayTapped(_ sender: UIButton) {

        if saturday.tag == 0 {
            taskDays.append("Saturday")
        } else {
            taskDays = taskDays.filter { $0 != "Saturday" }
        }
        
        buttonAction(for: sender)
        
    }
    
    @IBAction func editTask(_ sender: Any) {
        
        let taskNameWasEntered = taskNameTextField.hasText
        let taskTimeWasEntered = taskLengthTextField.hasText
        let frequencyWasEntered = occurrenceRateTextField.hasText
        let taskDaysWereEntered = !taskDays.isEmpty
        
        if taskNames.index(of: taskNameTextField.text!) != nil {
            
            taskNameTextField.errorMessage = "This name already exists"
            popAlert(alertType: .duplicate)
            
        } else if taskNameWasEntered && taskTimeWasEntered && frequencyWasEntered && taskDaysWereEntered {
            
            dismiss(animated: true, completion: nil)
            
        } else {
            
            if !taskNameWasEntered {
                taskNameTextField.errorMessage = "Need a Name"
            }
            
            if !taskTimeWasEntered {
                taskLengthTextField.errorMessage = "Need a Time"
            }
            
            if !frequencyWasEntered {
                occurrenceRateTextField.errorMessage = "Need frequency"
            }
            
            popAlert(alertType: .empty)
            
        }
        
    }
    
    //MARK: - Alert
    
    func popAlert(alertType: AlertType) {
        
        let message: String
        if alertType == .empty {
            message = "Please fill out all fields before creating task"
        } else {
            message = "A task with this name already exists"
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
    
    //MARK: - Keyoard Functions
    
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

        //self.scrollView.isScrollEnabled = true
        var info = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
        let contentInsets : UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize!.height, 0.0)
        
        //self.scrollView.contentInset = contentInsets
        //self.scrollView.scrollIndicatorInsets = contentInsets
        
        var aRect : CGRect = self.view.frame
        aRect.size.height -= keyboardSize!.height
        if let activeTextField = self.activeTextField {
            if (!aRect.contains(activeTextField.frame.origin)){
                print(!aRect.contains(activeTextField.frame.origin))
                
                //self.scrollView.scrollRectToVisible(activeTextField.frame, animated: true)
                
            }
        }
        
    }
    
    @objc func keyboardWillBeHidden(notification: NSNotification){
        //Once keyboard disappears, restore original positions
        var info = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
        let contentInsets : UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, -keyboardSize!.height, 0.0)
        //self.scrollView.contentInset = contentInsets
        //self.scrollView.scrollIndicatorInsets = contentInsets
        self.view.endEditing(true)
        //self.scrollView.isScrollEnabled = false
        
    }

}

//******************************
//UITextField functions
//******************************

//MARK: - Text Field Delegate

extension TaskSettingsViewController: UITextFieldDelegate {
    
    func compare(_ textField: SkyFloatingLabelTextField, with string: String) -> Bool{
        return textField.text == string
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        didValuesChange(added: string, to: textField as? SkyFloatingLabelTextField)
        
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
                    frequency = Double(string)!
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
    
    func textFieldDidBeginEditing(_ textField: UITextField){
        activeTextField = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField){
        activeTextField = nil
    }
    
    @objc func doneOccurrence() {
        occurrenceRateTextField.resignFirstResponder()
    }
    
}

//******************************
//UIPickerView functions
//******************************

//MARK: - Picker View Delegate

extension TaskSettingsViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
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
            }
            
            taskTime = Double((Int(selectedHours)! * 3600) + (Int(selectedMinutes)! * 60))
            selectedFromPicker = pickerView.view(forRow: row, forComponent: component) as! UILabel
            
            pickerView.reloadAllComponents()

        } else {
            
            frequency = Double(row + 1)
            occurrenceRateTextField.text = "Every " + frequencyData[row + 1]!
            selectedFromPicker = pickerView.view(forRow: row, forComponent: component) as! UILabel
            
        }
        
        didValuesChange()
        
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 0 {
            return pickerData[component].count
        } else {
            if component == 0 {
                return 1
            } else {
                return frequencyData.count
            }
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView.tag == 0 {
            return pickerData[component][row]
        } else {
            if component == 0 {
                return "Every"
            } else {
                return frequencyData[row + 1]
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
                let text = frequencyData[row + 1]!
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
        didValuesChange()
        resignResponder()
    }
    
    @objc func cancelPicker() {
        didValuesChange()
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
