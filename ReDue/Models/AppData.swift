//
//  AppData.swift
//  RepeatingTasks
//
//  Created by Chase Peers on 8/4/17.
//  Copyright © 2017 Chase Peers. All rights reserved.
//

import Foundation
import Chameleon

class AppData: NSObject, NSCoding {

    //MARK: - Properties
    
    // Basic task information
    var taskResetTime = Date()
    var taskLastTime = Date()
    var taskCurrentTime = Date()
    var colorScheme: [UIColor] = []
    var appColor = FlatSkyBlue()
    
    var appColorName = "Sky Blue"
    var resetOffset = "12:00"
    
    // Colors
    var mainColor = HexColor("247BA0")
    var bgColor = HexColor("EEF5DB") /*FlatWhite()*/
    var taskColor1 = HexColor("70C1B3")
    var taskColor2 = HexColor("B2DBBF")
    var progressColor = HexColor("FF1654")
    
    // App settings
    var isFullVersion = false
    var isNightMode = false
    var isGlass = false
    var usesCircularProgress = false
    var deviceType: DeviceType = {
        let screenSize = UIScreen.main.bounds
        let screenHeight = screenSize.height
        let type: DeviceType
        
        switch screenHeight {
        case ...600 :
            type = .legacy
        case 601...700 :
            type = .normal
        case 701...800 :
            type = .large
        case 801... :
            type = .X
        default:
            type = .normal
        }
        
        return type

    }()
    
    // Vars that holds all task data
    // Used for saving
    var appSettings = [String : Bool]()
    var timeSettings = [String : Date]()
    var colorSettings = [String : UIColor]()
    var misc = [String : String]()
    
    //MARK: - Keys
    struct Key {
        static let taskResetTimeKey = "taskResetTimeKey"
        static let taskLastTimeKey = "taskLastTimeKey"
        static let taskCurrentTimeKey = "taskCurrentTimeKey"
        static let colorSchemeKey = "colorSchemeKey"
        static let appColorKey = "appColorKey"
        static let appColorNameKey = "appColorNameKey"
        static let resetOffsetKey = "resetOffsetKey"
        static let isFullVersionKey = "isFullVersionKey"
        static let isNightModeKey = "isNightModeKey"
        static let usesCircularProgressKey = "usesCircularProgressKey"
        static let deviceTypeKey = "deviceTypeKey"
        static let isGlassKey = "isGlassKey"
        
        static let mainColorKey = "mainColorKey"
        static let bgColorKey = "bgColorKey"
        static let taskColor1Key = "taskColor1Key"
        static let taskColor2Key = "taskColor2Key"
        static let progressColorKey = "progressColorKey"

        //static let Key = "Key"
    }


    //MARK: - Archiving Paths

    static let documentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let appURL = documentsDirectory.appendingPathComponent("appSettings")
    
    //MARK: - Color Functions

    //TODO: Chaff???
    func loadColors() {
        
        if let appColor = colorSettings["appColor"] {
            self.appColor = appColor
        }
        
        setColorScheme()
        
    }
    
    /* Checks input color and uses a function (found on StackOverflow) to determine the darkness level.
       If that is over 0.5 then we use this to determine whether or not to set the text to white. */
    func darknessCheck(for color: UIColor?) -> Bool {
        
        var r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0, a: CGFloat = 0.0

        color?.getRed(&r, green: &g, blue: &b, alpha: &a)

        // Counting the perceptive luminance - human eye favors green color...
        let darkness = 1 - ( 0.299 * r + 0.587 * g + 0.114 * b)
        
        return darkness > 0.5
        
    }
    
    //TODO: Chaff???
    func setColorScheme() {
        colorScheme = ColorSchemeOf(.complementary, color: appColor, isFlatScheme: true)
        colorScheme.remove(at: 2)
    }
    
    //TODO: Chaff???
    func setAppValues() {
        
        var defaultReset = DateComponents()
        defaultReset.year = Calendar.current.component(.year, from: Date())
        defaultReset.month = Calendar.current.component(.month, from: Date())
        defaultReset.day = Calendar.current.component(.day, from: Date())
        defaultReset.hour = 2
        defaultReset.minute = 0
        defaultReset.second = 0
        
        //taskResetTime = timeSettings["taskResetTime"]!
        taskResetTime = Calendar.current.date(from: defaultReset)!
        taskLastTime = timeSettings["taskLastTime"] ?? Date()
        taskCurrentTime = timeSettings["taskCurrentTime"] ?? Date()
        
        isFullVersion = appSettings["isFullVersion"] ?? false
        isNightMode = appSettings["isNightMode"] ?? false
        usesCircularProgress = appSettings["usesCircularProgress"] ?? false
        appColorName = misc["ColorName"] ?? "Lapis"
        resetOffset = misc["ResetOffset"] ?? "12:00"
        
    }
    
