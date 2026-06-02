import GlassTodoNoteCore
import SwiftUI

struct ProgressDragView: View {
    let progress: Double
    let zoom: Double
    var onChange: (Double) -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)
                Capsule()
                    .fill(.tint)
                    .frame(width: proxy.size.width * progress / 100)
                Circle()
                    .fill(.white)
                    .shadow(radius: 2)
                    .frame(width: metric(18), height: metric(18))
                    .offset(x: max(0, proxy.size.width * progress / 100 - metric(9)))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let fraction = min(1, max(0, value.location.x / max(1, proxy.size.width)))
                        onChange(fraction * 100)
                    }
            )
        }
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(progress.rounded())) percent")
    }

    private func metric(_ baseValue: Double) -> CGFloat {
        CGFloat(WindowZoom.metric(baseValue, for: zoom))
    }
}
