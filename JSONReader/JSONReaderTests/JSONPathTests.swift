//
//  JSONReaderTests.swift
//  JSONPathTests
//
//  Created by Benedict Cohen on 09/12/2015.
//  Copyright © 2015 Benedict Cohen. All rights reserved.
//

import XCTest
//@testable import JSONReader


//TODO:
//Test parsing of valid paths
//Test parsing of invalid paths
//Test backtick escaping
//Test encodeTextAsSubscriptPathComponent
//Test cached paths



class JSONPathTests: XCTestCase {

//MARK:- Caching path performance

    func testInitWithCache() {
        // This is an example of a performance test case.
        self.measureBlock {
            for _ in 0...100000 {
                let _ = try! JSONPath(path: "boom[self][4].ewrgerbs....afegrsf['erthr`'nwa``ewgre']")
            }
        }
    }


    func testInitWithoutCache() {
        // This is an example of a performance test case.
        self.measureBlock {
            for _ in 0...100000 {
                var components: [JSONPath.Component] = []
                try! JSONPath.enumerateComponentsInPath("boom[self][4].ewrgerbs....afegrsf['erthr`'nwa``ewgre']") { component, _, _ in
                    components.append(component)
                }
                let _ = JSONPath(components: components)
            }
        }
    }
    
}
