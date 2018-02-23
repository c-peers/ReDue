//
//  TaskStatsViewController.swift
//  RepeatingTasks
//
//  Created by Chase Peers on 9/11/17.
//  Copyright © 2017 Chase Peers. All rights reserved.
//

import UIKit
import Charts
import Chameleon

class TaskStatsViewController: UIViewController, UIScrollViewDelegate {

    //@IBOutlet weak var missedTimeHistory: BarChartView!
    @IBOutlet weak var completedTimeHistory: BarChartView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var bgView: UIView!
    //@IBOutlet weak var missedTimeHistoryLabel: UILabel!
    @IBOutlet weak var completedTimeHistoryLabel: UILabel!
    @IBOutlet weak var statisticsTitleLabel: UILabel!
    @IBOutlet var statsNameLabels: [UILabel]!
    @IBOutlet var statsValueLabels: [UILabel]!
        
    //var taskHistory
    var statCharts: [UIView: String] {
        return [/*missedTimeHistory: "Missed Time Bar Chart", */completedTimeHistory: "Completed Time Bar Chart"]
    }
    
    let nameLabels = ["Task Time", "   Completed", "   Missed", "   Forfeited", "Total Days", "    Complete", "    Partial Complete", "    Missed", "Current Streak", "Best Streak"]

//    let nameLabels = ["Task Time", "Completed Task Time", "Missed Task Time", "Total Days", "Total Days (Complete)", "Total Days (Partial Complete", "Total Days (Missed)", "Current Streak", "Best Streak"]

    var valueLabels = ["0", "0", "0", "0", "0", "0", "0", "0", "0", "0"]
    
    var accessDates = [String]()
    
    var task = Task()
    var appData = AppData()

    var colors = Colors(main: HexColor("247BA0")!, bg: FlatWhite(), task1: HexColor("70C1B3")!, task2: HexColor("B2DBBF")!, progress: HexColor("FF1654")!)
    
    // MARK: - View and Init
    override func viewWillAppear(_ animated: Bool) {
        scrollView.delegate = self
        scrollView.contentSize.width = view.bounds.width
        scrollView.contentSize.height = CGFloat(700)

        //navigationController?.toolbar.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        colors = Colors.init(main: appData.mainColor!, bg: appData.bgColor!, task1: appData.taskColor1!, task2: appData.taskColor2!, progress: appData.progressColor!)
        
        let darkerThemeColor = colors.bg //.darken(byPercentage: Colors.darkLevelOne) //appData.appColor.darken(byPercentage: 0.25)
        view.backgroundColor = darkerThemeColor
        scrollView.backgroundColor = darkerThemeColor
        bgView.backgroundColor = darkerThemeColor
        
        //setLabelColor(for: missedTimeHistoryLabel)
        setLabelColor(for: completedTimeHistoryLabel)
        setLabelColor(for: statisticsTitleLabel)
 
        getAccessDates()
        
        setStatNameLabels()
        setStatValues()
        
        chartInit()
        
    }
    
    func getAccessDates() {

        let taskDates = task.previousDates
        var dates = [String]()
        
        for x in 0..<taskDates.count {
            let date = taskDates[x]
            let formattedDate = task.set(date: date, as: "MM/dd")
            dates.append(formattedDate)
        }
        accessDates = dates
    }
    
    func setLabelColor(for label: UILabel) {
        
        let darkerThemeColor = colors.darkMain //appData.appColor.darken(byPercentage: 0.25)
        if appData.darknessCheck(for: colors.bg) {
            label.textColor = UIColor.white
        } else {
            label.textColor = UIColor.black
        }
        
    }
    
//    func updateFont() {
//        let ctx = NSStringDrawingContext()
//        ctx.minimumScaleFactor = 1.0
//        let startingFont: UIFont? = labelLong.font
//        let fontName: String? = startingFont?.fontName
//        let startingSize: CGFloat? = startingFont?.pointSize
//        var i = startingSize * 10
//        while i > 1 {
//            // multiply by 10 so we can adjust font by tenths of a point with each iteration
//            let font = UIFont(name: fontName!, size: i / 10)
//            let textRect: CGRect = labelLong.text.boundingRect(with: labelLong.frame.size, options: .truncatesLastVisibleLine, attributes: [.font: font], context: ctx)
//            if textRect.size.width <= labelLong.textRect(forBounds: labelLong.bounds, limitedToNumberOfLines: 1).size.width {
//                print("Font size is: \(i / 10)")
//                labelShort.font = UIFont(name: fontName!, size: i / 10)
//                break
//            }
//            i -= 1
//        }
//    }

