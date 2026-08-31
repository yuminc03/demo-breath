import ActivityKit
import Foundation

/// `BreathEngine`의 단계 전환을 라이브 액티비티로 중계하는 얇은 래퍼.
///
/// 엔진이 ActivityKit을 직접 알지 못하도록 중간 계층으로 두었다.
/// 요청(request) / 갱신(update) / 종료(end)라는 ActivityKit 생명주기를 여기에 가둔다.
final class BreathActivityController: ObservableObject {

    private var activity: Activity<BreathActivityAttributes>?

    /// 사용자가 설정에서 라이브 액티비티를 꺼두었는지 여부.
    var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    /// 단계 전환마다 호출된다. 진행 중인 액티비티가 없으면 새로 요청하고, 있으면 갱신한다.
    func apply(sessionName: String, phase: BreathPhase, start: Date, end: Date) {
        let state = BreathActivityAttributes.ContentState(
            phase: phase,
            phaseStart: start,
            phaseEnd: end
        )

        if let activity {
            update(activity, state: state)
        } else {
            request(sessionName: sessionName, state: state)
        }
    }

    /// 세션이 끝나면 액티비티를 즉시 내린다.
    ///
    /// 로컬 참조만 보지 않고 시스템에 등록된 액티비티 전체를 훑는 이유는,
    /// 앱이 강제 종료됐다가 다시 실행되면 이 객체가 새로 만들어져 `activity`가 nil이 되는데
    /// 잠금 화면에는 이전 실행이 띄운 액티비티가 그대로 남아 있기 때문이다.
    func endAll() {
        let running = Activity<BreathActivityAttributes>.activities
        activity = nil
        guard !running.isEmpty else { return }

        Task {
            for item in running {
                await item.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    private func request(sessionName: String, state: BreathActivityAttributes.ContentState) {
        guard areActivitiesEnabled else { return }

        do {
            activity = try Activity.request(
                attributes: BreathActivityAttributes(sessionName: sessionName),
                content: ActivityContent(state: state, staleDate: staleDate(for: state)),
                pushType: nil
            )
        } catch {
            print("라이브 액티비티 시작 실패: \(error.localizedDescription)")
        }
    }

    private func update(
        _ activity: Activity<BreathActivityAttributes>,
        state: BreathActivityAttributes.ContentState
    ) {
        Task {
            await activity.update(
                ActivityContent(state: state, staleDate: staleDate(for: state))
            )
        }
    }

    /// 단계가 끝나고도 갱신이 오지 않으면 시스템이 "오래된 정보"로 표시하도록 한다.
    private func staleDate(for state: BreathActivityAttributes.ContentState) -> Date {
        state.phaseEnd.addingTimeInterval(1)
    }
}
