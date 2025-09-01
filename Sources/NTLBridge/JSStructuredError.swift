//
//  File.swift
//  NTLBridge
//
//  Created by vince on 2025/8/20.
//

import Foundation

func jsStructuredError(jsonValue: JSONValue) -> NSError? {
    guard case let .dictionary(dictionary) = jsonValue,
          let name = dictionary["name"]?.stringValue,
          let message = dictionary["message"]?.stringValue,
          let stack = dictionary["stack"]?.stringValue
    else {
        return nil
    }
    let description = "name: \(name)\nmessage: \(message)\nstack: \(stack)"
    let userInfo: [String: Any] = [
        NSLocalizedDescriptionKey: description,
    ]
    return NSError(domain: "NTLBridge", code: -1, userInfo: userInfo)
}