    func setStatNameLabels() {
        
        for label in statsNameLabels {
            let index = statsNameLabels.index(of: label)
            label.text = nameLabels[index!]
            setLabelColor(for: label)
        }
        
    }
    
    func setStatValues() {
        
        valueLabels[0] = String(task.totalTime)
        valueLabels[1] = String(task.completedTime)
        valueLabels[2] = String(task.missedTime)
        valueLabels[3] = String(task.forfeitedTime)
        valueLabels[4] = String(task.totalDays) + " Days"
        valueLabels[5] = String(task.fullDays) + " Days"
        valueLabels[6] = String(task.partialDays) + " Days"
        valueLabels[7] = String(task.missedDays) + " Days"
        valueLabels[8] = String(task.currentStreak) + " Days"
        valueLabels[9] = String(task.bestStreak) + " Days"

        for label in statsValueLabels {
            setLabelColor(for: label)
            guard let index = statsValueLabels.index(of: label) else { return }
            
            // The first four labels could have multiple units
            if index < 4 {
                label.text = formatLabel(withData: valueLabels[index])
            } else {
                label.text = valueLabels[index]
            }
        }
        
//        var taskStats = [String: Double]()
//
//        if let statsCheck = taskData.taskStatsDictionary[task] {
//            taskStats = statsCheck
//        }
//
//        for label in statsValueLabels {
//
//            setLabelColor(for: label)
//
//            for (key, value) in taskStats {
//
//                switch key {
//                case TaskData.totalTaskTimeKey:
//                    valueLabels[0] = String(value) + " Seconds"
//                case TaskData.completedTaskTimeKey:
//                    valueLabels[1] = String(value) + " Seconds"
//                case TaskData.missedTaskTimeKey:
//                    valueLabels[2] = String(value) + " Seconds"
//                case TaskData.totalTaskDaysKey:
//                    valueLabels[3] = String(Int(value)) + " Days"
//                case TaskData.fullTaskDaysKey:
//                    valueLabels[4] = String(Int(value)) + " Days"
//                case TaskData.partialTaskDaysKey:
//                    valueLabels[5] = String(Int(value)) + " Days"
//                case TaskData.missedTaskDaysKey:
//                    valueLabels[6] = String(Int(value)) + " Days"
//                case TaskData.currentStreakKey:
//                    valueLabels[7] = String(value) + " Days"
//                case TaskData.bestStreakKey:
//                    valueLabels[8] = String(value) + " Days"
//                default:
//                    print("Error")
//                }
//
//                let index = statsValueLabels.index(of: label)
//                label.text = String(valueLabels[index!])
//
//            }
//
//        }
        
    }
    
    /* Time lables will be set up to months.
       I doubt people will do years worth of a task. */
    func formatLabel(withData dataString: String) -> String {
        
        let data = Double(dataString)
        
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.month, .day ,.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .dropAll

        guard let string = formatter.string(from: data!.rounded()) else { return "" }

        return string
        
    }
    
