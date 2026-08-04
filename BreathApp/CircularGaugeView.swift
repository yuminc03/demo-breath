import SwiftUI

/// 현재 호흡 단계와 남은 초를 원형 게이지로 크게 보여주는 뷰.
struct CircularGaugeView: View {
    let progress: Double
    let color: Color
    let phaseText: String
    let remainingSeconds: Int

    private let lineWidth: CGFloat = 22

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.05), value: progress)

            VStack(spacing: 8) {
                Text(phaseText)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
                Text("\(remainingSeconds)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
        }
        .frame(width: 280, height: 280)
    }
}

#Preview {
    CircularGaugeView(progress: 0.4, color: .blue, phaseText: "들숨", remainingSeconds: 2)
}
