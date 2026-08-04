import SwiftUI

/// 햅틱을 느끼기 어려운 사용자를 위해, 현재 단계를 **눈으로도 따라갈 수 있게** 하는 효과.
///
/// 단계 전환 순간에만 반짝이는 신호는 놓치기 쉬우므로, 단계가 진행되는 내내
/// 이어지는 변화를 준다. 들숨에는 게이지가 서서히 커지고 날숨에는 서서히 작아져서,
/// 어느 순간에 화면을 보더라도 지금이 들이쉴 때인지 내쉴 때인지 알 수 있다.
///
/// **손쉬운 사용 - 동작 줄이기**가 켜져 있으면 크기 변화(움직임) 대신
/// 밝기 변화로 같은 정보를 전달한다. 신호를 없애는 것이 아니라 형태만 바꾼다.
struct BreathVisualCue: ViewModifier {
    let phase: BreathPhase
    /// 세션이 진행 중일 때만 효과를 준다. 대기/종료 상태에서는 기본값으로 되돌린다.
    let isRunning: Bool
    /// 한 단계의 길이. 변화가 단계 길이에 정확히 맞춰 진행되도록 애니메이션 시간으로 쓴다.
    let duration: TimeInterval

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// 날숨 끝에서 가장 작아지는 비율. 너무 크면 레이아웃을 넘고, 너무 작으면 눈에 안 띈다.
    private static let contractedScale: CGFloat = 0.88
    /// 동작 줄이기 상태에서 날숨 끝의 밝기.
    private static let contractedOpacity: Double = 0.5

    /// 실제로 화면에 적용 중인 값.
    ///
    /// `.animation(_:value:)`로 `phase`를 직접 관찰하면 아래에 붙은 뷰의 **색상과 글자까지**
    /// 같은 시간(4초)에 걸쳐 크로스페이드되어, 단계가 바뀌었는데 문구는 이전 것이 남는다.
    /// 그래서 크기·밝기만 상태로 따로 들고, `withAnimation`으로 그 값만 애니메이션한다.
    @State private var appliedScale: CGFloat = 1
    @State private var appliedOpacity: Double = 1

    func body(content: Content) -> some View {
        content
            .scaleEffect(reduceMotion ? 1 : appliedScale)
            .opacity(reduceMotion ? appliedOpacity : 1)
            .onAppear { updateCue() }
            .onChange(of: phase) { _ in updateCue() }
            .onChange(of: isRunning) { _ in updateCue() }
    }

    private func updateCue() {
        withAnimation(.easeInOut(duration: animationDuration)) {
            appliedScale = targetScale
            appliedOpacity = targetOpacity
        }
    }

    /// 대기 상태로 돌아갈 때는 단계 길이만큼 늘어지면 답답하므로 짧게 되돌린다.
    private var animationDuration: TimeInterval {
        isRunning ? duration : 0.3
    }

    /// 들숨의 목표는 1.0, 날숨의 목표는 축소값이다.
    /// 목표값 사이를 단계 길이에 맞춰 이동하므로 들숨엔 커지고 날숨엔 작아진다.
    private var targetScale: CGFloat {
        guard isRunning else { return 1 }
        switch phase {
        case .inhale, .hold: return 1
        case .exhale: return Self.contractedScale
        }
    }

    private var targetOpacity: Double {
        guard isRunning else { return 1 }
        switch phase {
        case .inhale, .hold: return 1
        case .exhale: return Self.contractedOpacity
        }
    }
}

extension View {
    /// 현재 호흡 단계를 크기(또는 동작 줄이기 시 밝기) 변화로 드러낸다.
    func breathVisualCue(
        phase: BreathPhase,
        isRunning: Bool,
        duration: TimeInterval
    ) -> some View {
        modifier(BreathVisualCue(phase: phase, isRunning: isRunning, duration: duration))
    }
}
