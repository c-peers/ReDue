//
//  ViewController.swift
//  RepeatingTasks
//
//  Created by Chase Peers on 6/13/17.
//  Copyright © 2017 Chase Peers. All rights reserved.
//

import Foundation
import UIKit
import Chameleon
import GoogleMobileAds
import Presentr
import SwiftyBeaver

enum CellType {
    case circular
    case line
}

class TaskViewController: UIViewController, GADBannerViewDelegate {

    //MARK: - Outlets
    
    @IBOutlet weak var taskList: UICollectionView!
    @IBOutlet weak var bannerView: GADBannerView!
    @IBOutlet weak var adView: UIView!
    @IBOutlet weak var bannerHeight: NSLayoutConstraint!
    
    //MARK: - Properties
    
    var taskNames = [String]()
    
    @objc dynamic var tasks = [Task]()
    var appData = AppData()
    //var timer = CountdownTimer()
    var check = Check()
    
    var secondaryTimer = Timer()
    
    var timerFiringFromTaskVC = false
    
    var selectedTask: Task?
    var selectedCell: TaskCollectionViewCell?
    var runningCompletionTime = 0.0
    
    var willResetTasks = false
    var now = Date()
    var yesterday = Date()
    var lastUsed = Date()
    
    var nextResetTime = Date()
    
    let log = SwiftyBeaver.self

    lazy var adBannerView: GADBannerView = {
        let adBannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        adBannerView.adUnitID = "ca-app-pub-3446210370651273/5359231299"
        adBannerView.delegate = self
        adBannerView.rootViewController = self

        return adBannerView
    }()
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load any saved data
        loadData()
        
        print("loaded Values")
        print(tasks)
        
        log.info("loaded Tasks")
        log.info(tasks)
        
        initializeCheck()
        
        appData.taskCurrentTime = Date()
        
        NotificationCenter.default.addObserver(forName: Notification.Name("StopTimerNotification"), object: nil, queue: nil, using: catchNotification)
        
        prepareNavBar()
        
        if !appData.isFullVersion {
            adView.alpha = 0
            let request = GADRequest()
            request.testDevices = [kGADSimulatorID]
            adBannerView.load(request)
        }
        
        // Check current time
        // Determine the time interval between now and when the timers will reset
        // Set a timer to go off at that time
        
        for task in tasks {
            if check.changeOfWeek(between: lastUsed, and: now) {
                
                let frequency = task.frequency
                let lastRunWeek = task.runWeek
                let nextRunWeek = lastRunWeek + Int(frequency)

                if check.currentWeek == nextRunWeek {
                    task.runWeek = nextRunWeek
                }

            }
            
            check.ifTaskWillRunToday(task)
            
        }
        
        timeCheck()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        print("Main - viewWillAppear")
        appData.setColorScheme()
        setTheme()
        
        if appData.isFullVersion {
            bannerHeight.constant = 0
        }
        
        // Circular progress cells were using the incorrect cell size, reason unknown.
        // This forces the cells to use the correct size
        //        if appData.usesCircularProgress {
        //            setCellSize(forType: .circular)
        //        } else {
        //            setCellSize(forType: .line)
        //        }
        
        if runningCompletionTime > 0, let task = selectedTask {
            if task.isRunning {
                //task.completedTime = runningCompletionTime
            }
        }
        
        //DispatchQueue.main.async {
        //    self.taskList.collectionViewLayout.invalidateLayout()
        //    self.taskList.reloadData()
        //}
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        print("Main - viewDidAppear")

        guard let taskCells = getTaskCells() else { return }
        
