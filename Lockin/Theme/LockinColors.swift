import SwiftUI

enum LockinColor {
    static let background       = Color(red: 0x11/255, green: 0x13/255, blue: 0x18/255)
    static let backgroundDeep   = Color(red: 0x08/255, green: 0x0A/255, blue: 0x0F/255)
    static let surface          = Color(red: 0x1C/255, green: 0x20/255, blue: 0x27/255)
    static let surfacePlus      = Color(red: 0x25/255, green: 0x2B/255, blue: 0x34/255)
    static let border           = Color(red: 0x2E/255, green: 0x34/255, blue: 0x40/255)

    static let textPrimary      = Color(red: 0xF0/255, green: 0xF2/255, blue: 0xF5/255)
    static let textSecondary    = Color(red: 0x7B/255, green: 0x84/255, blue: 0x94/255)
    static let textTertiary     = Color(red: 0x4E/255, green: 0x56/255, blue: 0x64/255)

    static let red              = Color(red: 0xFF/255, green: 0x33/255, blue: 0x33/255)
    static let redDeep          = Color(red: 0xB8/255, green: 0x1F/255, blue: 0x1F/255)
    static let green            = Color(red: 0x1D/255, green: 0xB9/255, blue: 0x54/255)
    static let blue             = Color(red: 0x4A/255, green: 0x9E/255, blue: 0xFF/255)
    static let amber            = Color(red: 0xFF/255, green: 0xB3/255, blue: 0x00/255)

    static let heroGradient = LinearGradient(
        colors: [Color(red: 0xFF/255, green: 0x33/255, blue: 0x33/255),
                 Color(red: 0xB8/255, green: 0x1F/255, blue: 0x1F/255)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let ringGradient = AngularGradient(
        colors: [
            Color(red: 0xFF/255, green: 0x4D/255, blue: 0x4D/255),
            Color(red: 0xFF/255, green: 0x7A/255, blue: 0x2E/255),
            Color(red: 0xFF/255, green: 0xB3/255, blue: 0x00/255),
            Color(red: 0xFF/255, green: 0x4D/255, blue: 0x4D/255)
        ],
        center: .center,
        startAngle: .degrees(-90),
        endAngle: .degrees(270)
    )

    static let paywallBackdrop = RadialGradient(
        colors: [
            Color(red: 0x2A/255, green: 0x08/255, blue: 0x0A/255),
            Color(red: 0x08/255, green: 0x0A/255, blue: 0x0F/255)
        ],
        center: .top,
        startRadius: 60,
        endRadius: 820
    )

    static let blockingActiveBackdrop = RadialGradient(
        colors: [
            Color(red: 0x2C/255, green: 0x00/255, blue: 0x00/255),
            Color(red: 0x00/255, green: 0x00/255, blue: 0x00/255)
        ],
        center: .bottom,
        startRadius: 20,
        endRadius: 900
    )
}
