import Foundation
import Combine

/// 호흡 사이클의 한 단계(들숨/멈춤/날숨)를 나타낸다.
enum BreathPhase: CaseIterable {
    case inhale
    case hold
    case exhale

    var displayName: String {
        switch self {
        case .inhale: return "들숨"
        case .hold: return "멈춤"
        case .exhale: return "날숨"
        }
    }
}

/// 호흡 세션 전체 진행 상태를 나타낸다.
enum BreathSessionState {
    case idle
    case running
    case finished
}

/// 들숨 → 멈춤 → 날숨 사이클을 반복하며, 지정된 세션 길이가 지나면 자동으로 종료되는 호흡 엔진.
/// UI 로직과 분리되어 독립적으로 테스트 가능하도록 설계되었다.
final class BreathEngine: ObservableObject {

    @Published private(set) var sessionState: BreathSessionState = .idle
    @Published private(set) var currentPhase: BreathPhase
    @Published private(set) var remainingInPhase: TimeInterval
    @Published private(set) var remainingInSession: TimeInterval

    let phaseDuration: TimeInterval
    let sessionDuration: TimeInterval

    /// 부드러운 게이지 애니메이션을 위한 타이머 갱신 주기.
    private let tickInterval: TimeInterval = 0.05

    private var timer: Timer?
    private var phaseElapsed: TimeInterval = 0
    private var sessionElapsed: TimeInterval = 0
    private var phaseIndex = 0
    private let phaseOrder: [BreathPhase] = [.inhale, .hold, .exhale]

    /// - Parameters:
    ///   - phaseDuration: 각 단계(들숨/멈춤/날숨)의 길이. 기본 4초.
    ///   - sessionDuration: 전체 세션 길이. 기본 180초(3분).
    init(phaseDuration: TimeInterval = 4.0, sessionDuration: TimeInterval = 180) {
        self.phaseDuration = phaseDuration
        self.sessionDuration = sessionDuration
        self.currentPhase = phaseOrder[0]
        self.remainingInPhase = phaseDuration
        self.remainingInSession = sessionDuration
    }

    /// 현재 단계 내 진행률 (0.0 ~ 1.0). 원형 게이지 채우기에 사용.
    var progressInPhase: Double {
        guard phaseDuration > 0 else { return 0 }
        return 1 - (remainingInPhase / phaseDuration)
    }

    /// 전체 세션 진행률 (0.0 ~ 1.0).
    var progressInSession: Double {
        guard sessionDuration > 0 else { return 0 }
        return 1 - (remainingInSession / sessionDuration)
    }

    func start() {
        guard sessionState != .running else { return }
        resetState()
        sessionState = .running
        let newTimer = Timer(timeInterval: tickInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }

    func stop() {
        invalidateTimer()
        sessionState = .idle
        resetState()
    }

    private func tick() {
        sessionElapsed += tickInterval
        phaseElapsed += tickInterval

        remainingInSession = max(0, sessionDuration - sessionElapsed)

        if sessionElapsed >= sessionDuration {
            finishSession()
            return
        }

        if phaseElapsed >= phaseDuration {
            advancePhase()
        } else {
            remainingInPhase = max(0, phaseDuration - phaseElapsed)
        }
    }

    private func advancePhase() {
        phaseElapsed = 0
        phaseIndex = (phaseIndex + 1) % phaseOrder.count
        currentPhase = phaseOrder[phaseIndex]
        remainingInPhase = phaseDuration
    }

    private func finishSession() {
        invalidateTimer()
        sessionState = .finished
        remainingInSession = 0
        remainingInPhase = 0
    }

    private func resetState() {
        phaseIndex = 0
        currentPhase = phaseOrder[0]
        phaseElapsed = 0
        sessionElapsed = 0
        remainingInPhase = phaseDuration
        remainingInSession = sessionDuration
    }

    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }

    deinit {
        timer?.invalidate()
    }
}
