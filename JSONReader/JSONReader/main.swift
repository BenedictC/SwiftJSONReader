//
//  main.swift
//  JSONReader
//
//  Created by Benedict Cohen on 07/11/2015.
//  Copyright © 2015 Benedict Cohen. All rights reserved.
//

import Foundation


let reader = JSONReader(object:
    ["arf": "String",
     "foo": [
             "bar": [
                     "arf1": "Arf1BOOM!",
                     "arf2": "ar2Boom!",
                    ]
            ]
    ]
)

let value0: String = reader["arf"].value() { _ in return "" }

let value1 = reader.valueAtPath("foo.bar.arf1") {error in return "default2"}
let value2 = reader.valueAtPath("foo['bar'].arf2", defaultValue: "default2")
let value3: String  = try reader.valueAtPath("arf")

print(value1, value2, value3)
