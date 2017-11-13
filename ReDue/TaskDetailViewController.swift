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
    @IBOutlet weak var recentTaskHistory: BarChartView!
    @IBOutlet weak var bannerView: GADBannerView!
    @IBOutlet weak var recentProgressLabel: UILabel!

    //MARK: - Properties
    
    //var timer = Timer()

    var taskNames = [String]()
    var tasks = [Task]()
    var task = Task()
    
    var elapsedTime = 0.0
    
    var timeString: String = ""
    
    var dayOfWeekString = ""
    
    var axisMaximum = 0.0
    
    //var taskData = TaskData()
    var appData = AppData()
    @objc var timer = CountdownTimer()
    
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
    
    //MARK: - View and Basic Functions
    
    override func viewWillAppear(_ animated: Bool) {
 
        self.title = task.name
        navigationController?.toolbar.isHidden = false
        prepareNavBar()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startButtonSetup()

        if !appData.isFullVersion {
            bannerView.adUnitID = "ca-app-pub-3446210370651273/3283732299"
            bannerView.rootViewController = self
            let request = GADRequest()
            request.testDevices = [kGADSimulatorID]
            bannerView.load(request)
        }
        elapsedTime = task.completed
        
        taskChartSetup()
        
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
        
        self.addObserver(self, forKeyPath: #keyPath(timer.elapsedTime), options: .new, context: nil)
        
        if timer.isEnabled && task.isRunning {

            taskStartButton.setImage(#imageLiteral(resourceName: "Pause"), for: .normal)
            let stencil = #imageLiteral(resourceName: "Pause").withRenderingMode(.alwaysTemplate)
            taskStartButton.setImage(stencil, for: .normal)
            taskStartButton.tintColor = UIColor.white

            //taskTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self,
            //                                 selector: #selector(timerRunning), userInfo: nil,
            //                                 repeats: true)
            
        }
        
        let taskIndex = taskNames.index(of: task.name)
        taskNames.remove(at: taskIndex!)

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        //timer.invalidate()
        
        let vc = self.navigationController?.viewControllers.first as! TaskViewController
        
        if timer.isEnabled && task.isRunning {
            
            //vc.taskData.taskDictionary[task]?["completedTime"] = completedTime
            vc.runningCompletionTime = task.completed
            
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        //timer.invalidate()
        
    }

    deinit {
        self.removeObserver(self, forKeyPath: #keyPath(timer.elapsedTime))
        //timer.invalidate()
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
    
    func taskDayCheck(for task: Task) -> Bool {
        
        let now = Date()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        
        dayOfWeekString = dateFormatter.string(from: now)
        print("Today is \(dayOfWeekString)")
        
        return task.days.contains(dayOfWeekString) //taskData.taskDays.contains(dayOfWeekString)
        
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

        //if keyPath == #keyPath(taskData.completedTime) {
            // Update Time Label
        //_ = synchedTimer(for: change![NSKeyValueChangeKey.newKey] as! Double)
        formatTimer()
        
        //}
    }
    
    func synchedTimer(for completedTime: Double) -> String {
        
        let remainingTime = task.weightedTime - task.completed
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        
        let remainingTimeAsString = formatter.string(from: TimeInterval(remainingTime))!
        
        if remainingTime != 0 {
            taskTimeLabel.text = remainingTimeAsString
            taskStartButton.isEnabled = true
        } else {
            taskTimeLabel.text = "Complete"
            taskStartButton.isEnabled = false
        }
        
        return remainingTimeAsString

    }
    
    func getRemainingTime() -> Double {
        
        let currentTime = Date().timeIntervalSince1970
        elapsedTime = task.completed
        
        if timer.isEnabled && task.isRunning {
            elapsedTime += (currentTime - timer.startTime)
        }
        
        return task.weightedTime - elapsedTime

    }
    
    func formatTimer() {
        // Used for initialization and when the task timer is updated
        
        let remainingTime = getRemainingTime()
        
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        
        if remainingTime < 60 {
            formatter.allowedUnits = [.minute, .second]
            formatter.zeroFormattingBehavior = .pad
        } else {
            formatter.allowedUnits = [.hour, .minute, .second]
            formatter.zeroFormattingBehavior = .default
        }

        let remainingTimeAsString = formatter.string(from: TimeInterval(remainingTime.rounded()))!
        
        if remainingTime > 0 {
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
    
    func completedTimeCheck() {
        
        print("Completed time is \(task.completedTime)")
        
    }
    
    @objc func timerRunning() {
        
        let timeRemaining = getRemainingTime()
        formatTimer()
        
        print("Time remaining is \(timeRemaining)")
        print("Elapsed is \(elapsedTime)")
        print("Combination is \(timeRemaining + elapsedTime)")

        if timeRemaining <= 0 || (task.completed == task.weightedTime) {
            
            timerStopped() //(for: task.name)
            
            let stencil = #imageLiteral(resourceName: "Play").withRenderingMode(.alwaysTemplate)
            taskStartButton.setImage(stencil, for: .normal)
            taskStartButton.tintColor = UIColor.white
            
            //taskStartButton.setImage(#imageLiteral(resourceName: "Play"), for: .normal)
            
        }
    }
    
    func timerStopped() { //for taskName: String) {
        
        timer.run.invalidate()
        
        timer.endTime = Date().timeIntervalSince1970
        
        var elapsedTime = timer.endTime - timer.startTime
        
        if elapsedTime > task.weightedTime {
            elapsedTime = task.weightedTime
        }
        
        task.completed += elapsedTime
        //taskData.taskDictionary[task]![TaskData.completedTimeKey]! += elapsedTime
        
        if let date = task.getAccessDate(lengthFromEnd: 0) {
            task.completedTimeHistory[date]! += elapsedTime
            //taskData.taskHistoryDictionary[task]![date]![TaskData.completedHistoryKey]! += elapsedTime
            
            let unfinishedTime = task.time - elapsedTime
            
            if unfinishedTime >= 0 {
                task.missedTimeHistory[date] = unfinishedTime
                //taskData.taskHistoryDictionary[task]![date]![TaskData.missedHistoryKey]! = unfinishedTime
            } else {
                task.missedTimeHistory[date] = 0
                //taskData.taskHistoryDictionary[task]![date]![TaskData.missedHistoryKey]! = 0.0
            }
            //setMissedTime(for: task, at: date)
            
        }
        
        task.isRunning = false
        timer.isEnabled = false
        timer.firedFromMainVC = false
        
        saveData()
        
    }
    
    func setTheme() {
        
        if appData.isNightMode {
            //NightNight.theme = .night
        } else {
            //NightNight.theme = .normal
        }
        
        let navigationBar = navigationController?.navigationBar
        let bgColor = navigationBar?.barTintColor
        
        let darkerThemeColor = appData.appColor.darken(byPercentage: 0.25)
        view.backgroundColor = darkerThemeColor

        if appData.darknessCheck(for: bgColor) {
            navigationBar?.tintColor = .white
            navigationBar?.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
            setStatusBarStyle(.lightContent)
        } else {
            navigationBar?.tintColor = .black
            navigationBar?.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.black]
            setStatusBarStyle(.default)
        }
        
        if appData.darknessCheck(for: darkerThemeColor) {
            taskTimeLabel.textColor = .white
            recentProgressLabel.textColor = .white
        } else {
            taskTimeLabel.textColor = .black
            recentProgressLabel.textColor = .black
        }
        
    }

    //MARK: - Button Related Functions
    
    func startButtonSetup() {
        
        taskStartButton.layer.cornerRadius = 10.0
        taskStartButton.layer.masksToBounds = true
        
        taskStartButton.layer.shadowColor = UIColor.lightGray.cgColor
        taskStartButton.layer.shadowOffset = CGSize.zero
        taskStartButton.layer.shadowRadius = 2.0
        taskStartButton.layer.shadowOpacity = 2.0
        taskStartButton.layer.shadowPath = UIBezierPath(roundedRect: taskStartButton.layer.bounds, cornerRadius: taskStartButton.layer.cornerRadius).cgPath
        
        //taskStartButton.setImage(#imageLiteral(resourceName: "Play"), for: .normal)
        let stencil = #imageLiteral(resourceName: "Play").withRenderingMode(.alwaysTemplate)
        taskStartButton.setImage(stencil, for: .normal)
        taskStartButton.tintColor = UIColor.white
        taskStartButton.backgroundColor = appData.appColor
        
    }
    
    @IBAction func taskButtonTapped(_ sender: UIButton) {
        
        if timer.isEnabled != true {
            task.isRunning = true
            timer.isEnabled = true
            
            let stencil = #imageLiteral(resourceName: "Pause").withRenderingMode(.alwaysTemplate)
            taskStartButton.setImage(stencil, for: .normal)
            taskStartButton.tintColor = UIColor.white
            
            //taskStartButton.setImage(#imageLiteral(resourceName: "Pause"), for: .normal)
            
            timer.startTime = Date().timeIntervalSince1970
            
            timer.run = Timer.scheduledTimer(timeInterval: 1.0, target: self,
                                             selector: #selector(timerRunning), userInfo: nil, repeats: true)
            
            let (_, remainingTime) = timer.formatTimer(for: task)
            timer.setFinishedNotification(for: task.name, atTime: remainingTime)

        } else {
            
            timerStopped() //(for: task.name)
            
            let stencil = #imageLiteral(resourceName: "Play").withRenderingMode(.alwaysTemplate)
            taskStartButton.setImage(stencil, for: .normal)
            taskStartButton.tintColor = UIColor.white
            //taskStartButton.setImage(#imageLiteral(resourceName: "Play"), for: .normal)
            
            NotificationCenter.default.post(name: Notification.Name("StopTimerNotification"), object: nil)
            timer.cancelFinishedNotification(for: task.name)
            
            
//            if willResetTimer {
//                resetTaskTimers()
//            }
            
        }
        
    }
    
    @objc func settingsTapped() {
        
        print("Go to Settings")
        presentTaskSettingsVC()
        
    }

    @objc func statsTapped() {
        
        if appData.isFullVersion {
            print("Go to Stats")
            performSegue(withIdentifier: "taskStatsSegue", sender: self)
        } else {
            popAlert(forType: .upgradeNeeded)
        }
    }

    @objc func trashTapped() {
        
        print("Erase Task")
        popAlert(forType: .delete)
    }
    
    func popAlert(forType type: AlertType) {
        
        let title: String
        let message: String
        
        if type == .delete {
            title = "Delete Task"
            message = "Are you sure you want to delete this?"
        } else {
            title = "Restricted"
            message = "Task statistics unlocked after purchase"
        }
        
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: UIAlertControllerStyle.alert)
        
        let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default){ (action: UIAlertAction) in
            print("Hello")
            self.performSegue(withIdentifier: "taskDeletedUnwindSegue", sender: self)
        }
        let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.cancel, handler: nil)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
        
        if type == .delete {
            alertController.addAction(yesAction)
            alertController.addAction(noAction)
        } else {
            alertController.addAction(okAction)
        }
        
        present(alertController,animated: true,completion: nil)
        
    }
    
    //MARK: - Chart Functions
    
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
    
    func taskChartSetup() {
        
        recentTaskHistory.chartDescription?.enabled = false
        recentTaskHistory.legend.enabled = false
        recentTaskHistory.xAxis.labelPosition = .bottom
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
        
        let darkerThemeColor = appData.appColor.darken(byPercentage: 0.25)
        if appData.darknessCheck(for: darkerThemeColor) {
            xAxis.labelTextColor = UIColor.white
            rightAxis.labelTextColor = UIColor.white
        } else {
            xAxis.labelTextColor = UIColor.black
            rightAxis.labelTextColor = UIColor.black
        }

        var recentAccess: [Date]?
        
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
            //let nextValue = taskData.taskHistoryDictionary[task]![date]![TaskData.completedHistoryKey]
            
            if nextValue > axisMaximum {
                axisMaximum = nextValue
            }
            
        }
        
        leftAxis.axisMaximum = axisMaximum + 5.0
        rightAxis.axisMaximum = leftAxis.axisMaximum

        loadChartData()
        
    }
    
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

            var taskTimeHistory = [Double]()
            
            for date in taskAccess! {
                
                let completedTime = task.completedTimeHistory[date]
                let completedInMinutes = completedTime! / 60
                //let completedTime = taskData.taskHistoryDictionary[task]![date]![TaskData.completedHistoryKey]
                taskTimeHistory.append(completedInMinutes)
                
            }
            
            for i in 0..<taskTimeHistory.count {
                
                var value: BarChartDataEntry
                if i < taskTimeHistory.count - 1  || !task.isToday{
                    value = BarChartDataEntry(x: Double(i), y: taskTimeHistory[i]) // here we set the X and Y status in a data chart entry
                } else {
                    let time = elapsedTime.rounded() / 60
                    value = BarChartDataEntry(x: Double(i), y: time)
                }
                
                barChartEntry.append(value) // here we add it to the data set
            }
            
            let bar = BarChartDataSet(values: barChartEntry, label: "") //Here we convert lineChartEntry to a LineChartDataSet
            
            bar.colors = ChartColorTemplates.pastel()
            
            let darkerThemeColor = appData.appColor.darken(byPercentage: 0.25)
            if appData.darknessCheck(for: darkerThemeColor) {
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
        
        appData.save()

        let index = tasks.index(of: task)
        tasks[index!] = task
        
        let data = DataHandler()
        data.save(tasks)
        
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
            preparePresenter(ofHeight: 0.7, ofWidth: 0.8)
        case .X:
            preparePresenter(ofHeight: 0.7, ofWidth: 0.8)
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
