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
    public let rootValue: Any?

    public var isEmpty: Bool {
        return rootValue == nil
    }
    
    
    //MARK:- Instance life cycle
    
    convenience public init(data: NSData, allowFragments: Bool = false) throws {
        let options: NSJSONReadingOptions = allowFragments ? [NSJSONReadingOptions.AllowFragments] : []
        let object = try NSJSONSerialization.JSONObjectWithData(data, options: options)
        self.init(rootValue: object)
    }


    public init(rootValue: Any?) {
        self.rootValue = rootValue
    }

    
    //MARK:- root value access
    
    public func value<T>() -> T? {
        return rootValue as? T
    }

    
    //MARK:- Element access
    
    public func isValidIndex(relativeIndex: Int) -> Bool {
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
    
    
    public func isValidKey(key: String) -> Bool {
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


//MARK:- JSONPath extension

extension JSONReader {

    public enum JSONPathError: ErrorType {
        public typealias JSONPathComponentsStack = [(JSONPath.Component, Any?)]
        case UnexpectedType(path: JSONPath, componentStack: JSONPathComponentsStack, Any.Type)
        //"Unexpected type while fetching value for path $PATH:\n
        //$i: $COMPONENT_VALUE ($COMPONENT_TYPE) -> $VALUE_TYPE\n"
        case InvalidSubscript(path: JSONPath, componentStack: JSONPathComponentsStack)
        case MissingValue(path: JSONPath)
    }


    //MARK: Value fetching

    public func valueAtPath<T>(path: JSONPath, terminalNSNullSubstitution nullSubstitution: T? = nil) throws -> T {
        var untypedValue: Any? = rootValue
        var componentsErrorStack = JSONPathError.JSONPathComponentsStack()

        for component in path.components {
            componentsErrorStack.append((component, untypedValue))

            switch component {
            case .SelfReference:
                break

            case .Numeric(let number):
                //Check the collection is valid
                guard let array = untypedValue as? NSArray else {
                    throw JSONPathError.UnexpectedType(path: path, componentStack: componentsErrorStack, NSArray.self)
                }

                //Check the index is valid
                guard let index = array.absoluteIndexForRelativeIndex(Int(number)) else {
                    //TODO: The error should be invalidIndex
                    throw JSONPathError.InvalidSubscript(path: path, componentStack: componentsErrorStack)

                }
                untypedValue = array[index]

            case .Text(let key):
                guard let dict = untypedValue as? NSDictionary else {
                    throw JSONPathError.UnexpectedType(path: path, componentStack: componentsErrorStack, NSDictionary.self)
                }

                //Check the index is valid
                guard let element = dict[key] else {
                    throw JSONPathError.InvalidSubscript(path: path, componentStack: componentsErrorStack)
                }
                untypedValue = element
            }
        }

        if untypedValue is NSNull {
            untypedValue = nullSubstitution
        }

        guard let value = untypedValue as? T else {
            throw JSONPathError.UnexpectedType(path: path, componentStack: componentsErrorStack, T.self)
        }
        
        return value
    }


    //MARK:- Reader fetching

    public func readerAtPath(path: JSONPath) throws -> JSONReader {
        let value = try valueAtPath(path) as Any

        return JSONReader(rootValue: value)
    }
}


//MARK:- Array index additions

extension NSArray {
    
    private func absoluteIndexForRelativeIndex(relativeIndex: Int) -> Int? {
        
        let count = self.count
        let shouldInvertIndex = relativeIndex < 0
        let index = shouldInvertIndex ? count + relativeIndex : relativeIndex
        
        let isInRange = index >= 0 && index < count
        return isInRange ? index : nil
    }
    
}


//MARK:- Depreacted methods

extension JSONReader {

    @available(*, deprecated=0.5, renamed="init(rootValue:)")
    public convenience init(object: Any?) {
        self.init(rootValue: object)
    }


    @available(*, deprecated=0.5, renamed="rootValue")
    public var object: Any? {
        return rootValue
    }


    @available(*, deprecated=0.5)
    public func valueAtPath<T>(path: JSONPath, errorHandler: (JSONPathError) throws -> T) rethrows -> T {

        guard let value = try optionalValueAtPath(path, substituteNSNullWithNil: false, errorHandler: { try errorHandler($0) }) else {
            //- if nil -> missing value error and return
            return try errorHandler(.MissingValue(path: path))
        }
        return value
    }


    @available(*, deprecated=0.5)
    public func valueAtPath<T>(path: JSONPath, defaultValue: T) -> T {
        return valueAtPath(path, errorHandler: {_ in return defaultValue })
    }


    @available(*, deprecated=0.5)
    public func readerAtPath(path: JSONPath, errorHandler: (JSONPathError) throws -> JSONReader = { throw $0 } ) rethrows -> JSONReader {
        let value: Any? = try optionalValueAtPath(path, substituteNSNullWithNil: false, errorHandler: errorHandler)
        guard let object = value else {
            return try errorHandler(.MissingValue(path: path))
        }

        return JSONReader(object: object)
    }


    @available(*, deprecated=0.5)
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


    @available(*, deprecated=0.5)
    public func optionalValueAtPath<T>(path: JSONPath, substituteNSNullWithNil: Bool = true) -> T? {
        return optionalValueAtPath(path, substituteNSNullWithNil: substituteNSNullWithNil, errorHandler: { _ in return nil })
    }


    @available(*, deprecated=0.5)
    public func optionalValueAtPath<T>(path: JSONPath, substituteNSNullWithNil: Bool = true, errorHandler: ((JSONPathError) throws -> T?)) rethrows -> T? {
        var untypedValue: Any? = object
        var componentsErrorStack = JSONPathError.JSONPathComponentsStack()

        for component in path.components {
            componentsErrorStack.append((component, untypedValue))

            switch component {
            case .SelfReference:
                break

            case .Numeric(let number):
                //Check the collection is valid
                guard let array = untypedValue as? NSArray else {
                    let error = JSONPathError.UnexpectedType(path: path, componentStack: componentsErrorStack, NSArray.self)
                    return try errorHandler(error)
                }

                //Check the index is valid
                guard let index = array.absoluteIndexForRelativeIndex(Int(number)) else {
                    //TODO: The erro should be invalidIndex
                    let error = JSONPathError.InvalidSubscript(path: path, componentStack: componentsErrorStack)
                    return try errorHandler(error)
                }
                untypedValue = array[index]

            case .Text(let key):
                guard let dict = untypedValue as? NSDictionary else {
                    let error = JSONPathError.UnexpectedType(path: path, componentStack: componentsErrorStack, NSDictionary.self)
                    return try errorHandler(error)
                }

                //Check the index is valid
                guard let element = dict[key] else {
                    let error = JSONPathError.InvalidSubscript(path: path, componentStack: componentsErrorStack)
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
            let error = JSONPathError.UnexpectedType(path: path, componentStack: componentsErrorStack, T.self)
            return try errorHandler(error)
        }

        return value
    }
}


@available(*, deprecated=0.5)
public func ==(lhs: JSONReader, rhs: JSONReader) -> Bool {

    if lhs.isEmpty && rhs.isEmpty {
        return true
    }

    if
        let left = lhs.object as? NSObject,
        let right = rhs.object as? NSObject {
        return left == right
    }

    return false
}
