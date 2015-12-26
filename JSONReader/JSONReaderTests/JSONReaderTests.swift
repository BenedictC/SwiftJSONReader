//
//  JSONReaderTests.swift
//  JSONReaderTests
//
//  Created by Benedict Cohen on 09/12/2015.
//  Copyright © 2015 Benedict Cohen. All rights reserved.
//

import XCTest


class JSONReaderTests: XCTestCase {

    let object = [
        "array": ["string", 2, NSNull(), 4.4, [], true],
        "number": NSNumber(integer: 5), //If we use NSNumber(float:) then the comparision fails. Strange.
        "string": "Boo!"
    ]
    lazy var reader: JSONReader = JSONReader(object: self.object)


    func testObjectProperty() {
        //Valid object
        XCTAssertNotNil(reader.object)
        XCTAssertFalse(reader.isEmpty)

        //InvalidObject
        let emptyReader = JSONReader(object: nil)
        XCTAssertNil(emptyReader.object)
        XCTAssertTrue(emptyReader.isEmpty)
    }


    func testInitWithJSONValidData() {
        //Given
        let expected: NSDictionary = object
        let data = (try? NSJSONSerialization.dataWithJSONObject(expected, options: [])) ?? NSData()

        //When
        let reader = try? JSONReader(data: data)
        let actual: NSDictionary = (reader?.object as? NSDictionary) ?? NSDictionary()

        //Then
        XCTAssertEqual(actual, expected)
    }


    func testInitWithJSONInvalidData() {
        //Given
        let data = NSData()

        //When
        let reader = try? JSONReader(data: data)

        //Then
        XCTAssertNil(reader)
    }


    func testInitWithJSONDataWithFragmentTrue() {
        //Given
        let expected = NSNull()
        let data = "null".dataUsingEncoding(NSUTF8StringEncoding)!

        //When
        let reader = try? JSONReader(data: data, allowFragments: true)
        let actual = reader?.object as? NSNull

        //Then
        if let actual = actual {
            XCTAssertEqual(actual, expected)
        } else {
            XCTFail()
        }
    }


    func testInitWithJSONDataWithFragmentFalse() {
        //Given
        let data = "null".dataUsingEncoding(NSUTF8StringEncoding)!

        //When
        let reader = try? JSONReader(data: data, allowFragments: false)

        //Then
        XCTAssertNil(reader)
    }

    
    func testValue() {
        //Given
        let expected: Float = 4.5
        let reader = JSONReader(object: expected)

        //When
        let actual = reader.value() as Float?

        //Then
        XCTAssertEqual(expected, actual)
    }



    func testValueWithErrorHandlerHappy() {
        //Given
        let expected: Double = 800
        let reader = JSONReader(object: expected)

        //When
        let actual = reader.value() { error in
            return expected * -1
        }

        //Then
        XCTAssertEqual(actual, expected)
    }


    func testValueWithErrorHandlerWrongType() {
        //Given
        let expected: Double = 800
        let reader = JSONReader(object: expected)

        //When
        let actualError: ErrorType?
        let actualValue: String?
        do {
            actualValue = try reader.value() { error -> String in throw error }
            actualError = nil
        } catch {
            actualValue = nil
            actualError = error
        }

        //Then
        XCTAssertNil(actualValue)
        XCTAssertNotNil(actualError)

        //TODO: Test error is of expect type
    }


    func testIsValidPositiveIndex() {
        //Given
        let array = [0,1,2]
        let reader = JSONReader(object: array)

        //When
        let actual = reader.isValidIndex(array.count - 1)

        //Then
        let expected = true
        XCTAssertEqual(actual, expected)
    }


    func testIsInvalidPositiveIndex() {
        //Given
        let array = [0,1,2]
        let reader = JSONReader(object: array)

        //When
        let actual = reader.isValidIndex(Int.max)

        //Then
        let expected = false
        XCTAssertEqual(actual, expected)
    }


    func testIsValidNegativeIndex() {
        //Given
        let array = [0,1,2]
        let reader = JSONReader(object: array)

        //When
        let actual = reader.isValidIndex(-array.count)

        //Then
        let expected = true
        XCTAssertEqual(actual, expected)
    }


    func testIsInvalidNegativeIndex() {
        //Given
        let array = [0,1,2]
        let reader = JSONReader(object: array)

        //When
        let actual = reader.isValidIndex(Int.min)

        //Then
        let expected = false
        XCTAssertEqual(actual, expected)
    }


    func testValidPositiveNumericSubscript() {
        //Given
        let array = ["zero", "one", "two"]
        let reader = JSONReader(object: array)

        //When
        let actual = reader[0]

        //Then
        let expected = JSONReader(object: array.first!)
        XCTAssertEqual(actual, expected)
    }


    func testInvalidPositiveNumericSubscript() {
        //Given
        let array = ["zero", "one", "two"]
        let reader = JSONReader(object: array)

        //When
        let actual = reader[Int.max]

        //Then
        let expected = JSONReader(object: nil)
        XCTAssertEqual(actual, expected)
    }


    func testValidNegativeNumericSubscript() {
        //Given
        let array = ["zero", "one", "two"]
        let reader = JSONReader(object: array)

        //When
        let actual = reader[-array.count]

        //Then
        let expected = JSONReader(object: array.first!)
        XCTAssertEqual(actual, expected)
    }


    func testInvalidNegativeNumericSubscript() {
        //Given
        let array = ["zero", "one", "two"]
        let reader = JSONReader(object: array)

        //When
        let actual = reader[Int.min]

        //Then
        let expected = JSONReader(object: nil)
        XCTAssertEqual(actual, expected)
    }


//MARK:

    func testIsValidKeyHappy() {
        //Given
        let key = "foo"
        let value = "bar"
        let dict = [key: value]
        let reader = JSONReader(object: dict)

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
        let reader = JSONReader(object: dict)

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
        let reader = JSONReader(object: dict)

        //When
        let actual = reader[key]

        //Then
        let expected = JSONReader(object: value)
        XCTAssertEqual(actual, expected)
    }


    func testStringSubscriptInvalid() {
        //Given
        let key = "foo"
        let value = "bar"
        let dict = [key: value]
        let reader = JSONReader(object: dict)

        //When
        let unhappyKey = "aegrsetwr"
        let actual = reader[unhappyKey]

        //Then
        let expected = JSONReader(object: nil)
        XCTAssertEqual(actual, expected)
    }
}


class JSONReaderJSONPathTests: XCTestCase {

/*

    @rethrows public func optionalValueAtPath<T>(path: JSONPath, substituteNSNullWithNil: Bool = default, errorHandler: (JSONPathError) throws -> T? = default) rethrows -> T?


    @rethrows public func valueAtPath<T>(path: JSONPath, errorHandler: (JSONPathError) throws -> T) rethrows -> T


    public func valueAtPath<T>(path: JSONPath, defaultValue: T) -> T


    public func valueAtPath<T>(path: JSONPath) throws -> T


    @rethrows public func readerAtPath(path: JSONPath, errorHandler: (JSONPathError) throws -> JSONReader = default) rethrows -> JSONReader.JSONReader
*/


    //TODO: 64 bit number edge cases
}
