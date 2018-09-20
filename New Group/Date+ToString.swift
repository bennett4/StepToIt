//
//  Date+ToString.swift
//  Steps
//
//  Created by Matt. on 7/24/18.
//  Copyright © 2018 mbenn. All rights reserved.
//

import Foundation

extension Date
{
    func toString( dateFormat format  : String ) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}
