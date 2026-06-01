import SwiftUI

struct GlassShatterView: View {
    @State private var animate = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<10, id: \.self) { index in
                    shard(index: index, size: proxy.size)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .onAppear {
                withAnimation(.easeOut(duration: 0.75)) {
                    animate = true
                }
            }
        }
    }

    private func shard(index: Int, size: CGSize) -> some View {
        let width = max(18, size.width / 4)
        let height = max(14, size.height / 2)
        let startX = CGFloat(index % 5) * size.width / 5
        let startY = CGFloat(index / 5) * size.height / 2
        let direction = CGFloat(index.isMultiple(of: 2) ? 1 : -1)

        return Rectangle()
            .fill(.ultraThinMaterial)
            .overlay(Rectangle().stroke(.white.opacity(0.45), lineWidth: 0.7))
            .frame(width: width, height: height)
            .rotationEffect(.degrees(animate ? Double(index * 17) : 0))
            .offset(
                x: startX + (animate ? direction * CGFloat(18 + index * 3) : 0),
                y: startY + (animate ? CGFloat(18 + index * 4) : 0)
            )
            .opacity(animate ? 0 : 0.9)
    }
}
