import SwiftUI

struct ProtractorOverlayView: View {
    let currentAngle: Double
    let baselineAngle: Double?
    let relativeAngle: Double?
    let isLevel: Bool

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let radius = min(size.width, size.height) * 0.42
            let center = CGPoint(x: size.width / 2, y: size.height * 0.46)

            Canvas { context, _ in
                drawProtractor(context: &context, center: center, radius: radius)
                drawLevelLine(context: &context, center: center, radius: radius)
                drawBaseline(context: &context, center: center, radius: radius)
                drawCurrentNeedle(context: &context, center: center, radius: radius)
            }

            levelBadge
                .position(x: size.width / 2, y: center.y + radius + 32)
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

    private func drawProtractor(context: inout GraphicsContext, center: CGPoint, radius: CGFloat) {
        var arc = Path()
        arc.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(200),
            endAngle: .degrees(340),
            clockwise: false
        )
        context.stroke(arc, with: .color(.white.opacity(0.56)), lineWidth: 2)

        for tick in stride(from: -70, through: 70, by: 5) {
            let isMajor = tick.isMultiple(of: 15)
            let angle = Angle.degrees(Double(tick - 90))
            let outer = point(center: center, radius: radius, angle: angle)
            let inner = point(center: center, radius: radius - (isMajor ? 20 : 10), angle: angle)

            var tickPath = Path()
            tickPath.move(to: outer)
            tickPath.addLine(to: inner)
            context.stroke(
                tickPath,
                with: .color(.white.opacity(isMajor ? 0.72 : 0.38)),
                lineWidth: isMajor ? 2 : 1
            )
        }
    }

    private func drawLevelLine(context: inout GraphicsContext, center: CGPoint, radius: CGFloat) {
        var line = Path()
        line.move(to: CGPoint(x: center.x - radius * 0.86, y: center.y))
        line.addLine(to: CGPoint(x: center.x + radius * 0.86, y: center.y))
        context.stroke(line, with: .color(.white.opacity(0.5)), style: StrokeStyle(lineWidth: 1.5, dash: [6, 7]))
    }

    private func drawBaseline(context: inout GraphicsContext, center: CGPoint, radius: CGFloat) {
        guard let baselineAngle else { return }

        let end = point(center: center, radius: radius * 0.78, angle: .degrees(baselineAngle - 90))
        var line = Path()
        line.move(to: center)
        line.addLine(to: end)
        context.stroke(line, with: .color(.mint.opacity(0.85)), style: StrokeStyle(lineWidth: 3, dash: [9, 5]))
    }

    private func drawCurrentNeedle(context: inout GraphicsContext, center: CGPoint, radius: CGFloat) {
        let angle = Angle.degrees(currentAngle - 90)
        let end = point(center: center, radius: radius * 0.9, angle: angle)

        var needle = Path()
        needle.move(to: center)
        needle.addLine(to: end)
        context.stroke(needle, with: .color(.yellow.opacity(0.95)), lineWidth: 4)

        let hub = Path(ellipseIn: CGRect(x: center.x - 7, y: center.y - 7, width: 14, height: 14))
        context.fill(hub, with: .color(.yellow))
    }

    private func point(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        CGPoint(
            x: center.x + cos(angle.radians) * radius,
            y: center.y + sin(angle.radians) * radius
        )
    }
}
