//
//  TaskDetailViewController.swift
//  RepeatingTasks
//
//  Created by Chase Peers on 8/7/17.
//  Copyright © 2017 Chase Peers. All rights reserved.
//

import UIKit
import Chameleon
import Charts
import GoogleMobileAds
import Presentr

class TaskDetailViewController: UIViewController, GADBannerViewDelegate {

    //MARK: - Outlets
    
    @IBOutlet weak var taskTimeLabel: UILabel!
    @IBOutlet weak var taskStartButton: UIButton!
    @IBOutlet weak var resetRolloverButton: UIButton!
    @IBOutlet weak var recentTaskHistory: BarChartView!
    @IBOutlet weak var bannerView: GADBannerView!
    @IBOutlet weak var bannerHeight: NSLayoutConstraint!
    @IBOutlet weak var recentProgressLabel: UILabel!

    //MARK: - Properties
    
    var taskNames = [String]()
    var tasks = [Task]()
    var task = Task()
    
    var isTaskDetailObserverSet = false
    
    var elapsedTime = 0.0
    
    var timeString: String = ""
    
    var dayOfWeekString = ""
    
    var axisMaximum = 0.0
    
    var appData = AppData()
    @objc var timer = CountdownTimer()
    let check = Check()
    
    var startTime = Date()
    var endTime = Date()
    
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
    
