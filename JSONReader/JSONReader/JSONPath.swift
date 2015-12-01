//
//  JSONReader.swift
//  JSONReader
//
//  Created by Benedict Cohen on 28/11/2015.
//  Copyright © 2015 Benedict Cohen. All rights reserved.
//

import Foundation


public class JSONPath: StringLiteralConvertible {
    
    public enum Component {
        case Text(String)
        case Numeric(Int64)
        case SelfReference
    }
    
    
    private enum ScanResult {
        case Match(Component)
        case NoMatch
    }
    
    private static let subScriptDelimiters = NSCharacterSet(charactersInString: "`'")
    private static let headCharacters = NSCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ$_")
    private static let bodyCharacters: NSCharacterSet = {
        let mutableCharacterSet = NSMutableCharacterSet(charactersInString: "0123456789")
        mutableCharacterSet.formUnionWithCharacterSet(headCharacters)
        return mutableCharacterSet
    }()
    
    
    public let path: String
    public let components: [Component]
    
    
    //MARK:- Instance life cycle
    
    public init(path: String) throws {
        self.path = path
        self.components = [Component]()
        try JSONPath.enumerateComponentsInPath(path) { component, componentIdx, stop in
            self.components.append(component)
        }
        
    }
    
    
    //MARK:- StringLiteralConvertible
    
    public typealias StringLiteralType = String
    
    required public init(stringLiteral path: JSONPath.StringLiteralType) {
        self.path = path
        self.components = [Component]()
        do {
            try JSONPath.enumerateComponentsInPath(path) { component, componentIdx, stop in
                self.components.append(component)
            }
        } catch let error {
            fatalError("String literal does not represent a valid JSONPath. Error: \(error)")
        }
    }
    
    
    public typealias ExtendedGraphemeClusterLiteralType = String
    
    required public init(extendedGraphemeClusterLiteral value: JSONPath.ExtendedGraphemeClusterLiteralType) {
        let path = "\(value)"
        self.path = path
        self.components = [Component]()
        do {
            try JSONPath.enumerateComponentsInPath(path) { component, componentIdx, stop in
                self.components.append(component)
            }
        } catch let error {
            fatalError("String literal does not represent a valid JSONPath. Error: \(error)")
        }
    }
    
    
    public typealias UnicodeScalarLiteralType = String
    
    public required init(unicodeScalarLiteral path: JSONPath.UnicodeScalarLiteralType) {
        self.path = path
        self.components = [Component]()
        do {
            try JSONPath.enumerateComponentsInPath(path) { component, componentIdx, stop in
                self.components.append(component)
            }
        } catch let error {
            fatalError("String literal does not represent a valid JSONPath. Error: \(error)")
        }
    }
    
    
    //MARK: Path parsing
    
    private static let identifierComponentValidHeadCharacterSet = NSCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ$_")
    
    private static var identifierComponentValidBodyCharacterSet: NSCharacterSet = {
        let mutableCharacterSet = NSMutableCharacterSet(charactersInString: "0123456789")
        mutableCharacterSet.formUnionWithCharacterSet(identifierComponentValidHeadCharacterSet)
        return mutableCharacterSet
    }()
    
    
    public class func enumerateComponentsInPath(JSONPath: String, enumerator: (component: Component, componentIdx: Int, inout stop: Bool) throws -> Void) throws {
        
        let scanner = NSScanner(string: JSONPath)
        scanner.charactersToBeSkipped = nil //Don't skip whitespace!

        var componentIdx = 0
        repeat {

            guard let component = try scanComponent(scanner) else {
                //[BCJError invalidJSONPathErrorWithJSONPath:JSONPath errorPosition:scanner.scanLocation];
                throw NSError(domain: "TODO", code: 0, userInfo: nil)
            }
            
            //Call the enumerator
            var stop = false
            try enumerator(component: component, componentIdx: componentIdx, stop: &stop)
            if stop { return }
        
            //Prepare for next loop
            componentIdx++
            
        } while !scanner.atEnd
        
        //Done without error
    }
    
    
    private class func scanComponent(scanner: NSScanner) throws -> Component? {
        
        if let component = try scanSubscriptComponent(scanner) {
            return component
        }

