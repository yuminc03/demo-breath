import SwiftUI

/// 현재 호흡 단계와 남은 초를 원형 게이지로 보여주는 뷰.
///
/// iPhone(기본 280pt)과 Apple Watch(화면에 맞춘 작은 크기)가 같은 컴포넌트를 쓴다.
/// 선 굵기와 글자 크기를 `size`에 비례시켜 두어, 어느 크기에서도 원본 비율이 유지된다.
/// (280pt일 때 각각 22pt / 22pt / 72pt로 기존 iPhone 레이아웃과 같은 값이 된다.)
struct CircularGaugeView: View {
    let progress: Double
    let color: Color
    let phaseText: String
    let remainingSeconds: Int
    var size: CGFloat = 280

    private var lineWidth: CGFloat { size * 0.0786 }
    private var phaseFontSize: CGFloat { size * 0.0786 }
    private var secondsFontSize: CGFloat { size * 0.2571 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.05), value: progress)

            VStack(spacing: size * 0.0286) {
                Text(phaseText)
                    .font(.system(size: phaseFontSize, weight: .semibold))
                    .foregroundStyle(color)
                Text("\(remainingSeconds)")
                    .font(.system(size: secondsFontSize, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    CircularGaugeView(progress: 0.4, color: .blue, phaseText: "들숨", remainingSeconds: 2)
}