    override func viewWillAppear(_ animated: Bool) {
 
        print("Detail - viewWillAppear")
        self.title = task.name
        navigationController?.toolbar.isHidden = false
        prepareNavBar()
        
        startButtonSetup()
        
        setElapsedTime()
        
        let (_, remainingTime) = timer.formatTimer(for: task)
        if task.rollover > 0 && remainingTime > task.time && !task.isRunning && task.isToday {
            rolloverButton(is: .visible)
        } else {
            rolloverButton(is: .hidden)
        }
        
        // The observer for the task detail VC tracks the elapsedTime variable
        // so I can't touch that var at all in here
        if !isTaskDetailObserverSet {
            self.addObserver(self, forKeyPath: #keyPath(timer.elapsedTime), options: .new, context: nil)
            isTaskDetailObserverSet = true
        }

        if timer.isEnabled && task.isRunning {
            
            setImage(as: #imageLiteral(resourceName: "Pause"))
            
            //taskTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self,
            //                                 selector: #selector(timerRunning), userInfo: nil,
            //                                 repeats: true)
            
        }
        
        checkTask()

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add appData to the check class
        initializeCheck()
        
        if !appData.isFullVersion {
            bannerView.adUnitID = "ca-app-pub-3446210370651273/3283732299"
            bannerView.rootViewController = self
            let request = GADRequest()
            request.testDevices = [kGADSimulatorID]
            bannerView.load(request)
        } else {
            bannerHeight.constant = 0
        }

        setElapsedTime()

        taskChartSetup()
        
        // Keep a list of all other task names. Only used when editing the name so
        // there isn't two tasks with the same name
        let taskIndex = taskNames.index(of: task.name)
        taskNames.remove(at: taskIndex!)

    }
    
    /* */
    override func viewWillDisappear(_ animated: Bool) {
        
        let vc = self.navigationController?.viewControllers.first as! TaskViewController
        
        if timer.isEnabled && task.isRunning {
            vc.runningCompletionTime = task.completed
        }
    
        if !(self.navigationController?.viewControllers.contains(self))! && !task.isRunning && !timer.firedFromMainVC {
            if isTaskDetailObserverSet {
                removeObserver(self, forKeyPath: #keyPath(timer.elapsedTime))
                isTaskDetailObserverSet = false
            }
        }
        
        if task.isToday {
            updateTaskCell()
        }
        
    }
    
    func setElapsedTime() {
        elapsedTime = task.completed.rounded()
    }

    func initializeCheck() {
        check.appData = appData
    }

    func prepareNavBar() {
        
        let settings = UIBarButtonItem(image: #imageLiteral(resourceName: "Settings"), style: .plain, target: self, action: #selector(settingsTapped))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let statsButton = UIBarButtonItem(image: #imageLiteral(resourceName: "Charts"), style: .plain, target: self, action: #selector(statsTapped))
        let trashButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(trashTapped))
        toolbarItems = [settings, space, statsButton, space, trashButton]
        
        setTheme()
        
    }
    
    //MARK: - Timer Related Functions
    
    /* Prepares timer if the task will run today
       Otherwise shows that the task is not today */
    func checkTask() {
        
        if task.isToday {
            formatTimer()
            if task.completed >= task.weightedTime {
                taskStartButton.isEnabled = false
            } else {
                taskStartButton.isEnabled = true
            }
        } else {
            taskTimeLabel.text = "No task today"
            taskStartButton.isEnabled = false
        }
    }
    
    /* Update the timer when the timer was started in the list VC
       and then the user moved to the task detail VC
       Follows timer.elapsedTime */
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        //if keyPath == #keyPath(taskData.completedTime) {
        // Update Time Label
        formatTimer()
        //}
    }
    
    /* If not running: returns time - completed
       If running:     returns the same - difference between now and timer.startTime
       class local elapsedTime is used because of KVO */
    func getRemainingTime() -> Double {
        
        let currentTime = Date().timeIntervalSince1970
        elapsedTime = task.completed
        
        if timer.isEnabled && task.isRunning {
            elapsedTime += (currentTime - timer.startTime)
            
            /* Since we can't have two separate places follow the same var
               (because one of them changes the var)
               we need something else to track when a user starts the task here
               and then goes back to the main task screen
               The var below exists JUST for that reason */
            if !timer.firedFromMainVC {
                timer.runningCompletedTime = elapsedTime.rounded()
                //task.completed = elapsedTime
            }
        }
        
        return task.weightedTime - elapsedTime.rounded()

    }
    
    /* Sets the timeLabel and startButton to correct values
       Updates the chart if task is running */
    func formatTimer() {
        // Used for initialization and when the task timer is updated
        
        let remainingTime = getRemainingTime()
        let remainingTimeAsString = timer.getRemainingTimeAsString(withRemaining: remainingTime.rounded())
        
        if remainingTime > 0 {
            print("\(taskTimeLabel.text!) time remaining")
            taskTimeLabel.text = remainingTimeAsString
            taskStartButton.isEnabled = true

            // observeValue is called after view disappears.
            // If you don't check if view is visible then chart will cause a crash
            if self.isViewLoaded && self.view.isTopViewInWindow() {
                loadChartData(willUpdate: true)
            }
            
        } else {
            taskTimeLabel.text = "Complete"
            taskStartButton.isEnabled = false
        }
        
    }
    
    /* Runs the above function (formatTimer) and checks how much
       time is remaining. Stops the timer if time is up */
    @objc func timerRunning() {
        
        let timeRemaining = getRemainingTime()
        formatTimer()
        
        print("Time remaining is \(timeRemaining)")
        print("Elapsed is \(elapsedTime)")
        print("Combination is \(timeRemaining + elapsedTime)")

        if timeRemaining <= 0 || (task.completed == task.weightedTime) {
            
            timerStopped()
            
            setImage(as: #imageLiteral(resourceName: "Play"))
            
        }
    }
    
    /* Stops the scheduled timer and saves data to the timer class,
       task completion, adds to task history
     */
    func timerStopped() {
        
        timer.run.invalidate()
        
        timer.endTime = Date().timeIntervalSince1970
        
        var elapsedTime = (timer.endTime - timer.startTime).rounded()
        
        task.completed += elapsedTime

        if task.completed > task.weightedTime {
            task.completed = task.weightedTime
        }
        
        //if elapsedTime > task.weightedTime {
        //    elapsedTime = task.weightedTime
        //}
        
        
        if task.completed >= task.weightedTime {
            
            if task.vibrateAlert != .none {
                timer.vibrate(for: task)
            }
            
            if task.audioAlert != .none {
                timer.playAudio(for: task)
            }
            
        } else {
            let mainVC = self.navigationController?.viewControllers.first as! TaskViewController
            let resetTime = check.timeToReset(at: mainVC.nextResetTime)
            let timeRemaining = getRemainingTime()
            let remainingTimeString = timer.getRemainingTimeAsString(withRemaining: timeRemaining)
            timer.setMissedTimeNotification(for: task.name, at: resetTime, withRemaining: remainingTimeString)
        }
        
        if let date = task.getAccessDate(lengthFromEnd: 0) {
            task.completedTimeHistory[date]! += elapsedTime
            
            let unfinishedTime = task.time - elapsedTime
            
            if unfinishedTime >= 0 {
                task.missedTimeHistory[date] = unfinishedTime
            } else {
                task.missedTimeHistory[date] = 0
            }
            
        }
        
        taskHasStopped()
        
        saveData()
        
    }
    
    func taskHasStopped() {
        task.isRunning = false
        timer.isEnabled = false
        timer.firedFromMainVC = false
        
    }
    
    func updateTaskCell() {

        let vc = self.navigationController?.viewControllers.first as! TaskViewController
        guard let taskIndex = vc.tasks.index(of: task) else { return }
        let indexPath = IndexPath(item: taskIndex, section: 0)
        let cell = vc.taskList.cellForItem(at: indexPath) as! TaskCollectionViewCell
        
        //let cell = presentingCell
        cell.taskNameField.text = task.name
        _ = cell.formatTimer(for: task)
        
        let id = cell.reuseIdentifier
        if id == "taskCollectionCell_Line" {
            cell.calculateProgress(ofType: .line)
        }
        
        if task.isRunning {
            cell.setImage(as: #imageLiteral(resourceName: "Pause"))
        } else {
            cell.setImage(as: #imageLiteral(resourceName: "Play"))
        }

    }

    // MARK: - Theme
    
    func setTheme() {
        
        colors = Colors.init(main: appData.mainColor!, bg: appData.bgColor!, task1: appData.taskColor1!, task2: appData.taskColor2!, progress: appData.progressColor!)
        
        if appData.isNightMode {
            //NightNight.theme = .night
        } else {
            //NightNight.theme = .normal
        }
        
        let navigationBar = navigationController?.navigationBar
        let bgColor = navigationBar?.barTintColor
        
        let darkerThemeColor = colors.darkMain //appData.appColor.darken(byPercentage: 0.25)
        view.backgroundColor = colors.bg //.darken(byPercentage: Colors.darkLevelOne )//darkerThemeColor

        if appData.darknessCheck(for: bgColor) {
            navigationBar?.tintColor = .white
            navigationBar?.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
            setStatusBarStyle(.lightContent)
        } else {
            navigationBar?.tintColor = .black
            navigationBar?.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.black]
            setStatusBarStyle(.default)
        }
        
        if appData.darknessCheck(for: view.backgroundColor) {
            taskTimeLabel.textColor = .white
            recentProgressLabel.textColor = .white
            resetRolloverButton.setTitleColor(.white, for: .normal)
        } else {
            taskTimeLabel.textColor = .black
            recentProgressLabel.textColor = .black
            resetRolloverButton.setTitleColor(.black, for: .normal)
        }
        
    }

    //MARK: - Button Related Functions
    
    func setImage(as image: UIImage) {
        let stencil = image.withRenderingMode(.alwaysTemplate)
        taskStartButton.setImage(stencil, for: .normal)
        taskStartButton.tintColor = .white
        
    }
    
    func startButtonSetup() {
        
        taskStartButton.layer.cornerRadius = 10.0
        taskStartButton.layer.masksToBounds = true
        
        taskStartButton.layer.shadowColor = UIColor.lightGray.cgColor
        taskStartButton.layer.shadowOffset = CGSize.zero
        taskStartButton.layer.shadowRadius = 2.0
        taskStartButton.layer.shadowOpacity = 2.0
        taskStartButton.layer.shadowPath = UIBezierPath(roundedRect: taskStartButton.layer.bounds, cornerRadius: taskStartButton.layer.cornerRadius).cgPath
        
        setImage(as: #imageLiteral(resourceName: "Play"))
        taskStartButton.backgroundColor = colors.main //appData.appColor
        
    }
    
    /* Starts or stops scheduledTimer and notifications */
    @IBAction func taskButtonTapped(_ sender: UIButton) {
        
        let mainVC = self.navigationController?.viewControllers.first as! TaskViewController

        let (_, remainingTime) = timer.formatTimer(for: task)

        if timer.isEnabled != true {
            task.isRunning = true
            timer.isEnabled = true
            
            rolloverButton(is: .hidden)
            
            setImage(as: #imageLiteral(resourceName: "Pause"))
            
            timer.startTime = Date().timeIntervalSince1970
            
            timer.run = Timer.scheduledTimer(timeInterval: 1.0, target: self,
                                             selector: #selector(timerRunning), userInfo: nil, repeats: true)
            
            timer.setFinishedNotification(for: task, atTime: remainingTime)

            /* Add the current VC to the array so that we can then load
               the correct intance of the VC when returning */
            mainVC.runningTaskVCs.append(self)
            
        } else {
            
            if task.rollover > 0 && remainingTime > task.time {
                rolloverButton(is: .visible)
            }
            
            taskHasStopped()
            timerStopped()
            
            setImage(as: #imageLiteral(resourceName: "Play"))

            NotificationCenter.default.post(name: Notification.Name("StopTimerNotification"), object: nil)
            timer.cancelFinishedNotification(for: task.name)

            // Remove the instance from the VC array since the timer was stopped
            if let index = mainVC.runningTaskVCs.index(of: self) {
                mainVC.runningTaskVCs.remove(at: index)
            }

            if mainVC.willResetTasks {
                mainVC.resetTaskTimers()
            }
            
        }
        
    }
    
    @IBAction func resetRolloverTapped(_ sender: UIButton) {
        popAlert(forType: .reset)
    }
    
    @objc func settingsTapped() {
        
        print("Go to Settings")
        presentTaskSettingsVC()
        
    }

    @objc func statsTapped() {
        
//        if appData.isFullVersion {
//            print("Go to Stats")
        navigationController?.toolbar.isHidden = true
            performSegue(withIdentifier: "taskStatsSegue", sender: self)
//        } else {
//            popAlert(forType: .upgradeNeeded)
//        }
    }

    @objc func trashTapped() {
        
        print("Erase Task")
        popAlert(forType: .delete)
    }
    
    func rolloverButton(is visible: Visible) {
        let isHidden = !(visible == .visible)
        UIView.animate(withDuration: 0.5, animations: {
            self.resetRolloverButton.isHidden = isHidden
            self.resetRolloverButton.alpha = isHidden ? 0:1
        })

        
    }
    
    func popAlert(forType type: AlertType) {
        
        let title: String
        let message: String
        
        if type == .delete {
            title = "Delete Task"
            message = "Are you sure you want to delete this?"
        } else if type == .upgradeNeeded {
            title = "Restricted"
            message = "Task statistics unlocked after purchase"
        } else if type == .reset {
            title = "Reset Timer"
            message = "Are you sure you want to reset the timer to its default length?"
        } else {
            title = ""
            message = ""
        }
        
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: UIAlertControllerStyle.alert)
        
        let yesAction = UIAlertAction(title: "Yes", style: .default){ (action: UIAlertAction) in
            print("Hello")
            self.performSegue(withIdentifier: "taskDeletedUnwindSegue", sender: self)
        }
        let noAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        let resetAction = UIAlertAction(title: "Yes", style: .default){ (action:
            UIAlertAction) in
            print("Resetting rollover")
            self.task.forfeitAccumulatedTime()
            self.formatTimer()
            self.saveData()
            self.rolloverButton(is: .hidden)
        }
        
        if type == .delete {
            alertController.addAction(yesAction)
            alertController.addAction(noAction)
        } else if type == .reset {
            alertController.addAction(resetAction)
            alertController.addAction(noAction)
        } else {
            alertController.addAction(okAction)
        }
        
        present(alertController,animated: true,completion: nil)
        
    }
    
    //MARK: - Chart Functions
    
    /*  */
    func findNewIndex(compare today: [Int], to dayArray: [Int]) -> Int {
        
        var arrayNewIndex: Int = 0
        let todayIndex = today.index(of: 1)
        
        for x in 0...today.count - 1 {
            
            if today[x] == dayArray[x] {
                arrayNewIndex = x
            }
        }
        
        if arrayNewIndex == 0 {
            
            for x in (0...todayIndex!).reversed() {
                
                if dayArray[x] == 1 {
                    arrayNewIndex = x
                    break
                }
                
            }
            
            for x in (todayIndex!...today.count - 1).reversed() {
                
                if dayArray[x] == 1 {
                    arrayNewIndex = x
                    break
                }
                
            }
            
        }
        

        return arrayNewIndex
        
    }
    
    /*  Lengthy, but sets up the chart */
    func taskChartSetup() {
        
        recentTaskHistory.chartDescription?.enabled = false
        recentTaskHistory.legend.enabled = false
        recentTaskHistory.xAxis.labelPosition = .bottom
        
        recentTaskHistory.scaleXEnabled = false
        recentTaskHistory.scaleYEnabled = false
        
        //recentTaskHistory.drawValueAboveBarEnabled = false
        //recentTaskHistory.borderLineWidth = 1.5
        //recentTaskHistory.borderColor = UIColor.flatBlackDark
        
        recentTaskHistory.rightAxis.enabled = false
        recentTaskHistory.leftAxis.enabled = false
        recentTaskHistory.drawGridBackgroundEnabled = false
        
        let leftAxis = recentTaskHistory.getAxis(.left)
        let rightAxis = recentTaskHistory.getAxis(.right)
        let xAxis = recentTaskHistory.xAxis
        
        leftAxis.drawLabelsEnabled = false
        rightAxis.drawLabelsEnabled = true
        
        leftAxis.axisMinimum = 0.0
        rightAxis.axisMinimum = 0.0
        
        let yAxisFormatter = NumberFormatter()
        yAxisFormatter.minimumFractionDigits = 0
        yAxisFormatter.maximumFractionDigits = 1
        yAxisFormatter.positiveSuffix = " min"
        
        rightAxis.valueFormatter = yAxisFormatter as? IAxisValueFormatter
        
        xAxis.granularity = 1.0
        xAxis.drawGridLinesEnabled = false
        xAxis.centerAxisLabelsEnabled = false
        
        let darkerThemeColor = colors.darkMain //appData.appColor.darken(byPercentage: 0.25)
        if appData.darknessCheck(for: view.backgroundColor) {
            xAxis.labelTextColor = .white
            rightAxis.labelTextColor = .white
            recentTaskHistory.noDataTextColor = .white
        } else {
            xAxis.labelTextColor = .black
            rightAxis.labelTextColor = .black
            recentTaskHistory.noDataTextColor = .black
        }

        var recentAccess: [Date]?
        
        /*  Only show up to the most recent 3 dates and set as xAxis labels */
        if task.previousDates.count > 3 {
            recentAccess = Array( task.previousDates.suffix(3))
        } else {
            recentAccess =  task.previousDates
        }
        
        var recentAccessStringArray: [String] = []
        
        for x in 0..<recentAccess!.count {
            let date = recentAccess![x]
            let formattedDate = task.set(date: date, as: "yyyy-MM-dd")
            recentAccessStringArray.append(formattedDate)
        }
        
        xAxis.valueFormatter = IndexAxisValueFormatter(values: recentAccessStringArray)
        
        axisMaximum = 0.0
        
        for date in recentAccess! {
            
            let nextValue = task.completedTimeHistory[date]! / 60
            
            if nextValue > axisMaximum {
                axisMaximum = nextValue
            }
            
        }
        
        leftAxis.axisMaximum = axisMaximum + 5.0
        rightAxis.axisMaximum = leftAxis.axisMaximum

        loadChartData()
        
    }
    
    /*  This function sets the actual bar data values
        past data taken from task history vars
        while tasks that will run today are taken from the elapsedTime var */
    func loadChartData(willUpdate: Bool = false) {
        
        var barChartEntry  = [BarChartDataEntry]() //this is the Array that will eventually be displayed on the graph.
        
        var taskAccess: [Date]?
        
        let dates = task.previousDates

        if dates.count >= 1 {
        
            let access = task.previousDates
            
            if access.count > 3 {
                taskAccess = Array(access.suffix(3))
            } else {
                taskAccess = access
            }

            /* This array holds the time of the most recent completed times in minutes */
            var taskTimeHistory = [Double]()
            
            for date in taskAccess! {
                let completedTime = task.completedTimeHistory[date]
                let completedInMinutes = completedTime! / 60
                //let completedTime = taskData.taskHistoryDictionary[task]![date]![TaskData.completedHistoryKey]
                taskTimeHistory.append(completedInMinutes)
            }
            
            /* T*/
            for i in 0..<taskTimeHistory.count {
                
                var value: BarChartDataEntry
                if i < taskTimeHistory.count - 1  || !task.isToday{
                    // here we set the X and Y status in a data chart entry
                    value = BarChartDataEntry(x: Double(i), y: taskTimeHistory[i])
                } else {
                    let time = elapsedTime / 60
                    value = BarChartDataEntry(x: Double(i), y: time)
                }
                
                barChartEntry.append(value) // here we add it to the data set
            }
            
            let bar = BarChartDataSet(values: barChartEntry, label: "")
            
            bar.colors = ChartColorTemplates.pastel()
            
            let darkerThemeColor = colors.darkMain //appData.appColor.darken(byPercentage: 0.25)
            if appData.darknessCheck(for: view.backgroundColor) {
                bar.valueColors = [UIColor.white]
            } else {
                bar.valueColors = [UIColor.black]
            }

            let data = BarChartData() //This is the object that will be added to the chart
            
            data.addDataSet(bar) //Adds the line to the dataSet
            data.setValueFormatter(self)
            
            if taskAccess?.count == 1 {
                data.barWidth = 0.4
            }
            
            if !willUpdate {
                recentTaskHistory.animate(xAxisDuration: 2.0, yAxisDuration: 2.0)
            }
            
            if elapsedTime > axisMaximum {
                let leftAxis = recentTaskHistory.getAxis(.left)
                let rightAxis = recentTaskHistory.getAxis(.right)
                
                leftAxis.resetCustomAxisMax()
                rightAxis.resetCustomAxisMax()
            }
            
            recentTaskHistory.data = data //finally - it adds the chart data to the chart and causes an update

        } else {
            recentTaskHistory.data = nil

        }
        
    }
    
    //MARK: - Data Handling
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "taskDeletedUnwindSegue" {
            
            let vc = segue.destination as! TaskViewController
            vc.taskNames = vc.taskNames.filter { $0 != task.name }
            print(" Deleting \(vc.tasks)")
            
            let index = vc.tasks.index(of: task)
            vc.tasks.remove(at: index!)
            
        } else if segue.identifier == "taskSettingsSegue" {
            
            let vc = segue.destination as! TaskSettingsViewController
            
            vc.task = task
            vc.appData = appData
            
        } else if segue.identifier == "taskStatsSegue" {
            
            let vc = segue.destination as! TaskStatsViewController
            
            vc.task = task
            vc.appData = appData
            
        }
        
    }
    
    func saveData() {
        
        //appData.save()

        let index = tasks.index(of: task)
        tasks[index!] = task
        
        let data = DataHandler()
        data.saveTasks(tasks)
        data.saveAppSettings(appData)
        
    }

    // MARK: - Navigation

    func presentTaskSettingsVC() {
        let taskSettingsVC = self.storyboard?.instantiateViewController(withIdentifier: "TaskSettingsVC") as! TaskSettingsViewController

        taskSettingsVC.task = task
        taskSettingsVC.appData = appData
        
        taskSettingsVC.taskNames = taskNames

        switch appData.deviceType {
        case .legacy:
            preparePresenter(ofHeight: 0.9, ofWidth: 0.9)
        case .normal:
            preparePresenter(ofHeight: 0.8, ofWidth: 0.8)
        case .large:
            preparePresenter(ofHeight: 0.6, ofWidth: 0.8)
        case .X:
            preparePresenter(ofHeight: 0.6, ofWidth: 0.8)
        }
        
        // Stop the task if it is currently running
        if timer.isEnabled {
            timer.run.invalidate()
            setImage(as: #imageLiteral(resourceName: "Play"))
            
            timerStopped()
            taskHasStopped()
            
            let mainVC = self.navigationController?.viewControllers.first as! TaskViewController
            let (_, remainingTime) = timer.formatTimer(for: task)
            
            if task.rollover > 0 && remainingTime > task.time {
                rolloverButton(is: .visible)
            }
            
            NotificationCenter.default.post(name: Notification.Name("StopTimerNotification"), object: nil)
            timer.cancelFinishedNotification(for: task.name)
            
            // Remove the instance from the VC array since the timer was stopped
            if let index = mainVC.runningTaskVCs.index(of: self) {
                mainVC.runningTaskVCs.remove(at: index)
            }
            
            if mainVC.willResetTasks {
                mainVC.resetTaskTimers()
            }
        }

        customPresentViewController(addPresenter, viewController: taskSettingsVC, animated: true, completion: nil)
    }
    
    func preparePresenter(ofHeight height: Float, ofWidth width: Float) {
        let width = ModalSize.fluid(percentage: width)
        let height = ModalSize.fluid(percentage: height)
        let center = ModalCenterPosition.center
        let customType = PresentationType.custom(width: width, height: height, center: center)
        
        addPresenter.presentationType = customType
        
    }
    
    @IBAction func editTaskUnwind(segue: UIStoryboardSegue) {
        print("Task edited")
        saveData()
    }

}

// MARK: - Bar Value Formatter
extension TaskDetailViewController: IValueFormatter {
    
    func stringForValue(_ value: Double,
                        entry: ChartDataEntry,
                        dataSetIndex: Int,
                        viewPortHandler: ViewPortHandler?) -> String {
        
        var stringValue = ""
        
        // Use if not dividing when setting up chart
//        if value >= 60 {
//            let minutes = String(Int(value/60))
//            stringValue = minutes + "m "
//        }
//
//        let seconds = String(Int(value.truncatingRemainder(dividingBy: 60)))
//        stringValue = seconds + "s"
        
        var time = value
        if time >= 1 {
            let minutes = String(Int(value))
            stringValue = minutes + "m "
            time -= Double(Int(time))
        }
        
        let seconds = String(Int(time*60))
        stringValue += seconds + "s"

        return stringValue
    }
}
