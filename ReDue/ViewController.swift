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
    
    var runningTaskVCs = [TaskDetailViewController]()
    
    var selectedTask: Task?
    var selectedCell: TaskCollectionViewCell?
    var runningCompletionTime = 0.0 //TODO: What is this????
    
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

    var colors = Colors(main: HexColor("247BA0")!, bg: FlatWhite(), task1: HexColor("70C1B3")!, task2: HexColor("B2DBBF")!, progress: HexColor("FF1654")!)
    
    //MARK: - View and Basic Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load any saved data
        loadData()
        
        print("loaded Values")
        print(tasks)
        
        log.info("loaded Tasks")
        log.info(tasks)
        
        // Loads check functions
        initializeCheck()
        
        /* Save current time for comparisons and reset time check */
        appData.taskCurrentTime = Date()
        
        NotificationCenter.default.addObserver(forName: Notification.Name("StopTimerNotification"), object: nil, queue: nil, using: catchNotification)
        
        prepareNavBar()
        
        // Hide ads if full version
        if !appData.isFullVersion {
            adView.alpha = 0
            let request = GADRequest()
            request.testDevices = [kGADSimulatorID]
            adBannerView.load(request)
        }
        
        // Offset times so that reset always occurs at "midnight" for easy calculation
        now = currentTimeIs()
        let then = check.offsetDate(appData.taskLastTime, by: appData.resetOffset)
        lastUsed = then
        
        for task in tasks {
            if check.changeOfWeek(between: lastUsed, and: now) {
                
                let frequency = task.frequency
                let lastRunWeek = task.runWeek
                let nextRunWeek = (lastRunWeek + Int(frequency)) % 52

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
    
    /* Sets bar buttons and then runs the theme function */
    func prepareNavBar() {
        
        let addBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTask))
        navigationItem.rightBarButtonItems = [addBarButton]
        
        let settingsButton = UIBarButtonItem(image: #imageLiteral(resourceName: "Settings"), style: .plain, target: self, action: #selector(settingsButtonTapped))
        toolbarItems = [settingsButton]
        navigationController?.isToolbarHidden = false
        
        setTheme()
        
    }
    
    /* Sets the color for all elements in the view.
       Color is determined by themes which are chosen in app settings */
    func setTheme() {
        
        colors = Colors.init(main: appData.mainColor!, bg: appData.bgColor!, task1: appData.taskColor1!, task2: appData.taskColor2!, progress: appData.progressColor!)
        
        let navigationBar = navigationController?.navigationBar
        navigationBar?.barTintColor = appData.appColor
        navigationBar?.barTintColor = appData.mainColor
        //navigationBar?.mixedBarStyle = MixedBarStyle(normal: .default, night: .blackTranslucent)
        
        let toolbar = navigationController?.toolbar
        toolbar?.barTintColor = appData.appColor
        toolbar?.barTintColor = colors.main
        
        //let darkerThemeColor = appData.appColor.darken(byPercentage: 0.25)
        
        //view.backgroundColor = darkerThemeColor
        view.backgroundColor = FlatWhite().darken(byPercentage: 0.1)
        view.backgroundColor = colors.bg
        taskList.backgroundColor = .clear
        taskList.backgroundView = UIView(frame: .zero)
        //taskList.backgroundView?.backgroundColor = darkerThemeColor //FlatWhite() //darkerThemeColor
        
        if appData.isNightMode {
            //NightNight.theme = .night
        } else {
            //NightNight.theme = .normal
        }
        
        let bgColor = navigationController?.navigationBar.barTintColor
        
        /* Check the color behind this text and set the text color appropriately */
        if appData.darknessCheck(for: bgColor) {
            navigationBar?.tintColor = .white
            toolbar?.tintColor = .white
            setStatusBarStyle(.lightContent)
        } else {
            navigationBar?.tintColor = .black
            toolbar?.tintColor = .black
            setStatusBarStyle(.default)
        }
        
    }
    
    /* Since there can be many tasks, this returns the task
       associated with the name sent to the function */
    func setTask(as task: String) -> Task {
        return tasks.first(where: { $0.name == task })!
    }
    
    //TODO: Necessary???
    /* */
    func catchNotification(notification:Notification) -> Void {
        print("Catch notification")
        log.debug("Catch notification")
    }
    
    //MARK: - App Rollover Related Functions
    
    /* Get the current time offset by what the task reset time */
    func currentTimeIs() -> Date {
        return check.offsetDate(Date(), by: appData.resetOffset)
    }
    
    /* Check current time
       Determine the time interval between now and when the timers will reset
       Set a timer to go off at that time */
    func timeCheck() {
        
        // Offset times so that reset always occurs at "midnight" for easy calculation
        let then = check.offsetDate(appData.taskLastTime, by: appData.resetOffset)
        
        let calendar = Calendar.current
        let currentTimeZone = TimeZone.current
        
        var currentTime = getDateComponents(for: now, at: currentTimeZone)
        
        /* Set the reset time to 0 minutes and move to the next day
           i.e. when the reset should happen next */
        var reset = currentTime
        reset.hour = check.offsetAsInt(for: appData.resetOffset)
        reset.minute = 0
        reset.day = currentTime.day! + 1
        
        /* Calculate the date from the reset date components
           use this to find out the number of s until reset */
        nextResetTime = calendar.date(from: reset)!
        let lastResetTime = calendar.date(byAdding: .day, value: -1, to: nextResetTime)
        let timeToReset = check.timeToReset(at: nextResetTime)

        let message = "\(timeToReset) sec until reset"
        print(message)
        log.debug(message)

        guard let taskCells = getTaskCells() else { return }
        let resetOccurred = check.resetTimePassed(between: then, and: now, with: lastResetTime!)
        
        /* If a reset happened between now and the last time the app was opened then reset all tasks */
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

        /* Otherwise make a timer that fires at the reset time */
        } else {
            
            log.debug("No reset yet. Next reset at \(timeToReset)")
            
            let resetDate = Date().addingTimeInterval(timeToReset)
            let resetTimer = Timer(fireAt: resetDate, interval: 0, target: self, selector: #selector(resetTaskTimers), userInfo: nil, repeats: false)
            RunLoop.main.add(resetTimer, forMode: RunLoopMode.commonModes)
            
        }
        
        /* Set the missed time notification for all tasks with time left.
           This is cancelled if a task is completed */
        for task in tasks {
            
            if task.isToday {
                if let cell = taskCells.first(where: { $0.taskNameField.text == task.name }) {
                    let (remainingTimeString, remainingTime) = cell.formatTimer(for: task)
                    if remainingTime > 0 {
                        cell.timer.setMissedTimeNotification(for: task.name, at: timeToReset, withRemaining: remainingTimeString)
                    }
                    cell.nextRunLabel.isHidden = true
                }
            }
            
        }

        appData.taskLastTime = appData.taskCurrentTime
        let data = DataHandler()
        data.saveAppSettings(appData)

    }
    
    /* Returns date components from date input */
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
    
    /* Returns date offset by the reset time
       e.g. A reset time of */
    //TODO: Is this used???
    func date(for day: Date, withOffset offset: Int) -> Date {
        
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: 1, to: day)
        
        return date!
        
    }
    
    /* Ran when the reset time happened or the next time the app is opened after said reset time
        Iterate through all tasks and do the following
        1. Reset completed time
        2. Calculate rollover time
        3. Refresh screen */
    @objc func resetTaskTimers() {
        print("RESET!!!!!!!!")
        log.info("Timers will be reset")
        
        // No need to run if there aren't any tasks
        if tasks.count < 1 {
            return
        }
        
        for task in tasks {
            
            task.rollover = 0
        
            let now = currentTimeIs()
            let daysBetween = check.daysBetweenTwoDates(start: self.lastUsed, end: now)

            log.debug("\(daysBetween) days between last run")
            
            /* Run for each day between the last used task date and today
               If there were any times it should have been done between then
               do the following
               1. Rollover leftover time according to the multiplier
               2. Add data to cumulative stats
               3. Save other data in the task history
               4. Reset the task to the usual time + rollover time */
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

            /* Set the total rollover time and reset completed time */
            task.rollover = task.weightedTime - task.time
            task.completed = 0
            task.willRunOnOffDay = false
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
    
    @objc func taskStartStopButtonPressed(sender: UIButton) {
    }
    
   //MARK: - Data Handling
    
    /* Send app-level data (themes, etc) and any other data to the next VC */
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
            
            /* If going to the settings VC turn off all timers */
            for cell in cells {
                if cell.timer.isEnabled {
                    cell.setImage(as: #imageLiteral(resourceName: "Play"))
                    cell.timer.run.invalidate()
                }
            }
            
        }
        
    }
    
    /* Load appData and tasks */
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
    
    /* Saves appData and tasks */
    func saveData() {
        
        let data = DataHandler()
        data.saveAppSettings(appData)
        data.saveTasks(tasks)

        getTaskNames()
        
    }
    
    /* Saves all task names in an array */
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
    
    /* Save after creating a new task */
    @IBAction func newTaskCreatedUnwind(segue: UIStoryboardSegue) {
        
        saveData()
        
        DispatchQueue.main.async {
            self.taskList.reloadData()
        }
        
    }
    
    /* Save after deleting a task */
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
    
    /* We're setting the dimensions of the presentr window based on device size so this
       helps set the size of the window to be shown */
    func preparePresenter(ofHeight height: Float, ofWidth width: Float) {
        let width = ModalSize.fluid(percentage: width)
        let height = ModalSize.fluid(percentage: height)
        let center = ModalCenterPosition.center
        let customType = PresentationType.custom(width: width, height: height, center: center)
        
        addPresenter.presentationType = customType
        
    }
    
    /* Functions as func prepare for the presentr launched New task VC */
    func presentNewTaskVC() {
        let newTaskViewController = self.storyboard?.instantiateViewController(withIdentifier: "NewTaskVC") as! NewTasksViewController
        newTaskViewController.appData = appData
        newTaskViewController.tasks = taskNames

        switch appData.deviceType {
        case .legacy:
            preparePresenter(ofHeight: 0.8, ofWidth: 0.9)
        case .normal:
            preparePresenter(ofHeight: 0.7, ofWidth: 0.8)
        case .large:
            preparePresenter(ofHeight: 0.7, ofWidth: 0.8)
        case .X:
            preparePresenter(ofHeight: 0.6, ofWidth: 0.8)
        }

        customPresentViewController(addPresenter, viewController: newTaskViewController, animated: true, completion: nil)
    }
    
    /* Functions as func prepare for the task detail VC
       running tasks have their detail VC saved. Those tasks don't pass any data */
    func presentTaskDetailVC() {
        
        let taskCells = getTaskCells()
        guard let cell = taskCells?.first(where: { $0.taskNameField.text == selectedTask!.name }) else { return }

        let taskVC: TaskDetailViewController
        
        if let vc = runningTaskVCs.first(where: {$0.task.name == cell.taskNameField.text}) {
            taskVC = vc
        } else {
            taskVC = self.storyboard!.instantiateViewController(withIdentifier: "TaskDetailVC") as! TaskDetailViewController
            
            taskVC.appData = appData
            taskVC.task = selectedTask!
            taskVC.tasks = tasks
            taskVC.taskNames = taskNames
            taskVC.timer = cell.timer

        }
    
        self.navigationController?.pushViewController(taskVC, animated: true)

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
    
    /* Loads either the regular cell or a cell with a circular progress bar
       Most of the setup code is in a different function called setupCollectionCell() */
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
    
    /* Move to the detail VC after tapping cell. Segue through presentTaskDetailVC() */
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        getTaskNames()
        let taskName = taskNames[indexPath.row]
        let task = setTask(as: taskName)
        
        selectedTask = task
        
        print("Selected task is \(task.name)")
        
        presentTaskDetailVC()
        //performSegue(withIdentifier: "taskDetailSegue", sender: self)
        
    }
    
    //TODO: Delete???
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        //if let cell = cell as? TaskCollectionViewCell {
            //cell.removeObserver()
        //}
    }
    
    //MARK: CollectionView Helper Functions
    
    /* Sets multiple border parameters with one function */
    func setBorder(for layer: CALayer, borderWidth: CGFloat, borderColor: CGColor, radius: CGFloat ) {
        layer.borderWidth = borderWidth
        layer.borderColor = borderColor
        layer.cornerRadius = radius
    }
    
    //TODO: Delete???
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
        
        // These two don't seem to work
        layout.minimumLineSpacing = 20.0
        layout.minimumInteritemSpacing = 20.0
        
        taskList.setCollectionViewLayout(layout, animated: true)
        
        //taskList.reloadData()
        
    }
    
    /* Put most cell related code here to make cellForRowAt smaller
       Loads and sets all items when cell becomes visible */
    func setupCollectionCell(for cell: TaskCollectionViewCell, ofType type: CellType, at indexPath: IndexPath) {
        
        getTaskNames()
        let taskName = taskNames[indexPath.row]
        let task = setTask(as: taskName)
        
        cell.task = task
        cell.appData = appData
        cell.taskNameField.text = task.name
        cell.mainVC = self
        
        // Only set observer once per cell
        if !cell.isObserverSet {
            cell.initializeObserver()
        }

        cell.playStopButton.backgroundColor = UIColor.clear
        cell.playStopButton.addTarget(cell, action: #selector(taskStartStopButtonPressed(sender:)), for: .touchUpInside)
        if cell.taskTimeRemaining.text == "Complete" {
            cell.playStopButton.isEnabled = false
        } else {
            cell.playStopButton.isEnabled = true
        }
        
        if cell.timer.isEnabled && task.isRunning, let _ = selectedTask?.name {
            cell.setImage(as: #imageLiteral(resourceName: "Pause"))
        } else {
            cell.setImage(as: #imageLiteral(resourceName: "Play"))
        }
        
        //let gradientBackground = GradientColor(.leftToRight, frame: cell.frame, colors: [UIColor.flatSkyBlue, UIColor.flatSkyBlueDark])
        //cell.backgroundColor = gradientBackground
        
        /* For now there are ten colors for cells. But all are variations of one of two colors */
        var taskColors = [UIColor]()
        taskColors.append(colors.task1)
        taskColors.append(colors.task2)
        taskColors.append(colors.task3)
        taskColors.append(colors.task4)
        taskColors.append(colors.task5)
        taskColors.append(colors.task6)
        taskColors.append(colors.task7)
        taskColors.append(colors.task8)
        taskColors.append(colors.task9)
        taskColors.append(colors.task10)

        let cellBGColor = taskColors[indexPath.row % 10]
        
        cell.buttonBackground.backgroundColor = cellBGColor.darken(byPercentage: 0.2)
        cell.buttonBackground.layer.cornerRadius = cell.buttonBackground.frame.size.width / 2
        cell.buttonBackground.clipsToBounds = true
        //cell.buttonBackground.addSubview(cell.playStopButton)
        
        //cell.playStopButton.addSubview(cell.buttonBackground)
        //cell.playStopButton.sendSubview(toBack: cell.buttonBackground)
        
//        if appData.darknessCheck(for: cellBGColor) {
//            cell.taskNameField.textColor = .white
//            cell.taskTimeRemaining.textColor = .white
//        } else {
//            cell.taskNameField.textColor = .black
//            cell.taskTimeRemaining.textColor = .black
//        }
        
        /* Still not sure if I will use this
           Leaving in for now
           Creates glass effect for cells */
        if appData.isGlass {

            let blurEffect = UIBlurEffect(style: .light)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView.frame = cell.contentView.bounds
            
            /* Only add blur effect the first time.
               Without this the blur is added every time you
               switch back to this view */
            let subviews = cell.contentView.subviews
            if !subviews.contains(where: {$0 is UIVisualEffectView}) {
                cell.contentView.addSubview(blurEffectView)
                cell.contentView.sendSubview(toBack: blurEffectView)
            }
            
            cell.backgroundColor = .clear
            
            cell.layer.cornerRadius = 10.0
            
            cell.layer.shadowOpacity = 0.0
            cell.layer.borderWidth = 0.0
            
            cell.contentView.clipsToBounds = true
            cell.clipsToBounds = true
            cell.layer.masksToBounds = true
            
            setCellColor(forCell: cell)
            
        /* Sets border, shadow and color for each cell */
        } else {
        
            //let borderColor = cellBGColor.darken(byPercentage: 0.3)?.cgColor
            setBorder(for: cell.layer, borderWidth: 2.0, borderColor: UIColor.clear.cgColor, radius: 10.0)

            cell.layer.shadowColor = UIColor.black.cgColor
            cell.layer.shadowOffset = CGSize(width: 6.0, height: 5.0)// CGSize.zero
            cell.layer.shadowRadius = 2.0
            cell.layer.shadowOpacity = 0.5

            cell.layer.shadowPath = UIBezierPath(roundedRect: cell.layer.bounds, cornerRadius: cell.layer.cornerRadius).cgPath
            cell.layer.masksToBounds = false

            setCellColor(cellBGColor, forCell: cell)

        }
        
        if type == .line {
            
            cell.progressView.barHeight = 6.0
            cell.progressView.layer.cornerRadius = 5.0
            cell.progressView.progressTintColor = appData.progressColor
            //cell.progressView.transform = cell.progressView.transform.scaledBy(x: 1.0, y: 2.0)
            //let borderColor = cellBGColor.darken(byPercentage: 0.3)?.cgColor
            if !appData.isGlass {
                //setBorder(for: cell.progressView.layer, borderWidth: 0.2, borderColor: borderColor!, radius: 5.0)
            } else {
                setBorder(for: cell.progressView.layer, borderWidth: 0.0, borderColor: UIColor.clear.cgColor, radius: 0.0)
            }
            
            cell.calculateProgress(ofType: .line)
            //cell.progressView.progressTintColor = UIColor.darkGray
            cell.progressView.clipsToBounds = true
            
            cell.progressView.isHidden = false
            //cell.circleProgressView.isHidden = true
            
        } else if type == .circular {
            
            let iOSDefaultBlue = UIButton(type: UIButtonType.system).titleColor(for: .normal)!
            cell.circleProgressView.trackColor = .darkGray
            cell.circleProgressView.progressColors = [iOSDefaultBlue]
            cell.circleProgressView.progress = 0.0
            cell.calculateProgress(ofType: .circular)

            //cell.progressView.isHidden = true
            cell.circleProgressView.isHidden = false
            
        }

        /* Show play Button, timer, next task day, etc.
           depending on whether the task will occur today or not */
        if task.isToday || task.willRunOnOffDay {
            _ = cell.formatTimer(for: task, ofType: type)
            //cell.progressView.isHidden = false
            cell.playStopButton.isHidden = false
            cell.buttonBackground.alpha = 1
            if check.access(for: task, upTo: now) {
                saveData()
            }
            cell.nextRunLabel.isHidden = true
        } else {
            cell.playStopButton.isHidden = true
            cell.buttonBackground.alpha = 0
            cell.taskTimeRemaining.text = "No task today"
            //cell.progressView.isHidden = true
        }
        
        /* If task will not happen show the next run day */
        if !task.isToday && !task.willRunOnOffDay {
            showNextRunDate(in: cell, for: task)
        } else {
            cell.nextRunLabel.isHidden = true
        }
        
    }
    
    func setCellColor(_ background: UIColor = .clear, forCell cell: TaskCollectionViewCell) {
        cell.backgroundColor = background
        cell.taskNameField.textColor = ContrastColorOf(background, returnFlat: true)
        cell.taskTimeRemaining.textColor = ContrastColorOf(background, returnFlat: true)
        cell.nextRunLabel.textColor = ContrastColorOf(background, returnFlat: true)
    }
    
    // Actually creates the desired blur effect
    func vibrancyEffectView(forBlurEffectView blurEffectView:UIVisualEffectView) -> UIVisualEffectView {
        
        let vibrancy = UIVibrancyEffect(blurEffect: blurEffectView.effect as! UIBlurEffect)
        let vibrancyView = UIVisualEffectView(effect: vibrancy)
        
        vibrancyView.isUserInteractionEnabled = false
        vibrancyView.frame = blurEffectView.bounds
        vibrancyView.autoresizingMask = .flexibleWidth
        return vibrancyView
    }
    
    /* Takes the set task days and then reorders them with the
       next run day at [0]. It then checks to see how far away the next run day is.
       If the task doesn't run every week then the function will add
       the neccessary number of weeks to obtain the correct next run date.
       That date is then shown in the cell.
     */
    func showNextRunDate(in cell: TaskCollectionViewCell, for task: Task) {
        
        //let nextRunWeek = task.runWeek
        var nextRunDay = "EMPTY"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        let currentDateString = dateFormatter.string(from: Date())
        
        let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        
        var reindexedDays = [String]()
        
        // Reorders the week with the current day at [0]
        guard let todayIndex = days.index(of: currentDateString) else { return }
        for i in 0..<days.count {
            reindexedDays.append(days[(todayIndex + i) % days.count])
        }
        
        var daysFromNow = 1
        
        for i in 0..<reindexedDays.count {
            daysFromNow = i
            if task.days[reindexedDays[i]]! {
                nextRunDay = reindexedDays[i]
                break
            }
        }
        
        // Add the number of days until next run time to current date
        let calendar = Calendar.current
        var calculatedNextRunDay = calendar.date(byAdding: .day, value: daysFromNow, to:
            Date())
        
        /* If the task will not run this week then add the appropriate number of weeks
           to get the actual run date. */
        var runWeek = task.runWeek
        let thatWeek = calendar.dateComponents([.weekOfYear], from: calculatedNextRunDay!)
        if runWeek != thatWeek.weekOfYear {
            runWeek += Int(task.frequency)
            calculatedNextRunDay = calendar.date(byAdding: .weekOfYear, value: ((runWeek % 52) - thatWeek.weekOfYear!), to: calculatedNextRunDay!)
        }

        dateFormatter.dateFormat = "MM/dd"
        let mmdd = dateFormatter.string(from: calculatedNextRunDay!)
        print(calculatedNextRunDay!)
        
//        var comps = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: Date())
//        comps.weekday = 2 // Monday
//        let mondayInWeek = calendar.date(from: comps)!
        
        dateFormatter.dateFormat = "EEEE"
        if nextRunDay == dateFormatter.string(from: calculatedNextRunDay!) {
            dateFormatter.dateFormat = "EEE"
            let abbrevNextRunDay = dateFormatter.string(from: calculatedNextRunDay!)
            cell.nextRunLabel.text = "Next run:\n\(abbrevNextRunDay) \(mmdd)"
            cell.nextRunLabel.isHidden = false

        }
        
    }
}

//MARK: - Progress View Height Extension

extension UIProgressView {
    
    /* Found on stackoverflow. Changes height of progressView */
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

/* This is used in many VC so I just added it to UIViewController
   This func pops an alert that only allows use of the Ok button*/
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

//MARK: - Color Scheme Extension

/* This color struct is used in all VCs to theme the app */
extension UIViewController {
    
    struct Colors {
        var main: UIColor
        var bg: UIColor
        var task1: UIColor
        var task2: UIColor
        var progress: UIColor
        
        let darkMain: UIColor
        let darkBG: UIColor
        let lightTask1: UIColor
        let lightTask2: UIColor
        let darkTask1: UIColor
        let darkTask2: UIColor
        let task3: UIColor
        let task4: UIColor
        let task5: UIColor
        let task6: UIColor
        let task7: UIColor
        let task8: UIColor
        let task9: UIColor
        let task10: UIColor

        static let colorLevel1: CGFloat = 0.1
        static let colorLevel2: CGFloat = 0.25
        static let colorLevel3: CGFloat = 0.5
        static let colorLevel4: CGFloat = 0.6
        
        init(main: UIColor, bg: UIColor, task1: UIColor, task2: UIColor, progress: UIColor) {
            self.main = main
            self.bg = bg
            self.task1 = task1
            self.task2 = task2
            self.progress = progress
            
            self.darkMain = main.darken(byPercentage: 0.2)!
            self.darkBG = bg.darken(byPercentage: 0.1)!
            self.darkTask1 = task1.darken(byPercentage: 0.1)!
            self.darkTask2 = task2.darken(byPercentage: 0.1)!
            self.lightTask1 = task1.lighten(byPercentage: 0.1)!
            self.lightTask2 = task2.lighten(byPercentage: 0.1)!
            
            self.task3 = task1.adjustBrightness(by: -5)
            self.task4 = task2.adjustBrightness(by: 30)
            self.task5 = task1.adjustBrightness(by: 20)
            self.task6 = task2.adjustBrightness(by: -10)
            self.task7 = task1.adjust(by: -5)!
            self.task8 = task2.adjust(by: 30)!
            self.task9 = task1.adjust(by: 20)!
            self.task10 = task2.adjust(by: -10)!
        }
        
    }

}

extension UIColor {
    
    func adjustBrightness(by percentage: CGFloat = 30.0) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if self.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            if b < 1.0 {
                let newB: CGFloat = max(min(b + (percentage/100.0)*b, 1.0), 0,0)
                return UIColor(hue: h, saturation: s, brightness: newB, alpha: a)
            } else {
                let newS: CGFloat = min(max(s - (percentage/100.0)*s, 0.0), 1.0)
                return UIColor(hue: h, saturation: newS, brightness: b, alpha: a)
            }
        }
        return self
    }

    func adjust(by percentage:CGFloat=30.0) -> UIColor? {
        var r:CGFloat=0, g:CGFloat=0, b:CGFloat=0, a:CGFloat=0;
        if(self.getRed(&r, green: &g, blue: &b, alpha: &a)){
            return UIColor(red: min(r + percentage/100, 1.0),
                           green: min(g + percentage/100, 1.0),
                           blue: min(b + percentage/100, 1.0),
                           alpha: a)
        }else{
            return nil
        }
    }
    
}
