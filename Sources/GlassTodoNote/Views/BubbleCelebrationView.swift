import SwiftUI

struct BubbleCelebrationView: View {
    let seed: Int
    @State private var animate = false

    var body: some View {
        GeometryReader { proxy in
            ForEach(0..<12, id: \.self) { index in
                Circle()
                    .strokeBorder(.white.opacity(0.7), lineWidth: 1)
                    .background(Circle().fill(.cyan.opacity(0.12)))
                    .frame(width: bubbleSize(index), height: bubbleSize(index))
                    .position(x: xPosition(index, width: proxy.size.width), y: animate ? -40 : 24)
                    .opacity(animate ? 0 : 1)
                    .animation(.easeOut(duration: 1.8).delay(Double(index) * 0.04), value: animate)
            }
        }
        .frame(height: 120)
        .onAppear {
            animate = true
        }
    }

    private func bubbleSize(_ index: Int) -> CGFloat {
        CGFloat(8 + ((seed + index * 7) % 15))
    }

    private func xPosition(_ index: Int, width: CGFloat) -> CGFloat {
        let bucket = CGFloat((seed + index * 37) % 100) / 100
        return max(12, min(width - 12, bucket * width))
    }
}
