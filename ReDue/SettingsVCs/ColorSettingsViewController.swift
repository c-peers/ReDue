//
//  ColorSettingsViewController.swift
//  RepeatingTasks
//
//  Created by Chase Peers on 8/28/17.
//  Copyright © 2017 Chase Peers. All rights reserved.
//

import UIKit
import Chameleon

class ColorSettingsViewController: UITableViewController {
    
    var appData = AppData()
    
    var previousCellIndex: IndexPath?
    var selectedColor: UIColor?
    var selectedTheme: String?
    var selectedEnum: ThemeColors?
    
    var colors = Colors(main: HexColor("247BA0")!, bg: FlatWhite(), task1: HexColor("70C1B3")!, task2: HexColor("B2DBBF")!, progress: HexColor("FF1654")!)
    
    var colorList = [String]()
//                  "Blue",
//                  "Brown",
//                  "Coffee",
//                  "Forest Green",
//                  "Gray",
//                  "Green",
//                  "Magenta",
//                  "Maroon",
//                  "Mint",
//                  "Navy Blue",
//                  "Pink",
//                  "Powder Blue",
//                  "Purple",
//                  "Red",
//                  "Sand",
//                  "Sky Blue",
//                  "Teal",
//                  "Watermelon",
//                  "White",
//                  "Dark Blue",
//                  "Dark Coffee",
//                  "Dark Gray",
//                  "Dark Green",
//                  "Dark Magenta",
//                  "Dark Mint",
//                  "Dark Orange",
//                  "Dark Pink",
//                  "Dark Powder Blue",
//                  "Dark Purple",
//                  "Dark Red",
//                  "Dark Sand",
//                  "Dark Sky Blue",
//                  "Dark Teal",
//                  "Dark Watermelon"]
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {

        self.title = "Theme Color"
        
        tableView.sectionIndexColor = UIColor.black
        
        //tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ColorCell")
        
        colorList.removeAll()
        
        for color in ThemeColors.allValues {
            let colorName = color.getColors().name.camelCaseToWords()
            colorList.append(colorName.capitalizingFirstLetter())
        }
        
        setCurrentThemeColor()
        
    }
    
