import SwiftUI

struct ContentView: View {
    @StateObject private var engine = BreathEngine()
    @StateObject private var activityController = BreathActivityController()

    /// 라이브 액티비티의 고정 값으로 실리는 세션 이름.
    private let sessionName = "호흡 세션"

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            Text(statusTitle)
                .font(.headline)
                .foregroundStyle(.secondary)

            CircularGaugeView(
                progress: engine.progressInPhase,
                color: engine.currentPhase.tintColor,
                phaseText: engine.currentPhase.displayName,
                remainingSeconds: remainingSecondsInPhase
            )
            .breathVisualCue(
                phase: engine.currentPhase,
                isRunning: engine.sessionState == .running,
                duration: engine.phaseDuration
            )

            Text("세션 남은 시간 \(sessionTimeText)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            actionButton

            Spacer()
        }
        .padding()
        .task { connectSideEffects() }
    }

    /// 엔진의 단계 전환을 라이브 액티비티와 햅틱으로 흘려보낸다.
    private func connectSideEffects() {
        let controller = activityController
        let name = sessionName

        // 앱이 강제 종료된 뒤 잠금 화면에 남아 있을 수 있는 이전 세션의 액티비티를 정리한다.
        controller.endAll()

        engine.onPhaseChange = { phase, start, end in
            BreathHaptics.play(for: phase)
            controller.apply(sessionName: name, phase: phase, start: start, end: end)
        }
        engine.onSessionEnd = { reason in
            if reason == .completed {
                BreathHaptics.playSessionCompleted()
            }
            controller.endAll()
        }
    }

    private var remainingSecondsInPhase: Int {
        Int(engine.remainingInPhase.rounded(.up))
    }

    private var sessionTimeText: String {
        let total = Int(engine.remainingInSession.rounded(.up))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var statusTitle: String {
        switch engine.sessionState {
        case .idle: return "준비"
        case .running: return "호흡 중"
        case .finished: return "세션 종료"
        }
    }

    private var actionButton: some View {
        Button {
            if engine.sessionState == .running {
                engine.stop()
            } else {
                BreathHaptics.prepare()
                engine.start()
            }
        } label: {
            Text(engine.sessionState == .running ? "중지" : "시작")
                .font(.title2.bold())
                .frame(maxWidth: .infinity)
                .padding()
                .background(engine.sessionState == .running ? Color.red : Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    ContentView()
}