        for cell in taskCells {
            
            guard let task = selectedTask else { return }
            
            if cell.timer.isEnabled && !cell.timer.firedFromMainVC && task.isRunning {
                
                let currentTime = Date().timeIntervalSince1970
                let timeElapsed = currentTime - cell.timer.startTime
                print("time elapsed \(timeElapsed)")
                
                log.debug("time elapsed \(timeElapsed)")
                
                let wholeNumbers = floor(timeElapsed)
                let milliseconds = Int((timeElapsed - wholeNumbers) * 1000)
                
                DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .milliseconds(milliseconds)) {
                    
                    print("Wait until next second begins")
                    
                }
                
                let indexPathRow = taskNames.index(of: selectedTask!.name)
                let indexPath = IndexPath(row: indexPathRow!, section: 0)
                selectedCell = taskList.cellForItem(at: indexPath) as? TaskCollectionViewCell
                
                _ = cell.formatTimer(for: selectedTask!)
                
                //secondaryTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self,
                //                                      selector: #selector(TaskCollectionViewCell.timerRunning),
                //                                      userInfo: nil,
                //                                      repeats: true)
                
            } else {
                //secondaryTimer.invalidate()
            }
            
        }
        
    }
    
    func initializeCheck() {
        check.appData = appData
    }
    
    func getTaskCells() -> [TaskCollectionViewCell]? {

        var cells = [TaskCollectionViewCell]()
        
        if tasks.count < 1 {
            return nil
        }
        
        for row in 0..<tasks.count {
            if let cell = taskList.cellForItem(at: IndexPath(row: row, section: 0)) as? TaskCollectionViewCell {
                cells.append(cell)
            }
        }
        
        return cells

    }
    
    func prepareNavBar() {
        
        let addBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTask))
        navigationItem.rightBarButtonItems = [addBarButton]
        
        let settingsButton = UIBarButtonItem(image: #imageLiteral(resourceName: "Settings"), style: .plain, target: self, action: #selector(settingsButtonTapped))
        toolbarItems = [settingsButton]
        navigationController?.isToolbarHidden = false
        
        setTheme()
        
    }
    
    func setTheme() {
        
        let navigationBar = navigationController?.navigationBar
        navigationBar?.barTintColor = appData.appColor
        //navigationBar?.mixedBarStyle = MixedBarStyle(normal: .default, night: .blackTranslucent)
        
        let toolbar = navigationController?.toolbar
        toolbar?.barTintColor = appData.appColor
        
        let darkerThemeColor = appData.appColor.darken(byPercentage: 0.25)
        
        view.backgroundColor = darkerThemeColor //FlatWhite()
        taskList.backgroundColor = .clear
        taskList.backgroundView = UIView(frame: .zero)
        //taskList.backgroundView?.backgroundColor = darkerThemeColor //FlatWhite() //darkerThemeColor
        
        if appData.isNightMode {
            //NightNight.theme = .night
        } else {
            //NightNight.theme = .normal
        }
        
        let bgColor = navigationController?.navigationBar.barTintColor
        
        if appData.darknessCheck(for: bgColor) {
            
            navigationBar?.tintColor = UIColor.white
            toolbar?.tintColor = UIColor.white
            setStatusBarStyle(.lightContent)
           
        } else {
            
            navigationBar?.tintColor = UIColor.black
            toolbar?.tintColor = UIColor.black
            setStatusBarStyle(.default)
        }
        
    }
    
    func setImage(as image: UIImage, forCell cell: TaskCollectionViewCell) {
        let stencil = image.withRenderingMode(.alwaysTemplate)
        cell.playStopButton.setImage(stencil, for: .normal)
        cell.playStopButton.tintColor = FlatWhite() //appData.appColor
        
        cell.buttonBackground.alpha = 0.0
        
//        var playBackground = image.resizeImageWith(ratio: 1.2)
//
//        let backgroundStencil = playBackground.withRenderingMode(.alwaysTemplate)
//
//        cell.buttonBackground.image = backgroundStencil
//        cell.buttonBackground.tintColor = appData.appColor
//        //cell.buttonBackground.alpha = 0.5
//        cell.buttonBackground.addSubview(cell.playStopButton)
//
//        let cellBGColor = cell.backgroundColor
//        if appData.darknessCheck(for: cellBGColor) {
//            cell.playStopButton.tintColor = .white
//        } else {
//            cell.playStopButton.tintColor = .black
//        }
        
    }
    
    func setTask(as task: String) -> Task {
        return tasks.first(where: { $0.name == task })!
    }
    
    func catchNotification(notification:Notification) -> Void {
        print("Catch notification")
        log.debug("Catch notification")
        //timer.run.invalidate()
        
    }
    
    //MARK: - Timer Related Functions
    
    @objc func timerRunningUnused() {
        
        let cell = selectedCell!
        let taskName = cell.taskNameField.text!
        let task = setTask(as: taskName)
        let id = cell.reuseIdentifier
        
        let (_, timeRemaining) = cell.formatTimer(for: task)
        print("Time remaining is \(timeRemaining)")
        log.debug("Time remaining is \(timeRemaining)")
        
        if id == "taskCollectionCell_Line" {
            calculateProgress(for: cell, ofType: .line)
        }
        
        if timeRemaining <= 0 {
            
            if id == "taskCollectionCell_Line" {
                timerStopped(for: task, ofType: .line)
            } else {
                timerStopped(for: task, ofType: .circular)
            }
            
            cell.taskTimeRemaining.text = "Complete"
            
            setImage(as: #imageLiteral(resourceName: "Play"), forCell: cell)
            cell.playStopButton.isEnabled = false
            
            cell.timer.cancelMissedTimeNotification(for: taskName)
            
        }
        
    }
    
    func timerStopped(for task: Task, ofType type: CellType) {
        
        guard let taskCells = getTaskCells() else { return }
        guard let cell = taskCells.first(where: { $0.taskNameField.text == task.name }) else { return }
        cell.timer.run.invalidate()
        
        cell.timer.endTime = Date().timeIntervalSince1970
        
        var elapsedTime = cell.timer.endTime - cell.timer.startTime
        
        if elapsedTime > task.weightedTime {
            elapsedTime = task.weightedTime
        }
        
        if type == .circular {
            selectedCell?.circleProgressView.pauseAnimation()
        }
        
        task.completed += elapsedTime
        
        if let date = task.getAccessDate(lengthFromEnd: 0) {
            
            task.completedTimeHistory[date]! += elapsedTime
            
            let unfinishedTime = task.time - elapsedTime
            
            if unfinishedTime >= 0 {
                task.missedTimeHistory[date]! = unfinishedTime
            } else {
                task.missedTimeHistory[date]! = 0
            }
            
        }
        
        let resetTime = check.timeToReset(at: nextResetTime)
        
        let (remainingTimeString, _) = cell.formatTimer(for: task)
        cell.timer.setMissedTimeNotification(for: task.name, at: resetTime, withRemaining: remainingTimeString)
        
        task.isRunning = false
        cell.timer.isEnabled = false
        cell.timer.firedFromMainVC = false
        
        saveData()
        
    }

    //MARK: - App Rollover Related Functions
    
    func currentTimeIs() -> Date {
        return check.offsetDate(Date(), by: appData.resetOffset)
    }
    
    func timeCheck() {
        
        // Offset times so that reset always occurs at "midnight" for easy calculation
        now = currentTimeIs()
        let then = check.offsetDate(appData.taskLastTime, by: appData.resetOffset)
        lastUsed = then
        
        let calendar = Calendar.current
        let currentTimeZone = TimeZone.current
        
        var currentTime = getDateComponents(for: now, at: currentTimeZone)
        //var lastAppTime = getDateComponents(for: then, at: currentTimeZone)
        
        var reset = currentTime
//        reset.timeZone = currentTimeZone
//        reset.year = currentTime.year
//        reset.month = currentTime.month
        reset.hour = check.offsetAsInt(for: appData.resetOffset)
        reset.minute = 0
        //reset.minute = calendar.component(.minute, from: appData.taskResetTime)
        
//        if (lastAppTime.year != currentTime.year) || (lastAppTime.month != currentTime.month) {
//            reset.day = currentTime.day
//        } else if lastAppTime.day != currentTime.day {
//            reset.day = currentTime.day! + 1
//        } else {
            reset.day = currentTime.day! + 1
//        }
        
        nextResetTime = calendar.date(from: reset)!
        let lastResetTime = calendar.date(byAdding: .day, value: -1, to: nextResetTime)
        let timeToReset = check.timeToReset(at: nextResetTime)

        let message = "\(timeToReset) sec until reset"
        print(message)
        log.debug(message)

        guard let taskCells = getTaskCells() else { return }
        let resetOccurred = check.resetTimePassed(between: then, and: now, with: lastResetTime!)
        
        if resetOccurred {
        
            log.debug("The reset time period has passed")

            for cell in taskCells {
                if cell.timer.isEnabled {
                    willResetTasks = true
                }
            }

            if !willResetTasks {
                resetTaskTimers()
            }
            
        } else {
            
            log.debug("No reset yet. Next reset at \(timeToReset)")
            
            let resetDate = Date().addingTimeInterval(timeToReset)
            let resetTimer = Timer(fireAt: resetDate, interval: 0, target: self, selector: #selector(resetTaskTimers), userInfo: nil, repeats: false)
            RunLoop.main.add(resetTimer, forMode: RunLoopMode.commonModes)
            
        }
        
        for task in tasks {
            
            if task.isToday {
                if let cell = taskCells.first(where: { $0.taskNameField.text == task.name }) {
                    let (remainingTimeString,_) = cell.formatTimer(for: task)
                    cell.timer.setMissedTimeNotification(for: task.name, at: timeToReset, withRemaining: remainingTimeString)
                }
            }
            
        }

        appData.taskLastTime = appData.taskCurrentTime
        let data = DataHandler()
        data.saveAppSettings(appData)

    }
    
    func getDateComponents(for date: Date, at timeZone: TimeZone) -> DateComponents {
        
        let calendar = Calendar.current
        var time = DateComponents()
        time.year = calendar.component(.year, from: date)
        time.month = calendar.component(.month, from: date)
        time.day = calendar.component(.day, from: date)
        time.hour = calendar.component(.hour, from: date)
        time.minute = calendar.component(.minute, from: date)
        time.second = calendar.component(.second, from: date)
        time.timeZone = timeZone
        
        return time

    }
    
    func date(for day: Date, withOffset offset: Int) -> Date {
        
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: 1, to: day)
        
        return date!
        
    }
    
    @objc func resetTaskTimers() {
        print("RESET!!!!!!!!")
        log.info("Timers will be reset")
        
        // Iterate through all tasks and do the following
        // 1. Reset completed time
        // 2. Calculate rollover time
        // 3. Refresh screen
        
        // No need to run if there aren't any tasks
        if tasks.count < 1 {
            return
        }
        
        for task in tasks {
            
            task.rollover = 0
        
            let now = currentTimeIs()
            let daysBetween = check.daysBetweenTwoDates(start: self.lastUsed, end: now)

            log.debug("\(daysBetween) days between last run")
            
            for i in 0..<daysBetween {
                
                let calendar = Calendar.current
                guard let date = calendar.date(byAdding: .day, value: i, to: self.lastUsed) else {
                    return
                }

                check.runWeek(for: task, at: date)
                
                let wasThatWeek = check.taskWeek(for: task, at: date)
                let wasThatDayofWeek = check.taskDays(for: task, at: date)
                
                if (wasThatWeek && wasThatDayofWeek) {
                    
                    // Popup that shows tasks will be reset
                    let modalView = ModalInfoView()
                    modalView.set(title: "Resetting Tasks")
                    modalView.set(image: #imageLiteral(resourceName: "Reset Arrow"))
                    modalView.set(length: 2)
                    view.addSubview(modalView)
                    modalView.center = view.center

                    let message = "Rollover, Stats, History will be calculated for date \(date)"
                    //popAlert(with: message)
                    log.info(message)
                    
                    task.setRollover()
                    task.calculateStats()
                    task.saveHistory(for: date)
                    task.reset()
                }
                                
            }

            task.rollover = task.weightedTime - task.time
            task.completed = 0
            check.ifTaskWillRunToday(task)
            if task.isToday {
                _ = check.access(for: task, upTo: now)
            }

        }
        
        DispatchQueue.main.async {
            self.taskList.reloadData()
        }

        taskList.reloadData()
        taskList.reloadInputViews()
        saveData()
        
    }

    //MARK: - Button Functions
    
    @objc func addTask() {
        presentNewTaskVC()
    }
    
    @objc func settingsButtonTapped() {
        performSegue(withIdentifier: "appSettingsSegue", sender: self)
    }
    
    //@IBAction func taskStartStopButtonPressed(_ sender: UIButton) {
    @objc func taskStartStopButtonPressed(sender: UIButton) {
        guard let cell = sender.superview?.superview as? TaskCollectionViewCell else {
            return
        }
        
        let id = cell.reuseIdentifier
        
        let taskName = cell.taskNameField.text!
        let task = setTask(as: taskName)
        
        if !cell.timer.isEnabled {
            
            task.isRunning = true
            cell.timer.isEnabled = true
            cell.timer.firedFromMainVC = true
            
            setImage(as: #imageLiteral(resourceName: "Pause"), forCell: cell)
            
            let weightedTime = task.weightedTime
            let elapsedTime = task.completed
            let remainingTime = weightedTime - elapsedTime
            
            if id == "taskCollectionCell_Circle" {
                
                let currentProgress = 1 - remainingTime/weightedTime
                let currentAngle = currentProgress * 360
                
                cell.circleProgressView.animate(fromAngle: currentAngle, toAngle: 359.9, duration: remainingTime as TimeInterval, relativeDuration: true, completion: nil)
            }
            
            cell.timer.startTime = Date().timeIntervalSince1970
            
            selectedCell = cell
            
            cell.timer.setFinishedNotification(for: task.name, atTime: remainingTime)
            cell.timer.run = Timer.scheduledTimer(timeInterval: 1.0, target: cell,
                                                 selector: #selector(TaskCollectionViewCell.timerRunning), userInfo: nil,
                                                 repeats: true)
            
            
        } else {
            
            setImage(as: #imageLiteral(resourceName: "Play"), forCell: cell)
            
            if id == "taskCollectionCell_Circle" {
                timerStopped(for: task, ofType: .circular)
            } else {
                timerStopped(for: task, ofType: .line)
            }
            
            cell.timer.cancelFinishedNotification(for: task.name)
            
            if willResetTasks {
                resetTaskTimers()
            }
            
        }
        
    }
    
   //MARK: - Data Handling
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let taskCells = getTaskCells()

        if segue.identifier == "taskDetailSegue" {
            let taskVC = segue.destination as! TaskDetailViewController
            
            taskVC.appData = appData
            taskVC.task = selectedTask!
            taskVC.tasks = tasks
            taskVC.taskNames = taskNames
            
            guard let cell = taskCells?.first(where: { $0.taskNameField.text == selectedTask!.name }) else { return }
            taskVC.timer = cell.timer
            
        } else if segue.identifier == "addTaskSegue" {
            let newTaskVC = segue.destination as! NewTasksViewController
            
            newTaskVC.appData = appData
            
        } else if segue.identifier == "appSettingsSegue" {
            let appSettingsVC = segue.destination as! AppSettingsViewController
            
            appSettingsVC.appData = appData
            
            guard let cells = taskCells else { return }
            
            for cell in cells {
                if cell.timer.isEnabled {
                    setImage(as: #imageLiteral(resourceName: "Play"), forCell: cell)
                    cell.timer.run.invalidate()
                }
            }
            
        }
        
    }
    
    func loadData() {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appData = appDelegate.appData
        
        print("Appdata color is \(appData.appColor.hexValue())")
        
        let data = DataHandler()
        if let loadedData = data.loadTasks() {
            tasks = loadedData
        }

        getTaskNames()
        
    }
    
    func saveData() {
        
        let data = DataHandler()
        data.saveAppSettings(appData)
        data.saveTasks(tasks)
        //appData.save()

        getTaskNames()
        
    }
    
    func getTaskNames() {
        taskNames.removeAll()
        for task in tasks {
            taskNames.append(task.name)
        }
    }
    
    //MARK: - Ads
    
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {

        print("Banner loaded successfully")
        
        adView.alpha = 1
        adView.addSubview(adBannerView)
        
    }

    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        print("Fail to receive ads")
    }
    
    //MARK: - Navigation
    
    @IBAction func newTaskCreatedUnwind(segue: UIStoryboardSegue) {
        
        saveData()
        
        DispatchQueue.main.async {
            self.taskList.reloadData()
        }
        
    }
    
    @IBAction func taskDeletedUnwind(segue: UIStoryboardSegue) {
        
        // Popup that shows tasks will be reset
//        let modalView = ModalInfoView()
//        modalView.set(title: "”)
//        modalView.set(image: xxxx)
//        modalView.set(length: 2)
//        view.addSubview(modalView)
//        modalView.center = view.center

        print("Baleted")
        print(tasks)
        
        saveData()
        
        DispatchQueue.main.async {
            self.taskList.reloadData()
        }
        
    }
    
    func preparePresenter(ofHeight height: Float, ofWidth width: Float) {
        let width = ModalSize.fluid(percentage: width)
        let height = ModalSize.fluid(percentage: height)
        let center = ModalCenterPosition.center
        let customType = PresentationType.custom(width: width, height: height, center: center)
        
        addPresenter.presentationType = customType
        
    }
    
    func presentNewTaskVC() {
        let newTaskViewController = self.storyboard?.instantiateViewController(withIdentifier: "NewTaskVC") as! NewTasksViewController
        newTaskViewController.appData = appData
        newTaskViewController.tasks = taskNames

        switch appData.deviceType {
        case .legacy:
            preparePresenter(ofHeight: 0.8, ofWidth: 0.9)
        case .normal:
            preparePresenter(ofHeight: 0.8, ofWidth: 0.8)
        case .large:
            preparePresenter(ofHeight: 0.7, ofWidth: 0.8)
        case .X:
            preparePresenter(ofHeight: 0.7, ofWidth: 0.8)
        }

        customPresentViewController(addPresenter, viewController: newTaskViewController, animated: true, completion: nil)
    }
    
}

//MARK: - Collection View Delegate

extension TaskViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    /* UICollectionViewDelegateFlowLayout functions added because the collection cells
       were not automatically resizing. Since the values in IB are ignored they are hardcoded
       the code below.
     */
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let screenWidth = view.bounds.width
        
        let cellSize: CGSize
        
        if appData.usesCircularProgress {
            cellSize = CGSize(width:170 , height:220) // w:170 h:220
        } else {
            cellSize = CGSize(width:screenWidth - 32 , height:106) // w:333 h:106
        }

        return cellSize
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var reuseIdentifier: String?
        let usesCircularProgress = appData.usesCircularProgress
        
        print(indexPath)
        
        if usesCircularProgress {
            reuseIdentifier = "taskCollectionCell_Circle"

            let nib: UINib = UINib(nibName: "TaskCircleProgressCollectionViewCell", bundle: nil)
            
            taskList.register(nib, forCellWithReuseIdentifier: reuseIdentifier!)
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier!, for: indexPath) as! TaskCollectionViewCell

            setupCollectionCell(for: cell, ofType: .circular, at: indexPath)

            collectionView.contentInset = UIEdgeInsets(top: 20, left: 10, bottom: 10, right: 10)

            return cell
            
        } else {
            reuseIdentifier = "taskCollectionCell_Line"

            let nib: UINib = UINib(nibName: "TaskCollectionViewCell", bundle: nil)
            
            taskList.register(nib, forCellWithReuseIdentifier: reuseIdentifier!)
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier!, for: indexPath as IndexPath) as! TaskCollectionViewCell
            
            setupCollectionCell(for: cell, ofType: .line, at: indexPath)
            
            return cell
            
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tasks.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let taskName = taskNames[indexPath.row]
        let task = setTask(as: taskName)
        
        selectedTask = task
        
        print("Selected task is \(task.name)")
        
        performSegue(withIdentifier: "taskDetailSegue", sender: self)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if let cell = cell as? TaskCollectionViewCell {
            //cell.removeObserver()
        }
    }
    
    //MARK: CollectionView Helper Functions
    
    func setBorder(for layer: CALayer, borderWidth: CGFloat, borderColor: CGColor, radius: CGFloat ) {
        layer.borderWidth = borderWidth
        layer.borderColor = borderColor
        layer.cornerRadius = radius
    }
    
    func setCellSize(forType type: CellType) {
        
        let cellSize: CGSize
        
        if type == .line {
            cellSize = CGSize(width:333 , height:106)
        } else {
            cellSize = CGSize(width:170 , height:220)
        }
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = cellSize
        layout.sectionInset = UIEdgeInsets(top: 20, left: 10, bottom: 10, right: 10)
        layout.minimumLineSpacing = 5.0
        layout.minimumInteritemSpacing = 5.0
        taskList.setCollectionViewLayout(layout, animated: true)
        
        //taskList.reloadData()
        
    }
    
    func calculateProgress(for cell: TaskCollectionViewCell, ofType type: CellType) {
        
        let taskName = cell.taskNameField.text!
        let task = setTask(as: taskName)
        
        // Why do I have to do this here???
        // Doesn't work from other classes when using .xib
        let weightedTime = task.weightedTime
        var elapsedTime = task.completed
        if cell.timer.isEnabled {
            elapsedTime += (cell.timer.currentTime - cell.timer.startTime)
        }
        let remainingTime = weightedTime - elapsedTime
        
        if type == .line {
            let currentProgress = 1 - Float(remainingTime)/Float(weightedTime)
            cell.progressView.setProgress(currentProgress, animated: true)
        } else {
            let currentProgress = 1 - remainingTime/weightedTime
            cell.circleProgressView.progress = currentProgress
        }
        
    }
    
    func setupCollectionCell(for cell: TaskCollectionViewCell, ofType type: CellType, at indexPath: IndexPath) {
        
        let taskName = taskNames[indexPath.row]
        let task = setTask(as: taskName)
        
        cell.task = task
        cell.appData = appData
        cell.taskNameField.text = task.name
        cell.mainVC = self
        
        cell.initializeObserver()

        cell.playStopButton.backgroundColor = UIColor.clear
        cell.playStopButton.addTarget(cell, action: #selector(taskStartStopButtonPressed(sender:)), for: .touchUpInside)
        if cell.taskTimeRemaining.text == "Complete" {
            cell.playStopButton.isEnabled = false
        } else {
            cell.playStopButton.isEnabled = true
        }
        
        if cell.timer.isEnabled && task.isRunning, let _ = selectedTask?.name {
            setImage(as: #imageLiteral(resourceName: "Pause"), forCell: cell)
        } else {
            setImage(as: #imageLiteral(resourceName: "Play"), forCell: cell)
        }
        
        //let gradientBackground = GradientColor(.leftToRight, frame: cell.frame, colors: [UIColor.flatSkyBlue, UIColor.flatSkyBlueDark])
        
        //cell.backgroundColor = gradientBackground
        
        let cellBGColor = RandomFlatColorWithShade(.light) //FlatWhite() //appData.colorScheme[indexPath.row % 4]
        
        cell.buttonBackground.backgroundColor = cellBGColor.darken(byPercentage: 0.2)
        cell.buttonBackground.layer.cornerRadius = cell.buttonBackground.frame.size.width / 2
        cell.buttonBackground.clipsToBounds = true
        cell.buttonBackground.addSubview(cell.playStopButton)
        
        cell.backgroundColor = cellBGColor
        cell.taskNameField.textColor = ContrastColorOf(cellBGColor, returnFlat: true)
        cell.taskTimeRemaining.textColor = ContrastColorOf(cellBGColor, returnFlat: true)
//        if appData.darknessCheck(for: cellBGColor) {
//            cell.taskNameField.textColor = .white
//            cell.taskTimeRemaining.textColor = .white
//        } else {
//            cell.taskNameField.textColor = .black
//            cell.taskTimeRemaining.textColor = .black
//        }
        
        if appData.isGlass {
            let blurEffect = UIBlurEffect(style: .extraLight)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView.frame = cell.bounds
            cell.backgroundColor = UIColor(white:1, alpha:0)
            //cell.backgroundView = blurEffectView
            //cell.contentView.backgroundColor = .clear
            //cell.isOpaque = false
            //cell.layer.opacity = 0.5
            //cell.backgroundColor = .clear
            //cell.layer.backgroundColor = UIColor.clear.cgColor
            //cell.insertSubview(blurEffectView, at: 0)
        }
        
        let borderColor = cellBGColor.darken(byPercentage: 0.3)?.cgColor
        
        cell.layer.masksToBounds = false
        cell.layer.cornerRadius = 5.0
        setBorder(for: cell.layer, borderWidth: 2.0, borderColor: borderColor!, radius: 10.0)
        
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)// CGSize.zero
        cell.layer.shadowRadius = 2.0
        cell.layer.shadowOpacity = 1.0
        
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.layer.bounds, cornerRadius: cell.layer.cornerRadius).cgPath
        
        if type == .line {
            
            cell.progressView.barHeight = 6.0
            //cell.progressView.transform = cell.progressView.transform.scaledBy(x: 1.0, y: 2.0)
            setBorder(for: cell.progressView.layer, borderWidth: 0.2, borderColor: borderColor!, radius: 5.0)
            calculateProgress(for: cell, ofType: .line)
            //cell.progressView.progressTintColor = UIColor.darkGray
            cell.progressView.clipsToBounds = true
            
            cell.progressView.isHidden = false
            //cell.circleProgressView.isHidden = true
            
        } else if type == .circular {
            
            let iOSDefaultBlue = UIButton(type: UIButtonType.system).titleColor(for: .normal)!
            cell.circleProgressView.trackColor = .darkGray
            cell.circleProgressView.progressColors = [iOSDefaultBlue]
            cell.circleProgressView.progress = 0.0
            calculateProgress(for: cell, ofType: .circular)
            
            //cell.progressView.isHidden = true
            cell.circleProgressView.isHidden = false
            
        }

        if task.isToday {
            _ = cell.formatTimer(for: task, ofType: type)
            //cell.progressView.isHidden = false
            cell.playStopButton.isHidden = false
            cell.buttonBackground.alpha = 1
            if check.access(for: task, upTo: now) {
                saveData()
            }
        } else {
            cell.playStopButton.isHidden = true
            cell.buttonBackground.alpha = 0
            cell.taskTimeRemaining.text = "No task today"
            //cell.progressView.isHidden = true
        }
        
    }
    
}

//MARK: - Progress View Height Extension

extension UIProgressView {
    
    @IBInspectable var barHeight : CGFloat {
        get {
            return transform.d * 2.0
        }
        set {
            // 2.0 Refers to the default height of 2
            let heightScale = newValue / 2.0
            let c = center
            transform = CGAffineTransform(scaleX: 1, y: heightScale)
            center = c
        }
    }
}

//extension UIImage{
//
//    func resizeImageWith(ratio: CGFloat) -> UIImage {
//
//        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
//        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
//        draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: newSize))
//        let newImage = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        return newImage!
//    }
//
//}

//MARK: - Testing Extension

extension UIViewController {
    func popAlert(with message: String) {
        
        let alertController = UIAlertController(title: "Test",
                                                message: message,
                                                preferredStyle: UIAlertControllerStyle.alert)
        
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default){ (action: UIAlertAction) in
            print("Hello")
        }
        
        alertController.addAction(okAction)
        
        present(alertController,animated: true,completion: nil)
        
    }
}

