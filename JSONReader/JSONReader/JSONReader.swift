//
//  JSONReader.swift
//  JSONReader
//
//  Created by Benedict Cohen on 28/11/2015.
//  Copyright © 2015 Benedict Cohen. All rights reserved.
//

import Foundation


//MARK:- Errors

public enum JSONReaderError: Error {
    case missingValue
    case unexpectedType(expectedType: Any.Type, actualType: Any.Type)
}


public final class JSONReader {

    /// The object to attempt to fetch values from
    public let rootValue: Any?

    public var isEmpty: Bool {
        return rootValue == nil
    }


    //MARK:- Instance life cycle

    public init(rootValue: Any?) {
        self.rootValue = rootValue
    }


    //MARK:- root value access

    public func value<T>() -> T? {
        return rootValue as? T
    }


    //MARK:- Element access

    public func isValidIndex(_ relativeIndex: Int) -> Bool {
        guard let array = rootValue as? NSArray else {
            return false
        }

        return array.absoluteIndexForRelativeIndex(relativeIndex) != nil
    }


    public subscript(relativeIndex: Int) -> JSONReader {
        guard let array = rootValue as? NSArray,
            let index = array.absoluteIndexForRelativeIndex(relativeIndex) else {
                return JSONReader(rootValue: nil)
        }

        return JSONReader(rootValue: array[index])
    }


    public func isValidKey(_ key: String) -> Bool {
        guard let collection = rootValue as? NSDictionary else {
            return false
        }

        return collection[key] != nil
    }


    public subscript(key: String) -> JSONReader {
        guard let collection = rootValue as? NSDictionary,
            let element = collection[key] else {
                return JSONReader(rootValue: nil)
        }

        return JSONReader(rootValue: element)
    }
}


//MARK:- JSON deserialization extension

extension JSONReader {

    convenience public init(data: Data, allowFragments: Bool = false) throws {
        let options: JSONSerialization.ReadingOptions = allowFragments ? [JSONSerialization.ReadingOptions.allowFragments] : []
        let object = try JSONSerialization.jsonObject(with: data, options: options)
        self.init(rootValue: object)
    }

}


//MARK:- JSONPath extension

extension JSONReader {

    public enum JSONPathError: Error {
        public typealias JSONPathComponentsStack = [(JSONPath.Component, Any?)]
        case unexpectedType(path: JSONPath, componentStack: JSONPathComponentsStack, Any.Type)
        case invalidSubscript(path: JSONPath, componentStack: JSONPathComponentsStack)
        case missingValue(path: JSONPath)
    }


    //MARK: Value fetching

    public func value<T>(at path: JSONPath, terminalNSNullSubstitution nullSubstitution: T? = nil) throws -> T {
        var untypedValue: Any? = rootValue
        var componentsErrorStack = JSONPathError.JSONPathComponentsStack()

        for component in path.components {
            componentsErrorStack.append((component, untypedValue))

            switch component {
            case .selfReference:
                break

            case .numeric(let number):
                //Check the collection is valid
                guard let array = untypedValue as? NSArray else {
                    throw JSONPathError.unexpectedType(path: path, componentStack: componentsErrorStack, NSArray.self)
                }

                //Check the index is valid
                guard let index = array.absoluteIndexForRelativeIndex(Int(number)) else {
                    throw JSONPathError.invalidSubscript(path: path, componentStack: componentsErrorStack)

                }
                untypedValue = array[index]

            case .text(let key):
                guard let dict = untypedValue as? NSDictionary else {
                    throw JSONPathError.unexpectedType(path: path, componentStack: componentsErrorStack, NSDictionary.self)
                }

                //Check the index is valid
                guard let element = dict[key] else {
                    throw JSONPathError.invalidSubscript(path: path, componentStack: componentsErrorStack)
                }
                untypedValue = element
            }
        }

        if untypedValue is NSNull {
            untypedValue = nullSubstitution
        }

        guard let value = untypedValue as? T else {
            throw JSONPathError.unexpectedType(path: path, componentStack: componentsErrorStack, T.self)
        }

        return value
    }


    //MARK:- Reader fetching

    public func reader(at path: JSONPath) throws -> JSONReader {
        let rootValue = try value(at: path) as Any

        return JSONReader(rootValue: rootValue)
    }
}


//MARK:- Array index additions

extension NSArray {

    private func absoluteIndexForRelativeIndex(_ relativeIndex: Int) -> Int? {

        let count = self.count
        let shouldInvertIndex = relativeIndex < 0
        let index = shouldInvertIndex ? count + relativeIndex : relativeIndex

        let isInRange = index >= 0 && index < count
        return isInRange ? index : nil
    }

}
