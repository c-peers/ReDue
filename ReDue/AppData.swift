//
//  AppData.swift
//  RepeatingTasks
//
//  Created by Chase Peers on 8/4/17.
//  Copyright © 2017 Chase Peers. All rights reserved.
//

import Foundation
import Chameleon

enum DeviceType {
    case legacy
    case normal
    case large
    case X
}

class AppData: NSObject, NSCoding {

    //MARK: - Properties
    
    // Basic task information
    var taskResetTime = Date()
    var taskLastTime = Date()
    var taskCurrentTime = Date()
    var colorScheme: [UIColor] = []
    var appColor = FlatSkyBlueDark()
    
    var appColorName = ""
    var resetOffset = ""
    
    // App settings
    var isFullVersion = false
    var isNightMode = false
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
    
    //MARK: - Archiving Paths

    static let documentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let archiveAppSettings = documentsDirectory.appendingPathComponent("appSettings")
    static let archiveTimeSettings = documentsDirectory.appendingPathComponent("timeSettings")
    static let archiveColorSettings = documentsDirectory.appendingPathComponent("colorSettings")
    static let archiveMisc = documentsDirectory.appendingPathComponent("miscSettings")

    //MARK: - Data Handling
    
    func save() {
        
        saveAppSettingsToDictionary()
        saveTimeSettingsToDictionary()
        saveColorSettingsToDictionary()
        saveMiscSettingsToDictionary()
        
        let appSettingsSaveSuccessful = NSKeyedArchiver.archiveRootObject(appSettings, toFile: AppData.archiveAppSettings.path)
        let timeSettingsSaveSuccessful = NSKeyedArchiver.archiveRootObject(timeSettings, toFile: AppData.archiveTimeSettings.path)
        let colorSettingsSaveSuccessful = NSKeyedArchiver.archiveRootObject(colorSettings, toFile: AppData.archiveColorSettings.path)
        let miscSaveSuccessful = NSKeyedArchiver.archiveRootObject(misc, toFile: AppData.archiveMisc.path)
        
        print("Saved app settings: \(appSettingsSaveSuccessful)")
        print("Saved time settings: \(timeSettingsSaveSuccessful)")
        print("Saved color settings: \(colorSettingsSaveSuccessful)")
        print("Saved misc: \(miscSaveSuccessful)")
        
    }
    
    func load() {
        
        if let loadAppSettings = NSKeyedUnarchiver.unarchiveObject(withFile: AppData.archiveAppSettings.path) as? [String : Bool] {
            appSettings = loadAppSettings
        }
        if let loadTimeSettings = NSKeyedUnarchiver.unarchiveObject(withFile: AppData.archiveTimeSettings.path) as? [String : Date] {
            timeSettings = loadTimeSettings
        }
        
        if let loadColorSettings = NSKeyedUnarchiver.unarchiveObject(withFile: AppData.archiveColorSettings.path) as? [String : UIColor] {
            colorSettings = loadColorSettings
        }

        if let loadMisc = NSKeyedUnarchiver.unarchiveObject(withFile: AppData.archiveMisc.path) as? [String : String] {
            misc = loadMisc
        }
        
        setAppValues()
        
    }
    
    //MARK: - Color Functions

    func loadColors() {
        
        if let appColor = colorSettings["appColor"] {
            self.appColor = appColor
        }
        
        setColorScheme()
        
    }
    
//    func darknessCheckOLD(for color:UIColor? = nil) -> Bool {
//        
//        var r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0, a: CGFloat = 0.0
//        
//        color?.getRed(&r, green: &g, blue: &b, alpha: &a)
//        
//        let twoLowColors = (r < 0.7 || g < 0.7)
//        
//        if r  < 0.7 && g  < 0.7 && b < 0.7 {
//            return true
//        } else {
//            return false
//        }
//        
//    }
    
    func darknessCheck(for color: UIColor?) -> Bool {
        
        var r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0, a: CGFloat = 0.0

        color?.getRed(&r, green: &g, blue: &b, alpha: &a)

        // Counting the perceptive luminance - human eye favors green color...
        let darkness = 1 - ( 0.299 * r + 0.587 * g + 0.114 * b)
        
        return darkness > 0.5
        
    }
    
    func setColorScheme() {
        
        colorScheme = ColorSchemeOf(.analogous, color: appColor, isFlatScheme: true)
        
    }
    
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
        appColorName = misc["ColorName"] ?? "Sky Blue Dark"
        resetOffset = misc["ResetOffset"] ?? "12:00"
        
    }
    
    
    func saveAppSettingsToDictionary(){
        
        appSettings["isNightMode"] = isNightMode
        appSettings["usesCircularProgress"] = usesCircularProgress
        appSettings["isFullVersion"] = isFullVersion
        
    }
    
    func saveTimeSettingsToDictionary(){
        
        timeSettings["taskResetTime"] = taskResetTime
        timeSettings["taskLastTime"] = taskLastTime
        timeSettings["taskCurrentTime"] = taskCurrentTime
        
    }
    
    func saveColorSettingsToDictionary() {
        
        colorSettings["appColor"] = appColor
    }
    
    func saveMiscSettingsToDictionary() {
        
        misc["ColorName"] = appColorName
        misc["ResetOffset"] = resetOffset

    }
    
    //MARK: - NSCoding
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(appSettings, forKey: "appSettings")
        aCoder.encode(timeSettings, forKey: "timeSettings")
        aCoder.encode(colorSettings, forKey: "colorSettings")
        aCoder.encode(appColorName, forKey: "miscSettings")
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        guard let appSettings = aDecoder.decodeObject(forKey: "appSettings") as? [String : Bool] else {
            return nil
        }
        guard let timeSettings = aDecoder.decodeObject(forKey: "timeSettings") as? [String : Date] else {
            return nil
        }
        guard let colorSettings = aDecoder.decodeObject(forKey: "colorSettings") as? [String : UIColor] else {
            return nil
        }
        guard let misc = aDecoder.decodeObject(forKey: "miscSettings") as? [String : String] else {
            return nil
        }
        
        // Must call designated initializer.
        self.init(appSettings: appSettings,  timeSettings: timeSettings, colorSettings: colorSettings, misc: misc)
        
    }
    
    //MARK: - Init
    
    init(appSettings: [String : Bool], timeSettings: [String : Date], colorSettings: [String : UIColor], misc: [String : String]) {
        
        self.appSettings = appSettings
        self.timeSettings = timeSettings
        self.colorSettings = colorSettings
        self.appColorName = misc["ColorName"] ?? "Sky Blue Dark"
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

