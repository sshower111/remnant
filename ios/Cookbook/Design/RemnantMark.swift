import SwiftUI

/// The logo's mark, drawn as vectors: a saved bookmark with a bite taken out of it (what's left
/// of the recipe), and two crumbs in ember. Same geometry as `design/logo/final/make.py`
/// (a 256 grid: bookmark 58–154 wide, 36–222 tall, bite r 42 at 158,100).
struct RemnantMark: View {
    var markColor: Color = .textPrimary
    var crumbColor: Color = .ember

    var body: some View {
        Canvas { context, size in
            let s = min(size.width / 146.5, size.height / 186)   // the mark's bounding box, 58…204.5 × 36…222
            context.translateBy(x: -58 * s, y: -36 * s)
            context.scaleBy(x: s, y: s)
            context.fill(Self.bookmark, with: .color(markColor))
            for (x, y, r) in [(178.0, 160.0, 10.0), (198.0, 136.0, 6.5)] {
                context.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                             with: .color(crumbColor))
            }
        }
        .aspectRatio(146.5 / 186, contentMode: .fit)
        .accessibilityHidden(true)
    }

    /// The bookmark minus the bite.
    static let bookmark: Path = {
        var mark = Path()
        mark.move(to: CGPoint(x: 74, y: 36))
        mark.addLine(to: CGPoint(x: 138, y: 36))
        mark.addArc(tangent1End: CGPoint(x: 154, y: 36), tangent2End: CGPoint(x: 154, y: 52), radius: 16)
        mark.addLine(to: CGPoint(x: 154, y: 222))
        mark.addLine(to: CGPoint(x: 106, y: 174))
        mark.addLine(to: CGPoint(x: 58, y: 222))
        mark.addLine(to: CGPoint(x: 58, y: 52))
        mark.addArc(tangent1End: CGPoint(x: 58, y: 36), tangent2End: CGPoint(x: 74, y: 36), radius: 16)
        mark.closeSubpath()
        let bite = Path(ellipseIn: CGRect(x: 158 - 42, y: 100 - 42, width: 84, height: 84))
        return mark.subtracting(bite)
    }()
}

#Preview {
    HStack(spacing: 24) {
        RemnantMark().frame(height: 120)
        RemnantMark().frame(height: 24)
    }
    .padding()
    .background(Color.canvas)
}
