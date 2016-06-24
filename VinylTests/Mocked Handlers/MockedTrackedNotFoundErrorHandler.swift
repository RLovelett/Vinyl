//
//  MockedTrackedNotFoundErrorHandler.swift
//  Vinyl
//
//  Created by Rui Peres on 18/02/2016.
//  Copyright © 2016 Velhotes. All rights reserved.
//

import Foundation
@testable import Vinyl

final class MockedTrackedNotFoundErrorHandler: ErrorHandler {
    
    private let completion: (Void) -> Void
    
    init (completion: (Void) -> Void) {
        self.completion = completion
    }


    /// - SeeAlso: http://stackoverflow.com/a/37801408/247730
    private lazy var once: () = {
        self.completion()
    }()
    func handleTrackNotFound(_ request: Request, playTracksUniquely: Bool) {

        
        // If this gets called multiple times and has an "expectation.fullfill()" it will crash
        // So we make sure it will only be called once.
        // It also makes sense, since in the DefaultErrorHandler this would call fatal_error (which is only called once)
        _ = once
    }
    
    func handleUnknownError() {
        fatalError("This shouldn't be called")
    }
}
