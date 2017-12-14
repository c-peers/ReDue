//
//  Enums.swift
//  ReDue
//
//  Created by Chase Peers on 11/29/17.
//  Copyright © 2017 Chase Peers. All rights reserved.
//

import Foundation
import Chameleon
import AudioToolbox

/* Found on theswiftdev.com allows the enums to return a list of all cases */
public protocol EnumCollection: Hashable {
    static func cases() -> AnySequence<Self>
    static var allValues: [Self] { get }
}

public extension EnumCollection {
    
    public static func cases() -> AnySequence<Self> {
        return AnySequence { () -> AnyIterator<Self> in
            var raw = 0
            return AnyIterator {
                let current: Self = withUnsafePointer(to: &raw) { $0.withMemoryRebound(to: self, capacity: 1) { $0.pointee } }
                guard current.hashValue == raw else {
                    return nil
                }
                raw += 1
                return current
            }
        }
    }
    
    public static var allValues: [Self] {
        return Array(self.cases())
    }
}

/* Used when throwing up alert popups.
   This usually is a way to make sure that action is
   either taken or confirmed by the user.
 */
enum AlertType {
    case empty, duplicate
    case missed, complete
    case delete, upgradeNeeded, reset
}

/* Used to determine device type */
enum DeviceType {
    case legacy
    case normal
    case large
    case X
}

enum TableCellType {
    case header, audio, vibration
}

/* */
enum AudioAlert: String, EnumCollection {
    case a = "Corsica.wav"
    case b = "Nuclear.mp3"
    case c = "School_Bell.wav"
    case d = "Short_Buzzer.wav"
    case e = "e.mp3"
    case f = "f.mp3"
    case g = "g.mp3"
    case h = "h.mp3"
    case i = "i.mp3"
    case j = "j.mp3"
    case k = "k.mp3"
    case l = "l.mp3"
    
    case none
}

typealias Vibrate = () -> ()

enum VibrateAlert: String, EnumCollection {
    case short = "Short"
    case long = "Long"
    case none
    
    var run: Vibrate {
        get {
            switch self {
            case .short:
                return {self.vibrate(forLength: 0.2, pause: 0.1)}
            case .long:
                return {self.vibrate(forLength: 0.4, pause: 0.2)}
            default:
                return { }
            }
        }
    }
    
    func vibrate(forLength time: Double, pause: Double) {
        var timer = Timer()
        
        for _ in 1...3 {

            timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(time), repeats: false, block: { _ in
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        })
        timer.invalidate()
    
        let when = DispatchTime.now() + pause
        DispatchQueue.main.asyncAfter(deadline: when) {
            print("Pause after vibration")
        }
            
        }

    }
    
}


/* Used for whatever cell type the user has chosen */
enum CellType {
    case circular
    case line
}

/* A list of all colors used in the app
   Each case has the color stored as a value */
//MARK: - Theme Color enum
enum ThemeColor: String {
    
    case blue, brown, coffee, forestGreen, gray, green, magenta, maroon, mint, navyBlue, pink, powderBlue, purple, red, sand, skyBlue, teal, watermelon, white
    case darkBlue, darkCoffee, darkGray, darkGreen, darkMagenta, darkMint, darkOrange, darkPink, darkPowderBlue, darkPurple, darkRed, darkSand, darkSkyBlue, darkTeal, darkWatermelon
    
}

extension ThemeColor {
    var value: UIColor {
        get {
            switch self {
            case .blue:
                return FlatBlue()
            case .brown:
                return FlatBrown()
            case .coffee:
                return FlatCoffee()
            case .forestGreen:
                return FlatForestGreen()
            case .gray:
                return FlatGray()
            case .green:
                return FlatGreen()
            case .magenta:
                return FlatMagenta()
            case .maroon:
                return FlatMaroon()
            case .mint:
                return FlatMint()
            case .navyBlue:
                return FlatNavyBlue()
            case .pink:
                return FlatPink()
            case .powderBlue:
                return FlatPowderBlue()
            case .purple:
                return FlatPurple()
            case .red:
                return FlatRed()
            case .sand:
                return FlatSand()
            case .skyBlue:
                return FlatSkyBlue()
            case .teal:
                return FlatTeal()
            case .watermelon:
                return FlatWatermelon()
            case .white:
                return FlatWhite()
            case .darkBlue:
                return FlatBlueDark()
            case .darkCoffee:
                return FlatCoffeeDark()
            case .darkGray:
                return FlatGrayDark()
            case .darkGreen:
                return FlatGreenDark()
            case .darkMagenta:
                return FlatMagentaDark()
            case .darkMint:
                return FlatMintDark()
            case .darkOrange:
                return FlatOrangeDark()
            case .darkPink:
                return FlatPinkDark()
            case .darkPowderBlue:
                return FlatPowderBlueDark()
            case .darkPurple:
                return FlatPurpleDark()
            case .darkRed:
                return FlatRedDark()
            case .darkSand:
                return FlatSandDark()
            case .darkSkyBlue:
                return FlatSkyBlueDark()
            case .darkTeal:
                return FlatTealDark()
            case .darkWatermelon:
                return FlatWatermelonDark()
            }
        }
    }
}