//
//  main.swift
//  JSONReader
//
//  Created by Benedict Cohen on 07/11/2015.
//  Copyright © 2015 Benedict Cohen. All rights reserved.
//

import Foundation


let reader = JSONReader(rootValue:
    ["arf": "String",
     "foo": [
             "bar": [
                     "arf1": "Arf1BOOM!",
                     "arf2": "ar2Boom!",
                    ]
            ]
    ]
)

let value0: String = reader["arf"].value() ?? ""

let value1 = try? reader.valueAtPath("foo.bar.arf1") ?? "default2"
let value2 = try? reader.valueAtPath("foo['bar'].arf2") ?? "default2"
let value3: String  = try reader.valueAtPath("arf")

//print(value1, value2, value3)

let path = try! JSONPath(path: "boom[self][4].ewrgerbs....afegrsf['erthr`'nwa``ewgre']")

print(path)
print(try! JSONPath(path: "boom[self][4].ewrgerbs....afegrsf['erthr`'nwa``ewgre']"))
print(try! JSONPath(path: "boom[self][4].ewrgerbs....afegrsf['erthr`'nwa``ewgre']"))
