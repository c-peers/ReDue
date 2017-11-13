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

enum AlertType {
    case empty, duplicate
    case missed, complete
    case delete, upgradeNeeded
}

class NewTasksViewController: UIViewController, UIScrollViewDelegate {

    //MARK: - Outlets

    //@IBOutlet weak var scrollView: UIScrollView!
    //@IBOutlet weak var newTaskView: UIView!
    //@IBOutlet weak var statusBarView: UIView!
    @IBOutlet weak var occurrenceLabel: UILabel!
    
    @IBOutlet weak var taskNameTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var taskLengthTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var occurrenceRateTextField: SkyFloatingLabelTextField!
    
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
    
    // For occurrence
    var taskDays = [String]()
    
    // For pickerview
    var hours = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"]
    var minutes: [String] = ["0"]
    var selectedHours = "0"
    var selectedMinutes = "0"
    
    var frequency = [1: "week", 2: "other week", 3: "3rd week", 4: "4th week", 5: "5th week", 6: "6th week", 7: "7th week", 8: "8th week"]

    var pickerData: [[String]] = []
    var selectedFromPicker: UILabel!
    
    var tasks = [String]()
    var taskFrequency = 0.0
    
    var timePickerView = UIPickerView()
    var frequencyPickerView = UIPickerView()
    let pickerViewDatasource = TaskTimePicker()
    
    var appData = AppData()
    
    var check = Check()
    
    var navigationBar: UINavigationBar?

    //MARK: - View and Basic Functions
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Array of textfields for easier setup and color changing
        textFieldArray = [taskNameTextField, taskLengthTextField, occurrenceRateTextField]
        
        for textField in textFieldArray {
            autoResizePlaceholderText(for: textField)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

        //******************************
        // Theme
        //******************************
        
        setTheme()
        
        //******************************
        // Pickerview initialization start
        //******************************

        for number in 1...12 {
            
            minutes.append(String(number * 5))
            
        }
        
        print(minutes)
        pickerData = [hours, minutes]
        
        let pickerToolBar = UIToolbar()
        pickerToolBar.barStyle = UIBarStyle.default
        pickerToolBar.isTranslucent = true
        pickerToolBar.barTintColor = appData.appColor
        //pickerToolBar.tintColor = UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1)
        pickerToolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(donePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.plain, target: self, action: #selector(cancelPicker))
        
        pickerToolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        
        pickerToolBar.isUserInteractionEnabled = true
        
        
        timePickerView.dataSource = self
        timePickerView.delegate = self
        taskLengthTextField.delegate = self
        taskLengthTextField.inputView = timePickerView
        taskLengthTextField.inputAccessoryView = pickerToolBar
        
        taskNameTextField.delegate = self

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
        occurrenceRateTextField.delegate = self
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
        
        createButton.layer.borderColor = appData.appColor.cgColor
        createButton.layer.borderWidth = 2
        createButton.layer.cornerRadius = 10.0
        
        createButton.setTitleColor(appData.appColor, for: .normal)
        
    }
    
    func prepareDayButtons(for button: UIButton) {
        
        button.layer.borderWidth = 1
        button.layer.borderColor = appData.appColor.cgColor
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
    
    func setTheme() {
        
        let themeColor = appData.appColor
        let darkerThemeColor = themeColor.darken(byPercentage: 0.25)
        
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
            let newTask = Task(name: taskName, time: taskTime, days: taskDays, multiplier: 1.0, rollover: 0.0, frequency: taskFrequency, completed: 0.0, runWeek: currentWeek)
            
            //vc.initializeCheck()
            vc.check.ifTaskWillRunToday(newTask)
            
            vc.tasks.append(newTask)
            vc.taskNames.append(taskName)

        }
    }
    
    //MARK: - Button Actions/Functions
    
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
    
    
    @IBAction func createTask(_ sender: Any) {

        if appData.isFullVersion || tasks.count < 2 {
            taskVerification()
        } else {
            popAlert(alertType: .upgradeNeeded)
        }
        
    }
    
    func taskVerification() {
        
        let taskNameWasEntered = taskNameTextField.hasText
        let taskTimeWasEntered = taskLengthTextField.hasText
        let frequencyWasEntered = occurrenceRateTextField.hasText
        let taskDaysWereEntered = !taskDays.isEmpty

        if tasks.index(of: taskNameTextField.text!) != nil {
            
            taskNameTextField.errorMessage = "This name already exists"
            popAlert(alertType: .duplicate)
            
        } else if taskNameWasEntered && taskTimeWasEntered && frequencyWasEntered && taskDaysWereEntered {
            
            performSegue(withIdentifier: "createdTaskUnwindSegue", sender: self)
            
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
        print("Keyboard was shown")
        var info = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
        let contentInsets : UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize!.height, 0.0)
        
        //self.scrollView.contentInset = contentInsets
        //self.scrollView.scrollIndicatorInsets = contentInsets
        
        print(taskLengthTextField.isFirstResponder)
        
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
    
    func textFieldDidBeginEditing(_ textField: UITextField){
        activeTextField = textField as? SkyFloatingLabelTextField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField){
        activeTextField = nil
    }
    
    @objc func doneOccurrence() {
        occurrenceRateTextField.resignFirstResponder()
    }
    
}
