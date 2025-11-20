// MARK: - File Header
//
// LayoutHelpers.swift
// BeatMap
//
// Version: 1.0.0
// Created: November 2025
//
// Property of A. Wheildon
// All rights reserved.
//
// MARK: - End File Header

import SwiftUI

/// Device-aware spacing and sizing utilities for BeatMap.
/// Ensures consistent, beautiful layouts across iPhone and iPad.
struct Spacing {
    /// Standard spacing between elements
    static func standard(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .regular ? 25 : 20
    }
    
    /// Small spacing for compact areas
    static func compact(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .regular ? 18 : 15
    }
    
    /// Large spacing for major sections
    static func large(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .regular ? 35 : 30
    }
}

struct CornerRadius {
    /// Standard corner radius for cards
    static func standard(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .regular ? 16 : 12
    }
    
    /// Small corner radius for buttons/badges
    static func small(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .regular ? 10 : 8
    }
}

struct AdaptiveSize {
    /// Scale a size value for iPad
    static func scale(_ value: CGFloat, for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        guard sizeClass == .regular else { return value }
        return value * 1.2
    }
}
