//
//  Player.swift
//  Vinyl
//
//  Created by David Rodrigues on 16/02/16.
//  Copyright © 2016 Velhotes. All rights reserved.
//

import Foundation

struct Player {
    
    let vinyl: Vinyl
    let trackMatchers: [TrackMatcher]
    
    private func seekTrackForRequest(_ request: Request) -> Track? {
        return vinyl.tracks.first({ track in
            trackMatchers.all({ matcher in matcher.matchableTrack(request, track: track) })
        })
    }
    
    func playTrack(forRequest request: Request) throws -> (data: Data?, response: URLResponse?, error: NSError?) {
        
        guard let track = self.seekTrackForRequest(request) else {
            throw Error.trackNotFound
        }
        
        return (data: track.response.body, response: track.response.urlResponse, error: track.response.error)
    }
}
