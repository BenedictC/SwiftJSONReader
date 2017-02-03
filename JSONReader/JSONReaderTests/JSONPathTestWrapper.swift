//
//  JSONPathTestWrapper.swift
//  JSONReader
//
//  Created by Benedict Cohen on 25/12/2015.
//  Copyright © 2015 Benedict Cohen. All rights reserved.
//

import Foundation


/**
JSONPathTestWrapper is a helper struct that reduces the boiler plate required to created arrays of components from Strings and Arrays. It also implements Equatable to reduce boiler plate code of comparsion.
*/
struct JSONPathTestWrapper: Equatable {
    let components: [JSONPath.Component]
    let isValid: Bool
}


func ==(lhs: JSONPathTestWrapper, rhs: JSONPathTestWrapper) -> Bool {
    return lhs.isValid    == rhs.isValid
        && lhs.components == rhs.components
}


extension JSONPathTestWrapper: ExpressibleByStringLiteral {

    init(stringLiteral path: StringLiteralType) {
        let jsonPath = try? JSONPath(path: path)

        let isValid = jsonPath != nil
        let components = jsonPath?.components ?? []
        self.init(components: components, isValid: isValid)
    }


    typealias ExtendedGraphemeClusterLiteralType = StringLiteralType

    init(extendedGraphemeClusterLiteral path: ExtendedGraphemeClusterLiteralType) {
        let jsonPath = try? JSONPath(path: path)

        let isValid = jsonPath != nil
        let components = jsonPath?.components ?? []
        self.init(components: components, isValid: isValid)
    }


    typealias UnicodeScalarLiteralType = String

    init(unicodeScalarLiteral path: UnicodeScalarLiteralType) {
        let jsonPath = try? JSONPath(path: "\(path)")

        let isValid = jsonPath != nil
        let components = jsonPath?.components ?? []
        self.init(components: components, isValid: isValid)
    }
}


extension JSONPathTestWrapper: ExpressibleByArrayLiteral {
    typealias Element = Any

    init(arrayLiteral elements:JSONPathTestWrapper.Element...) {

        var components = Array<JSONPath.Component>()
        for literal in elements {
            switch literal {
            case is String:
                components.append(JSONPath.Component.text(literal as! String))

            case is Int:
                let int = literal as! Int
                let number = Int64(int)
                components.append(JSONPath.Component.numeric(number))

            case is NSNull:
                components.append(JSONPath.Component.selfReference)

            default:
                fatalError("Invalid literal")
            }
        }
        
        self.init(components: components, isValid: true)
    }
}
