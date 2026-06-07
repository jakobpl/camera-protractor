import SwiftUI

enum ProtractorPlacement: String, CaseIterable, Identifiable {
    case top
    case bottom
    case left
    case right

    var id: String { rawValue }

    var label: String {
        switch self {
        case .top: return "Top"
        case .bottom: return "Bottom"
        case .left: return "Left"
        case .right: return "Right"
        }
    }

    var iconName: String {
        switch self {
        case .top: return "arrow.up.to.line"
        case .bottom: return "arrow.down.to.line"
        case .left: return "arrow.left.to.line"
        case .right: return "arrow.right.to.line"
        }
    }

    fileprivate var startDegrees: Double {
        switch self {
        case .top: return 0
        case .bottom: return 180
        case .left: return -90
        case .right: return 90
        }
    }

    fileprivate func center(in size: CGSize, radius: CGFloat) -> CGPoint {
        switch self {
        case .top:
            return CGPoint(x: size.width / 2, y: 0)
        case .bottom:
            return CGPoint(x: size.width / 2, y: size.height)
        case .left:
            return CGPoint(x: 0, y: size.height / 2)
        case .right:
            return CGPoint(x: size.width, y: size.height / 2)
        }
    }

    fileprivate func radius(in size: CGSize) -> CGFloat {
        switch self {
        case .top, .bottom:
            return min(size.width * 0.48, size.height * 0.62)
        case .left, .right:
            return min(size.height * 0.43, size.width * 0.78)
        }
    }
}

struct ProtractorOverlayView: View {
    let currentAngle: Double
    let baselineAngle: Double?
    let relativeAngle: Double?
    let isLevel: Bool
    let placement: ProtractorPlacement

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let radius = placement.radius(in: size)
            let center = placement.center(in: size, radius: radius)
            let badgePoint = badgePosition(in: size, center: center, radius: radius)

            Canvas { context, _ in
                drawGrid(context: &context, size: size)
                drawProtractor(context: &context, center: center, radius: radius)
                drawBaseline(context: &context, center: center, radius: radius)
                drawCurrentNeedle(context: &context, center: center, radius: radius)
            }