        if let component = try scanIdentifierComponent(scanner) {
            return component
        }
        
        return nil
    }
    
    
    private class func scanSubscriptComponent(scanner: NSScanner) throws -> Component? {
        let result: Component

        //Is it subscript?
        let isSubscript = scanner.scanString("[", intoString: nil)
        guard isSubscript else {
            return nil
        }
        
        //Scan the value
        var idx: Int64 = 0
        var text: String = ""
        switch scanner {
            
        case (_) where scanner.scanLongLong(&idx):
            result = .Numeric(idx)
            
        case (_) where scanner.scanString("self", intoString: nil):
            result = .SelfReference
            
        case (_) where try scanner.scanSingleQuoteDelimittedString(&text):
            result = .Text(text)
            
        default:
            throw NSError(domain: "TODO: Contents of subscript is not valid", code: 0, userInfo: nil)
        }
        
        //Close the subscript
        guard scanner.scanString("]", intoString: nil) else {
            throw NSError(domain: "TODO: Expected closing subscript ']'", code: 0, userInfo: nil)
        }
        
        //TODO:
        scanner.ARFARFARFisScannerIsAtStartOfJSONPathComponent()
        
        return result
    }
    
    
    private class func scanIdentifierComponent(scanner: NSScanner) throws -> Component? {
        //Technically there are a lot more unicode code points that are acceptable, but we go for 99+% of JSON keys.
        //See on https://mathiasbynens.be/notes/javascript-properties.
        
        var identifier = ""
        var headFragment: NSString?
        guard scanner.scanCharactersFromSet(identifierComponentValidHeadCharacterSet, intoString: &headFragment) else {
            return nil
        }
        identifier.appendContentsOf(headFragment as! String)
        
        var bodyFragment: NSString?
        if scanner.scanCharactersFromSet(identifierComponentValidBodyCharacterSet, intoString: &bodyFragment) {
            identifier.appendContentsOf(bodyFragment as! String)
        }
        
        //TODO:
        scanner.ARFARFARFisScannerIsAtStartOfJSONPathComponent()
        
        return .Text(identifier)
    }

}



extension NSScanner {
    
    private static let singleQuoteDelimittedStringDelimiters = NSCharacterSet(charactersInString:"`'")
    
    private func ARFARFARFisScannerIsAtStartOfJSONPathComponent() {
        //If there's another path component, thus meaning there're at least 2 more characters ("[SUBSCRIPT" or .indentifer),
        let hasAtLeast1MoreComponent = (scanLocation < (string as NSString).length - 1)
        //...then consume the optional trailing dot providing it's not followed by a '[' so that the remaining string is a valid path.
        if hasAtLeast1MoreComponent {
            let dotLocation = scanLocation
            if scanString(".", intoString:nil) && scanString("[", intoString:nil) {
                //That's an invalid sequence! Reset the scanLocation.
                scanLocation = dotLocation
            }
        }
    }
    
    
    private func scanSingleQuoteDelimittedString(inout string: String) throws -> Bool {

        guard scanString("'", intoString: nil) else {
            return false
        }
        
        var text = ""
        mainLoop: while !atEnd {
            //Scan normal text
            var fragment: NSString?
            let didScanFragment = scanUpToCharactersFromSet(NSScanner.singleQuoteDelimittedStringDelimiters, intoString:&fragment)
            if didScanFragment,
              let fragment = fragment as? String {
                text.appendContentsOf(fragment)
            }

            //Scan escape sequences
            escapeSequenceLoop: while true {
                if scanString("`'", intoString: nil) {
                    text.appendContentsOf("'")
                } else
                if scanString("``", intoString: nil) {
                    text.appendContentsOf("`")
                } else
                if scanString("`", intoString: nil) {
                    text.appendContentsOf("`") //This is technically an invalid escape sequence but we're forgiving.
                } else {
                    break escapeSequenceLoop
                }
            }
            
            //Attempt to scan the closing delimiter
            if scanString("'", intoString: nil) {
                //Done!
                string = text
                return true
            }
        }
        
        throw NSError(domain: "TODO: Expected character or delimiter but found end of string.", code: 0, userInfo: nil)
    }
}
