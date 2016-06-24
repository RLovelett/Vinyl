//
//  TurntableConfiguration.swift
//  Vinyl
//
//  Created by David Rodrigues on 17/02/16.
//  Copyright © 2016 Velhotes. All rights reserved.
//

import Foundation

public enum MatchingStrategy {
    case requestAttributes(types: [RequestMatcherType], playTracksUniquely: Bool)
    case trackOrder
}

public struct TurntableConfiguration {
    
   public let matchingStrategy: MatchingStrategy
    
    var playTracksUniquely: Bool {
        get {
            switch matchingStrategy {
            case .requestAttributes(_, let playTracksUniquely): return playTracksUniquely
            case .trackOrder: return true
            }
        }
    }
    
   public init(matchingStrategy: MatchingStrategy = .requestAttributes(types: [.method, .url], playTracksUniquely: true)) {
        self.matchingStrategy = matchingStrategy
    }
    
    func trackMatchersForVinyl(_ vinyl: Vinyl) -> [TrackMatcher] {
        
        switch matchingStrategy {
            
        case .requestAttributes(let types, let playTracksUniquely):
            
            var trackMatchers: [TrackMatcher] = [ TypeTrackMatcher(requestMatcherTypes: types) ]
            
            if playTracksUniquely {
                // NOTE: This should be always the last matcher since we only want to match if the track is still available or not, and that means keeping some state 🙄
                trackMatchers.append(UniqueTrackMatcher(availableTracks: vinyl.tracks))
            }
            
            return trackMatchers
            
        case .trackOrder:
            return [ UniqueTrackMatcher(availableTracks: vinyl.tracks) ]
        }
    }
}
