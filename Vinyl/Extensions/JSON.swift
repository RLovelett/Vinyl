//
//  JSON.swift
//  Vinyl
//
//  Created by Ryan Lovelett on 7/14/16.
//  Copyright © 2016 Velhotes. All rights reserved.
//

import Argo
import Foundation

extension JSON {
    func encode() -> AnyObject {
        switch self {
        case .object(let dictionary):
            var accum = Dictionary<String, AnyObject>(minimumCapacity: dictionary.count)
            for (key, value) in dictionary {
                accum[key] = value.encode()
            }
            return accum
        case .string(let str):
            return str
        default:
            return NSNull()
        }
    }
}
