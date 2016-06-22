//
//  TurntableError.swift
//  Vinyl
//
//  Created by Ryan Lovelett on 6/24/16.
//  Copyright © 2016 Velhotes. All rights reserved.
//

protocol CustomErrorConvertible {
    func userInfo() -> [String : String]?
    func domain() -> String
    func code() -> Int
}

extension CustomErrorConvertible {
    func error() -> NSError {
        return NSError(domain: self.domain(), code: self.code(), userInfo: self.userInfo())
    }
}

enum TurntableError: ErrorProtocol {
    case recordNotFound(for: URLRequest)
    case missing(resource: String)
    case invalidFormat(resource: String)
}

extension TurntableError : CustomErrorConvertible {
    func userInfo() -> [String : String]? {
        return [
            NSLocalizedDescriptionKey: "Unable to find match for request."
        ]
    }

    func domain() -> String {
        return "me.lovelett.Vinyl.TurntableError"
    }

    func code() -> Int {
        switch self {
        case .recordNotFound(_):
            return 404
        default:
            return 500
        }
    }
}
