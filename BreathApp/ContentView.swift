import SwiftUI

struct ContentView: View {
    @StateObject private var engine = BreathEngine()

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            Text(statusTitle)
                .font(.headline)
                .foregroundStyle(.secondary)

            CircularGaugeView(
                progress: engine.progressInPhase,
                color: phaseColor,
                phaseText: engine.currentPhase.displayName,
                remainingSeconds: remainingSecondsInPhase
            )

            Text("세션 남은 시간 \(sessionTimeText)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            actionButton

            Spacer()
        }
        .padding()
    }

    private var phaseColor: Color {
        switch engine.currentPhase {
        case .inhale: return .blue
        case .hold: return .purple
        case .exhale: return .green
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