    // MARK: - Chart Functions

//    func setMissedChart() {
//
//        missedTimeHistory.scaleYEnabled = false
//        missedTimeHistory.scaleXEnabled = true
//        missedTimeHistory.dragEnabled = true
//        missedTimeHistory.setVisibleXRangeMaximum(5.0)
//        missedTimeHistory.moveViewToX(5.0)
//        missedTimeHistory.rightAxis.enabled = true
//        missedTimeHistory.leftAxis.enabled = false
//
//        missedTimeHistory.chartDescription?.enabled = false
//        missedTimeHistory.legend.enabled = false
//        missedTimeHistory.xAxis.labelPosition = .bottom
//
//        let xAxis = missedTimeHistory.xAxis
//        xAxis.granularity = 1.0
//        xAxis.drawGridLinesEnabled = false
//        xAxis.centerAxisLabelsEnabled = false
//
//        xAxis.valueFormatter = IndexAxisValueFormatter(values: accessDates)
//
//        let leftAxis = missedTimeHistory.getAxis(.left)
//        let rightAxis = missedTimeHistory.getAxis(.right)
//
//        leftAxis.drawLabelsEnabled = false
//        rightAxis.drawLabelsEnabled = true
//
//        rightAxis.valueFormatter = self
//        rightAxis.granularity = 1.0
//
//        leftAxis.axisMinimum = 0.0
//        rightAxis.axisMinimum = 0.0
//
//        let darkerThemeColor = colors.darkMain //appData.appColor.darken(byPercentage: 0.25)
//        if appData.darknessCheck(for: colors.bg) {
//            xAxis.labelTextColor = UIColor.white
//            rightAxis.labelTextColor = UIColor.white
//            missedTimeHistory.noDataTextColor = .white
//        } else {
//            xAxis.labelTextColor = UIColor.black
//            rightAxis.labelTextColor = UIColor.black
//            missedTimeHistory.noDataTextColor = .black
//        }
//
//    }
    
    func setCompletedChart() {
        
        completedTimeHistory.scaleYEnabled = false
        completedTimeHistory.scaleXEnabled = true
        completedTimeHistory.dragEnabled = true
        completedTimeHistory.setVisibleXRangeMaximum(5.0)
        completedTimeHistory.moveViewToX(5.0)
        completedTimeHistory.rightAxis.enabled = true
        completedTimeHistory.leftAxis.enabled = false
        
        completedTimeHistory.chartDescription?.enabled = false
        completedTimeHistory.legend.enabled = false
        completedTimeHistory.xAxis.labelPosition = .bottom

        let xAxis = completedTimeHistory.xAxis
        xAxis.granularity = 1.0
        xAxis.drawGridLinesEnabled = false
        xAxis.centerAxisLabelsEnabled = false
        
        xAxis.valueFormatter = IndexAxisValueFormatter(values: accessDates)
        
        let leftAxis = completedTimeHistory.getAxis(.left)
        let rightAxis = completedTimeHistory.getAxis(.right)
        
        leftAxis.drawLabelsEnabled = false
        rightAxis.drawLabelsEnabled = true
        
        rightAxis.valueFormatter = self
        rightAxis.granularity = 1.0
        
        leftAxis.axisMinimum = 0.0
        rightAxis.axisMinimum = 0.0

        let darkerThemeColor = colors.darkMain //appData.appColor.darken(byPercentage: 0.25)
        if appData.darknessCheck(for: colors.bg) {
            xAxis.labelTextColor = UIColor.white
            rightAxis.labelTextColor = UIColor.white
            completedTimeHistory.noDataTextColor = .white
        } else {
            xAxis.labelTextColor = UIColor.black
            rightAxis.labelTextColor = UIColor.black
            completedTimeHistory.tintColor = UIColor.black
            completedTimeHistory.noDataTextColor = .white
        }

    }
    
//    func setXAxis(for chartView: Any, as type: String) {
//        
//        var chart: AnyObject
//        
//        switch type {
//        case "Line":
//            chart = chartView as! LineChartView
//        case "Bar":
//            chart = chartView as! BarChartView
//        default:
//            return
//        }
//        
//        var xAxis = chart.xAxis
//        xAxis!.granularity = 1.0
//        xAxis!.drawGridLinesEnabled = false
//        xAxis!.centerAxisLabelsEnabled = false
//        
//        xAxis!.valueFormatter = IndexAxisValueFormatter(values: accessDates)
//        //xAxis?.valueFormatter = IndexAxisValueFormatter(values: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"])
//        
//    }
//    
//    func setYAxis(for chartView: Any, as type: String) {
//     
//        var chart: AnyObject
//
//        switch type {
//        case "Line":
//            chart = chartView as! LineChartView
//        case "Bar":
//            chart = chartView as! BarChartView
//        default:
//            return
//        }
//
//        let leftAxis = chart.getAxis(.left)
//        let rightAxis = chart.getAxis(.right)
//        
//        leftAxis.drawLabelsEnabled = false
//        rightAxis.drawLabelsEnabled = false
//        
//        leftAxis.axisMinimum = 0.0
//        rightAxis.axisMinimum = 0.0
//        
//    }

//    func setChartView(for chartView: Any, as type: String) {
//        
//        var chart: AnyObject
//        
//        switch type {
//        case "Line":
//            chart = chartView as! LineChartView
//        case "Bar":
//            chart = chartView as! BarChartView
//        default:
//            return
//        }
//
//        chart.chartDescription??.enabled = false
//        chart.legend.enabled = false
//        chart.xAxis.labelPosition = .bottom
//        //recentTaskHistory.drawValueAboveBarEnabled = false
//        //recentTaskHistory.borderLineWidth = 1.5
//        //recentTaskHistory.borderColor = UIColor.flatBlackDark
//        
//        chart.rightAxis.enabled = false
//        chart.leftAxis.enabled = false
//        //chart.drawGridBackgroundEnabled = false
//
//    }
    
