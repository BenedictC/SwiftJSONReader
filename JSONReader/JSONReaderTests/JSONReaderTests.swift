//
//  JSONReaderTests.swift
//  JSONReaderTests
//
//  Created by Benedict Cohen on 09/12/2015.
//  Copyright © 2015 Benedict Cohen. All rights reserved.
//

import XCTest


class JSONReaderTests: XCTestCase {

    func testObjectProperty() {
        //Given
        let reader = JSONReader(rootValue: [])

        //Valid object
        XCTAssertNotNil(reader.rootValue)
        XCTAssertFalse(reader.isEmpty)

        //InvalidObject
        let emptyReader = JSONReader(rootValue: nil)
        XCTAssertNil(emptyReader.rootValue)
        XCTAssertTrue(emptyReader.isEmpty)
    }


    func testInitWithJSONValidData() {
        //Given
        let expected = ["foo": "bar"] as NSDictionary
        let data = (try? JSONSerialization.data(withJSONObject: expected, options: [])) ?? Data()

        //When
        let reader = try? JSONReader(data: data)
        let actual: NSDictionary = (reader?.rootValue as? NSDictionary) ?? NSDictionary()

        //Then
        XCTAssertEqual(actual, expected)
    }


    func testInitWithJSONInvalidData() {
        //Given
        let data = Data()

        //When
        let reader = try? JSONReader(data: data)

        //Then
        XCTAssertNil(reader)
    }


    func testInitWithJSONDataWithFragmentTrue() {
        //Given
        let expected = NSNull()
        let data = "null".data(using: String.Encoding.utf8)!

        //When
        let reader = try? JSONReader(data: data, allowFragments: true)
        let actual = reader?.rootValue as? NSNull

        //Then
        if let actual = actual {
            XCTAssertEqual(actual, expected)
        } else {
            XCTFail()
        }
    }


    func testInitWithJSONDataWithFragmentFalse() {
        //Given
        let data = "null".data(using: String.Encoding.utf8)!

        //When
        let reader = try? JSONReader(data: data, allowFragments: false)

        //Then
        XCTAssertNil(reader)
    }

    
    func testValue() {
        //Given
        let expected: Float = 4.5
        let reader = JSONReader(rootValue: expected)

        //When
        let actual = reader.value() as Float?

        //Then
        XCTAssertEqual(expected, actual)
    }


    func testIsValidPositiveIndex() {
        //Given
        let array = [0,1,2]
        let reader = JSONReader(rootValue: array)

        //When
        let actual = reader.isValidIndex(array.count - 1)

        //Then
        let expected = true
        XCTAssertEqual(actual, expected)
    }


    func testIsInvalidPositiveIndex() {
        //Given
        let array = [0,1,2]
        let reader = JSONReader(rootValue: array)

        //When
        let actual = reader.isValidIndex(Int.max)

        //Then
        let expected = false
        XCTAssertEqual(actual, expected)
    }


    func testIsValidNegativeIndex() {
        //Given
        let array = [0,1,2]
        let reader = JSONReader(rootValue: array)

        //When
        let actual = reader.isValidIndex(-array.count)

        //Then
        let expected = true
        XCTAssertEqual(actual, expected)
    }


    func testIsInvalidNegativeIndex() {
        //Given
        let array = [0,1,2]
        let reader = JSONReader(rootValue: array)

        //When
        let actual = reader.isValidIndex(Int.min)

        //Then
        let expected = false
        XCTAssertEqual(actual, expected)
    }


    func testValidPositiveNumericSubscript() {
        //Given
        let array = ["zero", "one", "two"]
        let reader = JSONReader(rootValue: array)

        //When
        let actual = reader[0].rootValue as? NSObject

        //Then
        let expected = JSONReader(rootValue: array.first!).rootValue as? NSObject
        XCTAssertEqual(actual, expected)
    }


    func testInvalidPositiveNumericSubscript() {
        //Given
        let array = ["zero", "one", "two"]
        let reader = JSONReader(rootValue: array)

        //When
        let actual = reader[Int.max].rootValue as? NSObject

        //Then
        let expected = JSONReader(rootValue: nil).rootValue as? NSObject
        XCTAssertEqual(actual, expected)
    }


    func testValidNegativeNumericSubscript() {
        //Given
        let array = ["zero", "one", "two"]
        let reader = JSONReader(rootValue: array)

        //When
        let actual = reader[-array.count].rootValue as? NSObject

        //Then
        let expected = JSONReader(rootValue: array.first!).rootValue as? NSObject
        XCTAssertEqual(actual, expected)
    }


    func testInvalidNegativeNumericSubscript() {
        //Given
        let array = ["zero", "one", "two"]
        let reader = JSONReader(rootValue: array)

        //When
        let actual = reader[Int.min].rootValue as? NSObject

        //Then
        let expected = JSONReader(rootValue: nil).rootValue as? NSObject
        XCTAssertEqual(actual, expected)
    }


//MARK:

    func testIsValidKeyHappy() {
        //Given
        let key = "foo"
        let value = "bar"
        let dict = [key: value]
        let reader = JSONReader(rootValue: dict)

        //When
        let actual = reader.isValidKey(key)

        //Then
        let expected = true
        XCTAssertEqual(actual, expected)
    }


    func testIsValidKeyUnhappy() {
        //Given
        let key = "foo"
        let value = "bar"
        let dict = [key: value]
        let reader = JSONReader(rootValue: dict)

        //When
        let unhappyKey = "asgrdhf"
        let actual = reader.isValidKey(unhappyKey)

        //Then
        let expected = false
        XCTAssertEqual(actual, expected)
    }


    func testStringSubscriptValid() {
        //Given
        let key = "foo"
        let value = "bar"
        let dict = [key: value]
        let reader = JSONReader(rootValue: dict)

        //When
        let actual = reader[key].rootValue as? NSObject

        //Then
        let expected = JSONReader(rootValue: value).rootValue as? NSObject
        XCTAssertEqual(actual, expected)
    }


    func testStringSubscriptInvalid() {
        //Given
        let key = "foo"
        let value = "bar"
        let dict = [key: value]
        let reader = JSONReader(rootValue: dict)

        //When
        let unhappyKey = "aegrsetwr"
        let actual = reader[unhappyKey].rootValue as? NSObject

        //Then
        let expected = JSONReader(rootValue: nil).rootValue as? NSObject
        XCTAssertEqual(actual, expected)
    }
}


class JSONReaderJSONPathTests: XCTestCase {


    func testReaderAtPathValid() {
        //Given
        let value = true
        let dict = ["key": value]
        let reader = JSONReader(rootValue: dict)

        //When
        let actual = (try? reader.reader(at:"key"))?.rootValue as? NSObject ?? JSONReader(rootValue: nil).rootValue as? NSObject

        //Then
        let expected = JSONReader(rootValue: value).rootValue as? NSObject
        XCTAssertEqual(actual, expected)
    }


    func testReaderAtPathInvalid() {
        //Given
        let dict = ["key": "value"]
        let reader = JSONReader(rootValue: dict)

        //When
        let actual: JSONReader?
        let actualError: Error?
        do {
            actual = try reader.reader(at: "arf")
            actualError = nil
        } catch {
            actualError = error
            actual = nil
        }

        //Then
        XCTAssertNotNil(actualError)
        XCTAssertNil(actual)
    }


    //TODO: Test errors are of expected value
    //TODO: 64 bit number edge cases
}
