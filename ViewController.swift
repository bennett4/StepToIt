//
//  ViewController.swift
//  Steps
//
//  Created by Matt. on 6/27/18.
//  Copyright © 2018 mbenn. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var stepsLabel: UILabel!
    @IBOutlet weak var monthPicker: UIPickerView!
    @IBOutlet weak var dayPicker: UIPickerView!
    @IBOutlet weak var yearPicker: UIPickerView!
    
    var healthStore = HKHealthStore()
    var dateHelper = DateHelper()
    
    var monthArray = [Int]()
    var dayArray = [Int]()
    var yearArray = [Int]()
    
    var selectedYear: Int = 0
    var selectedMonth: Int = 0
    var selectedDay: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeDateArrays()
        
        // Check to see if the app already has permissions
        if (appIsAuthorized()) {
            displaySteps()
        } // end if
        
        else {
            // Don't have permission, yet
            handlePermissions()
        } // end else
        
        adjustLabelText()
    } // end of function viewDidLoad

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    } // end of method didReceiveMemoryWarning
    
    
    func handlePermissions() {
        
        // Access Step Count
        let healthKitTypes: Set = [ HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)! ]
        
        // Check Authorization
        healthStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { (bool, error) in
            
            if (bool) {
                
                // Authorization Successful
                self.displaySteps()
                
            } // end if
            
        } // end of checking authorization
        
    } // end of func handlePermissions
    
    
    func displaySteps() {
        
        getSteps { (result) in
            DispatchQueue.main.async {
                
                var stepCount = String(Int(result))
                
                // Did not retrieve proper step count
                if (stepCount == "-1") {
                    
                    // If we do not have permissions
                    if (!self.appIsAuthorized()) {
                        self.stepsLabel.text = "Settings  >  Privacy  >  Health  >  Steps"
                    } // end if
                    
                    // Else, no data to show
                    else {
                        self.stepsLabel.text = "0"
                    } // end else
                    
                    return
                } // end if
                
                if (stepCount.count > 6) {
                    // Add a comma if the user managed to take at least 1,000,000 steps.
                    // He/she also deserves much more than a comma.
                    stepCount.insert(",", at: stepCount.index(stepCount.startIndex, offsetBy: stepCount.count - 6))
                } // end if
                
                if (stepCount.count > 3) {
                    // Add a comma if the user took at least 1,000 steps.
                    stepCount.insert(",", at: stepCount.index(stepCount.startIndex, offsetBy: stepCount.count - 3))
                } // end if
                
                self.stepsLabel.text = String(stepCount)
                
            }
        }
        
    } // end of func displaySteps
    
    
    func getSteps(completion: @escaping (Double) -> Void) {
        
        let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        let selectedDate = dateHelper.getSelectedDate(year: selectedYear, month: selectedMonth, day: selectedDay)
        
        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        
        var interval = DateComponents()
        interval.day = 1
        
        let query = HKStatisticsCollectionQuery(quantityType: stepsQuantityType,
                                                quantitySamplePredicate: nil,
                                                options: [.cumulativeSum],
                                                anchorDate: startOfDay,
                                                intervalComponents: interval)
        query.initialResultsHandler = { _, result, error in
            
            var resultCount = -1.0
            
            guard let result = result else {
                completion(resultCount)
                return
            }
            
            result.enumerateStatistics(from: startOfDay, to: selectedDate) { statistics, _ in
                if let sum = statistics.sumQuantity() {
                    // Get steps (they are of double type)
                    resultCount = sum.doubleValue(for: HKUnit.count())
                }
                
                // Return
                DispatchQueue.main.async {
                    completion(resultCount)
                }
            }
            
        }
        
        query.statisticsUpdateHandler = {
            query, statistics, statisticsCollection, error in
            
            // If new statistics are available
            if let sum = statistics?.sumQuantity() {
                let resultCount = sum.doubleValue(for: HKUnit.count())
                DispatchQueue.main.async {
                    completion(resultCount)
                }
            }
            
        }
        
        healthStore.execute(query)
        
    } // end of func getSteps
    
    
    func appIsAuthorized() -> Bool {
        if (self.healthStore.authorizationStatus(for: HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!) == .sharingAuthorized) {
            return true
        }
        else {
            return false
        }
    } // end of method appIsAuthorized
    
    
    func initializeDateArrays() {
        for i in 1...12 {
            monthArray.append(i)
        }
        
        for i in 1...31 {
            dayArray.append(i)
        }
        
        let components = Calendar.current.dateComponents([.year], from: Date())
        let year =  components.year
        
        for i in 2014...year! {
            yearArray.append(i)
        }
        
        self.monthPicker.delegate = self
        self.monthPicker.dataSource = self
        self.dayPicker.delegate = self
        self.dayPicker.dataSource = self
        self.yearPicker.delegate = self
        self.yearPicker.dataSource = self
        
        self.monthPicker.selectRow(dateHelper.getCurrentMonth() - 1, inComponent: 0, animated: false)
        self.dayPicker.selectRow(dateHelper.getCurrentDay() - 1, inComponent: 0, animated: false)
        self.yearPicker.selectRow(yearArray.count - 1, inComponent: 0, animated: false)
        
        selectedYear = yearArray[self.yearPicker.selectedRow(inComponent: 0)]
        selectedMonth = monthArray[self.monthPicker.selectedRow(inComponent: 0)]
        selectedDay = dayArray[self.dayPicker.selectedRow(inComponent: 0)]
    } // end of method InitializeDateArrays
    
    func adjustLabelText() {
        // Center text within each label
        stepsLabel.textAlignment = NSTextAlignment.center
        
        // Resize font of stepsLabel if it is too large
        stepsLabel.numberOfLines = 1
        stepsLabel.minimumScaleFactor = 0.1
        stepsLabel.adjustsFontSizeToFitWidth = true;
    }
    
    
    func getAvailableDays(month: Int) -> Array<Int> {
        var daysForSpecifiedDay = dayArray
        
        let components = Calendar.current.dateComponents([.month, .day], from: Date())
        let currentDay =  components.day
        let currentMonth =  components.month
        
        var isCurrentMonth = false
        
        // If the selected row in yearPicker is the current year
        if (yearPicker.selectedRow(inComponent: 0) == yearArray.count - 1) {
            
            // If the selected row in monthPicker is the current month
            if (monthPicker.selectedRow(inComponent: 0)+1 == monthArray[currentMonth!-1]) {
                
                isCurrentMonth = true
                daysForSpecifiedDay.removeSubrange(currentDay!...daysForSpecifiedDay.count-1)
                
            }
        }
        
        // If the selected row in monthPicker is not the current month
        if (!isCurrentMonth) {
            let thirtyDayMonths = [4, 6, 9, 11]
            
            // If a 30 Day Month
            if (thirtyDayMonths.contains(month)) {
                daysForSpecifiedDay.removeLast()
            }
            // If February
            else if (month == 2) {
                for _ in 1...3 {
                    daysForSpecifiedDay.removeLast()
                }
            }
        } // end if
        
        return daysForSpecifiedDay
    } // end of func getDays
    
    
    func getAvailableMonths() -> Array<Int> {
        var monthsForSpecifiedYear = monthArray
        
        let component = Calendar.current.dateComponents([.month], from: Date())
        let month =  component.month
        
        // If the selected row is the current year
        if (yearPicker.selectedRow(inComponent: 0) == yearArray.count - 1) {
            for _ in 1...(12-month!) {
                monthsForSpecifiedYear.removeLast()
            }
        }
        return monthsForSpecifiedYear
    }
    
    
    // UIPickerView Methods
    
    // Number of Columns in a Single Picker
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        // Hide Top and Bottom Border of Each UIPickerView
        pickerView.subviews.forEach({
            $0.isHidden = $0.frame.height < 1.0
        })
        return 1
    }
    
    // Number of Items in the PickerView
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == yearPicker {
            return yearArray.count
        }
        else if pickerView == monthPicker {
            return getAvailableMonths().count
        }
        else {
            return getAvailableDays(month: (monthPicker.selectedRow(inComponent: 0) + 1)).count
        }
    }
    
    // What Is Displayed
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == yearPicker {
            return String(yearArray[row])
        }
        else if pickerView == monthPicker {
            return String(monthArray[row])
        }
        else {
            return String(dayArray[row])
        }
    }
    
    // Row Changed
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == yearPicker {
            selectedYear = yearArray[self.yearPicker.selectedRow(inComponent: 0)]
            monthPicker.reloadAllComponents()
            selectedMonth = monthArray[self.monthPicker.selectedRow(inComponent: 0)]
            dayPicker.reloadAllComponents()
        }
        else if pickerView == monthPicker {
            selectedMonth = monthArray[self.monthPicker.selectedRow(inComponent: 0)]
            dayPicker.reloadAllComponents()
        }
        selectedDay = dayArray[self.dayPicker.selectedRow(inComponent: 0)]
        displaySteps()
    }
    
    // Font Size
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label = UILabel()
        if let v = view {
            label = v as! UILabel
        }
        label.font = UIFont (name: "Helvetica Neue", size:40)
        if (pickerView == yearPicker) {
            label.text =  String(yearArray[row])
        }
        else if (pickerView == monthPicker) {
            label.text =  String(monthArray[row])
        }
        else {
            label.text =  String(dayArray[row])
        }
        label.textAlignment = .center
        return label
    }
    
    // Set Height of Row of Each UIPickerView
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 50
    }
    
} // end of class ViewController