    func chartInit() {
        
        //setMissedChart()
        setCompletedChart()

        for (chart, type) in statCharts {
            
            //setXAxis(for: chart, as: type)
            //setYAxis(for: chart, as: type)
            //setChartView(for: chart, as: type)
            loadBarChartData(chart: chart as! BarChartView, as: type)
            //if type.contains("Line") {
                //loadLineChartData(chart: chart as! LineChartView, as: type)
            //} else if type.contains("Bar") {
                
            //}
            
        }
        
    }
    
    func loadBarChartData(chart: BarChartView, as type: String) {
        
        var barChartEntry  = [BarChartDataEntry]() //this is the Array that will eventually be displayed on the graph.
        
        let taskAccess = task.previousDates
        
        var dataSet = [Double]()
        
        for date in taskAccess {

            var entry = 0.0
            
            if type.contains("Missed") {
                entry = task.missedTimeHistory[date]! / 60
            } else if type.contains("Complete") {
                entry = task.completedTimeHistory[date]! / 60
            }
         
            dataSet.append(entry)
            
        }

        for i in 0..<dataSet.count {
        //for i in 0..<testData.count {
            var value: BarChartDataEntry
            
            value = BarChartDataEntry(x: Double(i), y: dataSet[i])
            //value = BarChartDataEntry(x: Double(i), y: Double(testData[i]))
            
            barChartEntry.append(value) // here we add it to the data set
            
        }
        
        let bar = BarChartDataSet(values: barChartEntry, label: "") //Here we convert lineChartEntry to a LineChartDataSet
        
        bar.colors = ChartColorTemplates.pastel()
        
        let darkerThemeColor = colors.darkMain //appData.appColor.darken(byPercentage: 0.25)
        if appData.darknessCheck(for: colors.bg) {
            bar.valueColors = [UIColor.white]
        } else {
            bar.valueColors = [UIColor.black]
        }
        
        let data = BarChartData() //This is the object that will be added to the chart
        
        data.addDataSet(bar) //Adds the line to the dataSet
        data.setValueFormatter(self)
        
        if taskAccess.count == 1 {
            data.barWidth = 0.4
        }

        chart.animate(xAxisDuration: 2.0, yAxisDuration: 2.0)
        
        chart.data = data //finally - it adds the chart data to the chart and causes an update
        
        //        } else {
        //            recentTaskHistory.data = nil
        //        }
        
    }
    
}

// MARK: - Bar Value Formatter
extension TaskStatsViewController: IValueFormatter {
    
    func stringForValue(_ value: Double,
                        entry: ChartDataEntry,
                        dataSetIndex: Int,
                        viewPortHandler: ViewPortHandler?) -> String {
        
        var stringValue = ""
        
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

// MARK: - Axis Value Formatter
extension TaskStatsViewController: IAxisValueFormatter {
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {

        return String(Int(value)) + "m"
        
    }
    

    

}