    //MARK: - NSCoding
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(taskResetTime, forKey: Key.taskResetTimeKey)
        aCoder.encode(taskLastTime, forKey: Key.taskLastTimeKey)
        aCoder.encode(taskCurrentTime, forKey: Key.taskCurrentTimeKey)
        aCoder.encode(appColor, forKey: Key.appColorKey)
        aCoder.encode(appColorName, forKey: Key.appColorNameKey)
        aCoder.encode(resetOffset, forKey: Key.resetOffsetKey)
        aCoder.encode(isFullVersion, forKey: Key.isFullVersionKey)
        aCoder.encode(isNightMode, forKey: Key.isNightModeKey)
        aCoder.encode(usesCircularProgress, forKey: Key.usesCircularProgressKey)
        aCoder.encode(mainColor, forKey: Key.mainColorKey)
        aCoder.encode(bgColor, forKey: Key.bgColorKey)
        aCoder.encode(taskColor1, forKey: Key.taskColor1Key)
        aCoder.encode(taskColor2, forKey: Key.taskColor2Key)
        aCoder.encode(progressColor, forKey: Key.progressColorKey)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        let taskResetTime = aDecoder.decodeObject(forKey: Key.taskResetTimeKey) as? Date ?? Date()
        let taskLastTime = aDecoder.decodeObject(forKey: Key.taskLastTimeKey) as? Date  ?? Date()
        let taskCurrentTime = aDecoder.decodeObject(forKey: Key.taskCurrentTimeKey) as? Date ?? Date()

        let appColor = aDecoder.decodeObject(forKey: Key.appColorKey) as? UIColor ?? FlatSkyBlue()
        
        let appColorName = aDecoder.decodeObject(forKey: Key.appColorNameKey) as? String ?? "Lapis"

        let resetOffset = aDecoder.decodeObject(forKey: Key.resetOffsetKey) as? String  ?? "12:00"

        let isFullVersion = aDecoder.decodeBool(forKey: Key.isFullVersionKey)
        let isNightMode = aDecoder.decodeBool(forKey: Key.isNightModeKey)
        let isGlass = aDecoder.decodeBool(forKey: Key.isGlassKey)
        let usesCircularProgress = aDecoder.decodeBool(forKey: Key.usesCircularProgressKey)

        let mainColor = aDecoder.decodeObject(forKey: Key.mainColorKey) as? UIColor ?? HexColor("247BA0")!
        let bgColor = aDecoder.decodeObject(forKey: Key.bgColorKey) as? UIColor ?? FlatWhite()
        let taskColor1 = aDecoder.decodeObject(forKey: Key.taskColor1Key) as? UIColor ?? HexColor("70C1B3")!
        let taskColor2 = aDecoder.decodeObject(forKey: Key.taskColor2Key) as? UIColor ?? HexColor("B2DBBF")!
        let progressColor = aDecoder.decodeObject(forKey: Key.progressColorKey) as? UIColor ?? HexColor("FF1654")!
        
        self.init(taskResetTime: taskResetTime, taskLastTime: taskLastTime, taskCurrentTime: taskCurrentTime, appColor: appColor, appColorName: appColorName, resetOffset: resetOffset, isFullVersion: isFullVersion, isNightMode: isNightMode, isGlass: isGlass, usesCircularProgress: usesCircularProgress, mainColor: mainColor, bgColor: bgColor, taskColor1: taskColor1, taskColor2: taskColor2, progressColor: progressColor)
        
    }
    
    //MARK: - Init
    
    init(taskResetTime: Date, taskLastTime: Date, taskCurrentTime: Date, appColor: UIColor, appColorName: String, resetOffset: String, isFullVersion: Bool, isNightMode: Bool, isGlass: Bool, usesCircularProgress: Bool, mainColor: UIColor, bgColor: UIColor, taskColor1: UIColor, taskColor2: UIColor, progressColor: UIColor) {
        
        self.taskResetTime = taskResetTime
        self.taskLastTime = taskLastTime
        self.taskCurrentTime = taskCurrentTime
        self.appColor = appColor
        self.appColorName = appColorName
        self.resetOffset = resetOffset
        self.isFullVersion = isFullVersion
        self.isNightMode = isNightMode
        self.isGlass = isGlass
        self.usesCircularProgress = usesCircularProgress
        
        self.mainColor = mainColor
        self.bgColor = bgColor
        self.taskColor1 = taskColor1
        self.taskColor2 = taskColor2
        self.progressColor = progressColor
        
    }
    
    init(appSettings: [String : Bool], timeSettings: [String : Date], colorSettings: [String : UIColor], misc: [String : String]) {
        
        self.appSettings = appSettings
        self.timeSettings = timeSettings
        self.colorSettings = colorSettings
        self.appColorName = misc["ColorName"] ?? "Lapis"
        self.resetOffset = misc["ResetOffset"]!
        
    }
    
    override init() {
        super.init()
        
        if let appColor = colorSettings["appColor"] {
            self.appColor = appColor
        }
        
        setColorScheme()
        
    }
    
}

