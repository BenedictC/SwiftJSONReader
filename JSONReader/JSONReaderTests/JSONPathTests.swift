//
//  JSONReaderTests.swift
//  JSONPathTests
//
//  Created by Benedict Cohen on 09/12/2015.
//  Copyright © 2015 Benedict Cohen. All rights reserved.
//

import XCTest
//@testable import JSONReader


class JSONPathTests: XCTestCase {

    //MARK:- Path creation

    func testParsingOfValidPaths() {
        var actual: JSONPathTestWrapper
        var expected: JSONPathTestWrapper

        //Identifer delimiters
        actual   = "arf.foo..Bar.......woof.............."
        expected = ["arf", "foo", "Bar", "woof"]
        XCTAssertEqual(expected, actual)

        //Valid identifer characters
        actual   = "QWERTYUIOPASDFGHJKLZXCVBNM.qwertyuiopasdfghjklzxcvbnm._1234567890.$"
        expected = ["QWERTYUIOPASDFGHJKLZXCVBNM", "qwertyuiopasdfghjklzxcvbnm", "_1234567890", "$"]
        XCTAssertEqual(expected, actual)

        //Subscript/identifier delimiters
        actual = "arf...['foo']arf['foo']....arf['😈']"
        expected = ["arf", "foo", "arf", "foo", "arf", "😈"]
        XCTAssertEqual(expected, actual)

        //self reference
        actual = "[self]"
        expected = [NSNull()]
        XCTAssertEqual(expected, actual)

        //Valid subscript characters/backtick escaping
        actual = "['f``oo']['`'foo']['````foo']['`foo']"
        expected = ["f`oo", "'foo", "``foo", "`foo"]
        XCTAssertEqual(expected, actual)
    }


    func testParsingOfInvalidPaths() {
        var actual:JSONPathTestWrapper
        let expected = JSONPathTestWrapper(components: [], isValid: false)

        //Empty path
        actual = ""
        XCTAssertEqual(expected, actual)

        //Invalid leading delimiter with identifer
        actual = ".arf"
        XCTAssertEqual(expected, actual)

        //Invalid leading delimiter with subscript
        actual = ".['arf']"
        XCTAssertEqual(expected, actual)

        //Unquoted subscript
        actual = "[foo]"
        XCTAssertEqual(expected, actual)

        //Invalid leading identifier character
        actual = "1arf"
        XCTAssertEqual(expected, actual)
    }


    func testEncodeTextAsSubscriptPathComponent() {
        let encodeText = { (text: String) -> ([JSONPath.Component], [JSONPath.Component]) in
            let encodedText = JSONPath.Component.text(text)
            let path = try? JSONPath(path: encodedText.textRepresentation)
            let actual = (path?.components ?? [])
            let expected = [JSONPath.Component.text(text)]
            return (expected, actual)
        }
        var actual: [JSONPath.Component]
        var expected: [JSONPath.Component]

        (expected, actual) = encodeText("`foo")
        XCTAssertEqual(expected, actual)

        (expected, actual) = encodeText("'foo")
        XCTAssertEqual(expected, actual)

        (expected, actual) = encodeText("`'foo")
        XCTAssertEqual(expected, actual)

        (expected, actual) = encodeText("'`foo")
        XCTAssertEqual(expected, actual)
    }
    
}


class JSONPathPerformanceTests: XCTestCase {

    //MARK:- Caching path performance

//    func testInitWithCache() {
//        // This is an example of a performance test case.
//        self.measureBlock {
//            for _ in 0...10000 {
//                let _ = try! JSONPath(path: "boom[self][4].ewrgerbs....afegrsf['erthr`'nwa``ewgre']")
//            }
//        }
//    }
//
//
//    func testInitWithoutCache() {
//        // This is an example of a performance test case.
//        self.measureBlock {
//            for _ in 0...10000 {
//                var components: [JSONPath.Component] = []
//                try! JSONPath.enumerateComponentsInPath("boom[self][4].ewrgerbs....afegrsf['erthr`'nwa``ewgre']") { component, _, _ in
//                    components.append(component)
//                }
//                let _ = JSONPath(components: components)
//            }
//        }
//    }

}