            levelBadge
                .position(badgePoint)
        }
        .allowsHitTesting(false)
    }

    private var levelBadge: some View {
        Text(isLevel ? "LEVEL" : "TILT")
            .font(.caption.weight(.bold))
            .monospaced()
            .foregroundStyle(isLevel ? .black : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isLevel ? Color.mint.opacity(0.95) : Color.red.opacity(0.8), in: Capsule())
    }

    private func drawGrid(context: inout GraphicsContext, size: CGSize) {
        let fineSpacing: CGFloat = 28
        let coarseSpacing = fineSpacing * 2

        for x in stride(from: CGFloat(0), through: size.width, by: fineSpacing) {
            let isCoarse = Int((x / coarseSpacing).rounded()) * Int(coarseSpacing) == Int(x.rounded())
            var line = Path()
            line.move(to: CGPoint(x: x, y: 0))
            line.addLine(to: CGPoint(x: x, y: size.height))
            context.stroke(line, with: .color(.white.opacity(isCoarse ? 0.34 : 0.18)), lineWidth: isCoarse ? 1.1 : 0.7)
        }

        for y in stride(from: CGFloat(0), through: size.height, by: fineSpacing) {
            let isCoarse = Int((y / coarseSpacing).rounded()) * Int(coarseSpacing) == Int(y.rounded())
            var line = Path()
            line.move(to: CGPoint(x: 0, y: y))
            line.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(line, with: .color(.white.opacity(isCoarse ? 0.34 : 0.18)), lineWidth: isCoarse ? 1.1 : 0.7)
        }
    }

    private func drawProtractor(context: inout GraphicsContext, center: CGPoint, radius: CGFloat) {
        let innerRadius = radius * 0.62
        let start = placement.startDegrees
        let end = start + 180

        var ring = Path()
        ring.addArc(center: center, radius: radius, startAngle: .degrees(start), endAngle: .degrees(end), clockwise: false)
        ring.addArc(center: center, radius: innerRadius, startAngle: .degrees(end), endAngle: .degrees(start), clockwise: true)
        ring.closeSubpath()

        context.fill(ring, with: .color(.white.opacity(0.34)))
        context.stroke(ring, with: .color(.black.opacity(0.42)), lineWidth: 1.4)

        for degree in 0...180 {
            let tickAngle = Angle.degrees(start + Double(degree))
            let tickLength: CGFloat
            let lineWidth: CGFloat
            let opacity: Double

            if degree.isMultiple(of: 10) {
                tickLength = 34
                lineWidth = 1.6
                opacity = 0.78
            } else if degree.isMultiple(of: 5) {
                tickLength = 24
                lineWidth = 1
                opacity = 0.62
            } else {
                tickLength = 14
                lineWidth = 0.65
                opacity = 0.48
            }

            let outer = point(center: center, radius: radius, angle: tickAngle)
            let inner = point(center: center, radius: radius - tickLength, angle: tickAngle)

            var tickPath = Path()
            tickPath.move(to: outer)
            tickPath.addLine(to: inner)
            context.stroke(tickPath, with: .color(.black.opacity(opacity)), lineWidth: lineWidth)

            if degree.isMultiple(of: 10) {
                drawLabel(
                    context: &context,
                    text: "\(degree)",
                    center: center,
                    radius: radius - 50,
                    angle: tickAngle,
                    color: .black,
                    fontSize: degree.isMultiple(of: 30) ? 18 : 15
                )

                drawLabel(
                    context: &context,
                    text: "\(180 - degree)",
                    center: center,
                    radius: innerRadius + 23,
                    angle: tickAngle,
                    color: .white,
                    fontSize: 14
                )
            }
        }

        var innerArc = Path()
        innerArc.addArc(center: center, radius: innerRadius, startAngle: .degrees(start), endAngle: .degrees(end), clockwise: false)
        context.stroke(innerArc, with: .color(.white.opacity(0.5)), lineWidth: 1)
    }

    private func drawBaseline(context: inout GraphicsContext, center: CGPoint, radius: CGFloat) {
        guard let baselineAngle else { return }

        let end = point(center: center, radius: radius * 1.35, angle: needleAngle(for: baselineAngle))
        var line = Path()
        line.move(to: center)
        line.addLine(to: end)
        context.stroke(line, with: .color(.mint.opacity(0.9)), style: StrokeStyle(lineWidth: 3, dash: [9, 5]))
    }

    private func drawCurrentNeedle(context: inout GraphicsContext, center: CGPoint, radius: CGFloat) {
        let angle = needleAngle(for: currentAngle)
        let end = point(center: center, radius: radius * 1.45, angle: angle)

        var needle = Path()
        needle.move(to: center)
        needle.addLine(to: end)
        context.stroke(needle, with: .color(.blue.opacity(0.95)), lineWidth: 4)

        let hub = Path(ellipseIn: CGRect(x: center.x - 8, y: center.y - 8, width: 16, height: 16))
        context.fill(hub, with: .color(.blue.opacity(0.86)))
        context.stroke(hub, with: .color(.white.opacity(0.75)), lineWidth: 1.4)
    }

    private func drawLabel(
        context: inout GraphicsContext,
        text: String,
        center: CGPoint,
        radius: CGFloat,
        angle: Angle,
        color: Color,
        fontSize: CGFloat
    ) {
        let labelPoint = point(center: center, radius: radius, angle: angle)
        var label = context.resolve(Text(text)
            .font(.system(size: fontSize, weight: .semibold, design: .rounded))
        )
        label.shading = .color(color.opacity(0.92))
        context.draw(label, at: labelPoint, anchor: .center)
    }

    private func needleAngle(for angle: Double) -> Angle {
        switch placement {
        case .left:
            return .degrees(angle)
        case .right:
            return .degrees(180 + angle)
        case .top:
            return .degrees(90 + angle)
        case .bottom:
            return .degrees(-90 + angle)
        }
    }

    private func badgePosition(in size: CGSize, center: CGPoint, radius: CGFloat) -> CGPoint {
        switch placement {
        case .top:
            return CGPoint(x: size.width - 62, y: min(radius + 30, size.height - 92))
        case .bottom:
            return CGPoint(x: size.width - 62, y: max(size.height - radius - 30, 92))
        case .left:
            return CGPoint(x: min(radius + 58, size.width - 62), y: 92)
        case .right:
            return CGPoint(x: max(size.width - radius - 58, 62), y: 92)
        }
    }

    private func point(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        CGPoint(
            x: center.x + cos(angle.radians) * radius,
            y: center.y + sin(angle.radians) * radius
        )
    }
}
