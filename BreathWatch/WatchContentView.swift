import SwiftUI

/// Apple Watch 호흡 화면.
///
/// iPhone 앱과 **같은 `BreathEngine`·`CircularGaugeView`** 를 그대로 쓰고,
/// 워치 고유의 입력인 Digital Crown으로 세션 길이(1~10분)를 조절한다.
struct WatchContentView: View {
    @StateObject private var engine = BreathEngine()

    /// Digital Crown이 물고 도는 값(분). 대기 상태에서만 엔진에 반영한다.
    @State private var sessionMinutes: Double = 3
    @FocusState private var isCrownFocused: Bool

    private static let minuteRange: ClosedRange<Double> = 1...10

    /// 게이지 아래에 두는 안내 문구 + 버튼 + 간격이 차지하는 높이.
    private static let footerHeight: CGFloat = 58
    private static let stackSpacing: CGFloat = 4

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: Self.stackSpacing) {
                CircularGaugeView(
                    progress: engine.progressInPhase,
                    color: engine.currentPhase.tintColor,
                    phaseText: engine.currentPhase.displayName,
                    remainingSeconds: remainingSecondsInPhase,
                    size: gaugeSize(in: proxy.size)
                )
                .breathVisualCue(
                    phase: engine.currentPhase,
                    isRunning: engine.sessionState == .running,
                    duration: engine.phaseDuration
                )

                footer

                actionButton
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .focusable(true)
        .focused($isCrownFocused)
        .digitalCrownRotation(
            $sessionMinutes,
            from: Self.minuteRange.lowerBound,
            through: Self.minuteRange.upperBound,
            by: 1,
            sensitivity: .low,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        .onChange(of: sessionMinutes) { newValue in
            applySessionMinutes(newValue)
        }
        .onAppear {
            isCrownFocused = true
            applySessionMinutes(sessionMinutes)
            connectHaptics()
        }
    }

    /// 단계 전환과 세션 완료를 햅틱으로 알린다.
    ///
    /// 워치에서는 이 햅틱이 주된 안내 수단이다. 손목을 보지 않아도
    /// 들숨(올라가는 느낌) / 멈춤(짧은 클릭) / 날숨(내려가는 느낌)을 구분할 수 있다.
    private func connectHaptics() {
        engine.onPhaseChange = { phase, _, _ in
            BreathHaptics.play(for: phase)
        }
        engine.onSessionEnd = { reason in
            if reason == .completed {
                BreathHaptics.playSessionCompleted()
            }
        }
    }

    /// 게이지 크기를 정한다.
    ///
    /// 화면 폭과, 하단 문구·버튼이 쓸 높이를 뺀 나머지 중 작은 쪽에 맞춘다.
    /// 41mm처럼 좁은 워치에서도 버튼이 화면 밖으로 밀리지 않도록 비율 추정 대신
    /// 실제로 예약한 높이를 빼서 계산한다.
    private func gaugeSize(in size: CGSize) -> CGFloat {
        let availableHeight = size.height - Self.footerHeight - (Self.stackSpacing * 2)
        return max(60, min(size.width, availableHeight))
    }

    /// 대기 중에는 Crown으로 고른 세션 길이를, 진행 중에는 남은 시간을 보여준다.
    @ViewBuilder
    private var footer: some View {
        if engine.sessionState == .running {
            Text(sessionTimeText)
                .font(.caption2)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        } else {
            Label("\(Int(sessionMinutes))분", systemImage: "digitalcrown.horizontal.arrow.clockwise")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var actionButton: some View {
        Button {
            if engine.sessionState == .running {
                engine.stop()
            } else {
                engine.start()
            }
        } label: {
            Text(engine.sessionState == .running ? "중지" : "시작")
                .font(.footnote.bold())
                .frame(maxWidth: .infinity)
        }
        .tint(engine.sessionState == .running ? .red : .blue)
    }

    /// Crown 값(분)을 엔진에 초 단위로 반영한다. 진행 중이면 엔진이 알아서 무시한다.
    private func applySessionMinutes(_ minutes: Double) {
        engine.setSessionDuration(minutes.rounded() * 60)
    }

    private var remainingSecondsInPhase: Int {
        Int(engine.remainingInPhase.rounded(.up))
    }

    private var sessionTimeText: String {
        let total = Int(engine.remainingInSession.rounded(.up))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

#Preview {
    WatchContentView()
}