    func setCurrentThemeColor() {
        
        colors = Colors.init(main: appData.mainColor!, bg: appData.bgColor!, task1: appData.taskColor1!, task2: appData.taskColor2!, progress: appData.progressColor!)
        
        //let themeColor = appData.appColor
        let darkerThemeColor = colors.bg //appData.appColor.darken(byPercentage: 0.25)
        tableView.backgroundColor = darkerThemeColor
        tableView.separatorColor = colors.bg.darken(byPercentage: Colors.colorLevel4) //appData.appColor.darken(byPercentage: 0.6)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //let cell = tableView.dequeueReusableCell(withIdentifier: "ColorCell", for: indexPath)
        
        if let cell = tableView.cellForRow(at: indexPath as IndexPath) {
            
            if let index = previousCellIndex {
                let previousCell = tableView.cellForRow(at: index)
                previousCell?.accessoryType = .none
            }
            if cell.accessoryType == .checkmark{
                cell.accessoryType = .none
            }
            else{
                cell.accessoryType = .checkmark
                previousCellIndex = indexPath
            }
            
            let selectedCellText = cell.textLabel?.text
            let enumValue = findTheme(for: selectedCellText!)
            selectedEnum = enumValue
            //selectedColor = enumValue.value
            selectedTheme = enumValue.getColors().name
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
   
        //setColor(as: colors[indexPath.row])
        
        print(colorList[indexPath.row])
        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return colorList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ColorCell", for: indexPath)
        
        let cellText = colorList[indexPath.row]
        cell.textLabel?.text = cellText
        
        let camelCase = cellText.wordsToCamelCase()
        let enumValue = findTheme(for: camelCase)
        let theme = enumValue.getColors()
        
        if theme.main == appData.mainColor { //appData.appColor {
            cell.accessoryType = .checkmark
            previousCellIndex = indexPath
        }
        
        let darkerThemeColor = colors.bg //appData.appColor.darken(byPercentage: 0.25)
        cell.backgroundColor = darkerThemeColor
        if appData.darknessCheck(for: darkerThemeColor) {
            cell.textLabel?.textColor = .white
        } else {
            cell.textLabel?.textColor = .black
        }
        
        return cell
    }
        
    func setColor(as color: String) {
    
        if color.range(of:"Dark") == nil {
            switch color {
            case "Black":
                selectedColor = FlatBlack()
            case "Blue":
                selectedColor = FlatBlue()
            case "Brown":
                selectedColor = FlatBrown()
            case "Coffee":
                selectedColor = FlatCoffee()
            case "Forest Green":
                selectedColor = FlatForestGreen()
            case "Gray":
                selectedColor = FlatGray()
            case "Green":
                selectedColor = FlatGreen()
            case "Magenta":
                selectedColor = FlatMagenta()
            case "Maroon":
                selectedColor = FlatMaroon()
            case "Mint":
                selectedColor = FlatMint()
            case "Navy Blue":
                selectedColor = FlatNavyBlue()
            case "Orange":
                selectedColor = FlatOrange()
            case "Pink":
                selectedColor = FlatPink()
            case "Plum":
                selectedColor = FlatPlum()
            case "Powder Blue":
                selectedColor = FlatPowderBlue()
            case "Purple":
                selectedColor = FlatPurple()
            case "Red":
                selectedColor = FlatRed()
            case "Sand":
                selectedColor = FlatSand()
            case "Sky Blue":
                selectedColor = FlatSkyBlue()
            case "Teal":
                selectedColor = FlatTeal()
            case "Watermelon":
                selectedColor = FlatWatermelon()
            case "White":
                selectedColor = FlatWhite()
            case "Yellow":
                selectedColor = FlatYellow()
            default:
                selectedColor = FlatBlue()
            }
        } else {
            switch color {
            case "Dark Black":
                selectedColor = FlatBlackDark()
            case "Dark Blue":
                selectedColor = FlatBlueDark()
            case "Dark Brown":
                selectedColor = FlatBrownDark()
            case "Dark Coffee":
                selectedColor = FlatCoffeeDark()
            case "Dark Forest Green":
                selectedColor = FlatForestGreenDark()
            case "Dark Gray":
                selectedColor = FlatGrayDark()
            case "Dark Green":
                selectedColor = FlatGreenDark()
            case "Dark Magenta":
                selectedColor = FlatMagentaDark()
            case "Dark Maroon":
                selectedColor = FlatMaroonDark()
            case "Dark Mint":
                selectedColor = FlatMintDark()
            case "Dark Orange":
                selectedColor = FlatOrangeDark()
            case "Dark Pink":
                selectedColor = FlatPinkDark()
            case "Dark Plum":
                selectedColor = FlatPlumDark()
            case "Dark Powder Blue":
                selectedColor = FlatPowderBlueDark()
            case "Dark Purple":
                selectedColor = FlatPurpleDark()
            case "Dark Red":
                selectedColor = FlatRedDark()
            case "Dark Sand":
                selectedColor = FlatSandDark()
            case "Dark Sky Blue":
                selectedColor = FlatSkyBlueDark()
            case "Dark Teal":
                selectedColor = FlatTealDark()
            case "Dark Watermelon":
                selectedColor = FlatWatermelonDark()
            default:
                selectedColor = FlatBlue()
            }
            
        }
        
        //appData.saveColorSettingsToDictionary()
        //appData.save()
        
    }
    
    func findTheme(for string: String) -> ThemeColors {
        
        let camelCase = string.wordsToCamelCase()
        print(camelCase)
        
        //let enumValue = ThemeColor(rawValue: camelCase)
        //return ThemeColor(rawValue: camelCase)!
        
        return ThemeColors(rawValue: camelCase)!
    }
    
    func stringValue(forEnum enumValue: Theme) -> String {
        
        let rawString = enumValue.name //.rawValue
        let isDark = rawString.contains("dark")
        let stringValue: String
        
        if isDark {
            stringValue = rawString.camelCaseToWords()
         } else {
            stringValue = rawString.camelCaseToWords()
        }
        
        return stringValue.capitalizingFirstLetter()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        if let theme = selectedEnum, let name = selectedTheme {
            
            let colorString = name.camelCaseToWords()
            appData.appColorName = colorString.capitalizingFirstLetter()
            
            appData.mainColor = theme.getColors().main
            appData.bgColor = theme.getColors().bg
            appData.taskColor1 = theme.getColors().task1
            appData.taskColor2 = theme.getColors().task2
            appData.progressColor = theme.getColors().progress
            
            let data = DataHandler()
            data.saveAppSettings(appData)
            
        }
        
//        if let themeColor = selectedColor {
//            appData.appColor = themeColor
//            //let appDelegate = UIApplication.shared.delegate as! AppDelegate
//            //        appDelegate.setTheme(as: selectedColor!)
//
//            let colorString = selectedEnum?.rawValue.camelCaseToWords()
//            appData.appColorName = colorString!.capitalizingFirstLetter()
//            
//            let data = DataHandler()
//            data.saveAppSettings(appData)
//
//            //appDelegate.appData.saveColorSettingsToDictionary()
//            //appDelegate.appData.save()
//        }
        
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        
//        self.setThemeUsingPrimaryColor(appData.appColor, withSecondaryColor: UIColor.clear, andContentStyle: .contrast)
//        
//    }
    
    override func willMove(toParentViewController parent: UIViewController?) { // tricky part in iOS 10
        //if selectedColor != nil {
        if selectedEnum != nil {
            navigationController?.navigationBar.barTintColor = selectedEnum?.getColors().main
            navigationController?.toolbar.barTintColor = selectedEnum?.getColors().main
        }
        super.willMove(toParentViewController: parent)
    }
    
}

//MARK: - Camel Case Conversion
extension String {
    
    func camelCaseToWords() -> String {
        return unicodeScalars.reduce("") {
            if CharacterSet.uppercaseLetters.contains($1) {
                if $0.count > 0 {
                    return ($0 + " " + String($1))
                }
            }
            return $0 + String($1)
        }
    }
    
    func wordsToCamelCase() -> String {
        guard let first = first else { return "" }
        let camelCase = unicodeScalars.reduce("") {
            if CharacterSet.whitespaces.contains($1) {
                if $0.count > 0 {
                    return ($0)
                }
            }
            return $0 + String($1)
        }
        return String(first).lowercased() + camelCase.dropFirst()
        
    }
    
}

extension String {
    func capitalizingFirstLetter() -> String {
        guard let first = first else { return "" }
        return String(first).uppercased() + dropFirst()

//        let first = String(prefix(1)).capitalized
//        let other = String(dropFirst())
//        return first + other
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
    
}
