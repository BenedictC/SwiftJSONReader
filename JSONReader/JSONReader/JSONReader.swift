//
//  JSONReader.swift
//  JSONReader
//
//  Created by Benedict Cohen on 28/11/2015.
//  Copyright © 2015 Benedict Cohen. All rights reserved.
//

import Foundation


public final class JSONReader: Equatable {

    //MARK:- Errors

    public enum Error: ErrorType {
        case MissingValue
        case UnexpectedType(expectedType: Any.Type, actualType: Any.Type)
    }


    /// The object to attempt to fetch values from
    let object: AnyObject?

    var isEmpty: Bool {
        return object == nil
    }


    //MARK:- Instance life cycle

    convenience public init(data: NSData, allowFragments: Bool = false) throws {
        let options: NSJSONReadingOptions = allowFragments ? [NSJSONReadingOptions.AllowFragments] : []
        let object = try NSJSONSerialization.JSONObjectWithData(data, options: options)
        self.init(object: object)
    }


    public init(object: AnyObject?) {
        self.object = object
    }


    private convenience init() {
        self.init(object: nil)
    }


    //MARK:- Value access

    public func value<T>() -> T? {
        return object as? T
    }


    public func value<T>(errorHandler: (JSONReader.Error) throws -> T) rethrows -> T {
        guard object != nil else {
            let error = Error.MissingValue
            return try errorHandler(error)
        }

        guard let value = object as? T else {
            let error = Error.UnexpectedType(expectedType: T.self, actualType: object.dynamicType)
            return try errorHandler(error)
        }

        return value
    }


    //MARK:- Element access

    public func isValidIndex(relativeIndex: Int) -> Bool {
        return absoluteIndexForRelativeIndex(relativeIndex) != nil
    }


    private func absoluteIndexForRelativeIndex(relativeIndex: Int) -> Int? {
        guard let array = object as? NSArray else {
            return nil
        }

        let count = array.count
        let shouldInvertIndex = relativeIndex < 0
        let index = shouldInvertIndex ? count + relativeIndex : relativeIndex

        let isInRange = index >= 0 && index < count
        return isInRange ? index : nil
    }


    public subscript(relativeIndex: Int) -> JSONReader {
        guard let index = absoluteIndexForRelativeIndex(relativeIndex),
              let collection = object as? [AnyObject] else {
            return JSONReader()
        }

        return JSONReader(object: collection[index])
    }


    public func isValidKey(key: String) -> Bool {
        guard let collection = object as? NSDictionary else {
            return false
        }

        return collection[key] != nil
    }


    public subscript(key: String) -> JSONReader {
        guard let collection = object as? [String: AnyObject],
              let element = collection[key] else {
            return JSONReader()
        }

        return JSONReader(object: element)
    }
}


//MARK:- JSONPath extension

extension JSONReader {

    public enum JSONPathError: ErrorType {
        public typealias JSONPathComponentsStack = [(JSONPath.Component, AnyObject?)]
        case UnexpectedType(JSONPath, JSONPathComponentsStack, Any.Type)
        //"Unexpected type while fetching value for path $PATH:\n
        //$i: $COMPONENT_VALUE ($COMPONENT_TYPE) -> $VALUE_TYPE\n"
        case InvalidSubscript(JSONPath, JSONPathComponentsStack)
        case MissingValue(JSONPath)
    }


    //MARK:- Optional value fetching

    public func optionalValueAtPath<T>(path: JSONPath, substituteNSNullWithNil: Bool = true, errorHandler: (JSONPathError) throws -> T? = { _ in return nil } ) rethrows -> T? {
        var untypedValue: AnyObject? = object
        var componentsErrorStack = JSONPathError.JSONPathComponentsStack()

        for component in path.components {
            componentsErrorStack.append((component, untypedValue))

            switch component {
            case .SelfReference:
                break

            case .Numeric(let number):
                //Check the collection is valid
                guard let array = untypedValue as? NSArray else {
                    let error = JSONPathError.UnexpectedType(path, componentsErrorStack, NSArray.self)
                    return try errorHandler(error)
                }

                //Check the index is valid
                guard let index = absoluteIndexForRelativeIndex(Int(number)) else {
                    //TODO: The erro should be invalidIndex
                    let error = JSONPathError.InvalidSubscript(path, componentsErrorStack)
                    return try errorHandler(error)
                }
                untypedValue = array[index]

            case .Text(let key):
                guard let dict = untypedValue as? NSDictionary else {
                    let error = JSONPathError.UnexpectedType(path, componentsErrorStack, NSDictionary.self)
                    return try errorHandler(error)
                }

                //Check the index is valid
                guard let element = dict[key] else {
                    let error = JSONPathError.InvalidSubscript(path, componentsErrorStack)
                    return try errorHandler(error)
                }
                untypedValue = element
            }
        }

        if untypedValue == nil //This can only occur when the rootObject is nil and the path consists only of .SelfReference
        || (substituteNSNullWithNil && untypedValue is NSNull) {
            return nil
        }

        guard let value = untypedValue as? T else {
            let error = JSONPathError.UnexpectedType(path, componentsErrorStack, T.self)
            return try errorHandler(error)
        }

        return value
    }


    //MARK: Non-optional value fetching

    public func valueAtPath<T>(path: JSONPath, errorHandler: (JSONPathError) throws -> T) rethrows -> T {
        
        guard let value = try optionalValueAtPath(path, substituteNSNullWithNil: false, errorHandler: { try errorHandler($0) }) else {
            //- if nil -> missing value error and return
            return try errorHandler(.MissingValue(path))
        }
        return value
    }


    public func valueAtPath<T>(path: JSONPath, defaultValue: T) -> T {
        return valueAtPath(path, errorHandler: {_ in return defaultValue })
    }


    public func valueAtPath<T>(path: JSONPath) throws -> T {
        return try valueAtPath(path, errorHandler: {throw $0})
    }


    //MARK:- Reader fetching

    public func readerAtPath(path: JSONPath, errorHandler: (JSONPathError) throws -> JSONReader = { throw $0 } ) rethrows -> JSONReader {
        guard let object = try optionalValueAtPath(path, substituteNSNullWithNil: false, errorHandler: errorHandler) else {
            return try errorHandler(.MissingValue(path))
        }

        return JSONReader(object: object)
    }
}


public func ==(lhs: JSONReader, rhs: JSONReader) -> Bool {

    if lhs.isEmpty && rhs.isEmpty {
        return true
    }

    if let
        left:  NSArray = lhs.value(),
        right: NSArray = rhs.value() {
            return left == right
    }

    if let
        left:  NSDictionary = lhs.value(),
        right: NSDictionary = rhs.value() {
            return left == right
    }

    if let
        left:  NSString = lhs.value(),
        right: NSString = rhs.value() {
            return left == right
    }

    if let
        left:  NSNull = lhs.value(),
        right: NSNull = rhs.value() {
            return left == right
    }

    if let
        left:  NSNumber = lhs.value(),
        right: NSNumber = rhs.value() {
            return left == right
    }

    return false
}
