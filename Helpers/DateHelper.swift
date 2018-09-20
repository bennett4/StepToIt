//
//  Date.swift
//  Steps
//
//  Created by Matt. on 8/26/18.
//  Copyright © 2018 mbenn. All rights reserved.
//

import Foundation

class DateHelper {
    
    func getCurrentMonth() -> Int {
        let components = Calendar.current.dateComponents([.month], from: Date())
        return components.month!
    }
    
    func getCurrentDay() -> Int {
        let components = Calendar.current.dateComponents([.day], from: Date())
        return components.day!
    }
    
    func getCurrentYear() -> Int {
        let components = Calendar.current.dateComponents([.year], from: Date())
        return components.year!
    }
    
    func getSelectedDate(year: Int, month: Int, day: Int) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        let result = formatter.date(from: "\(year)" + "/" + "\(month)" + "/" + "\(day)")
        
        var selectedDate: Date
        if (result != nil) {
            selectedDate = result!
        }
        else {
            selectedDate = Date()
        }
        
        return selectedDate
    }

} // end of class DateHelper
