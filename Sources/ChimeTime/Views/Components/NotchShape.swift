import SwiftUI

struct NotchShape: Shape {
    var cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Slight outset at top so boundary points (0,0) and (width,0) are inside the filled region
        let outset: CGFloat = 0.25

        // Top-left, slightly outside rect
        path.move(to: CGPoint(x: rect.minX - outset, y: rect.minY - outset))

        // Top-right, slightly outside rect
        path.addLine(to: CGPoint(x: rect.maxX + outset, y: rect.minY - outset))

        // Right edge down to bottom-right curve
        path.addLine(to: CGPoint(x: rect.maxX + outset, y: rect.maxY - cornerRadius))

        // Bottom-right rounded corner (quadratic curve for smooth transition)
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY),
            control: CGPoint(x: rect.maxX + outset, y: rect.maxY)
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))

        // Bottom-left rounded corner
        path.addQuadCurve(
            to: CGPoint(x: rect.minX - outset, y: rect.maxY - cornerRadius),
            control: CGPoint(x: rect.minX - outset, y: rect.maxY)
        )

        // Left edge back up, close path
        path.closeSubpath()

        return path
    }
}
