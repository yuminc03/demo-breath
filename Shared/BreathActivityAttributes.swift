import ActivityKit
import Foundation

/// 호흡 세션 라이브 액티비티가 주고받는 데이터 계약.
///
/// 앱 타깃과 위젯 익스텐션 타깃 양쪽에 포함되어야 한다.
struct BreathActivityAttributes: ActivityAttributes {

    /// 세션이 끝날 때까지 변하지 않는 고정 값.
    let sessionName: String

    /// 단계가 바뀔 때마다 갱신되는 값.
    ///
    /// 남은 초를 `Int`로 박아두지 않고 단계의 시작/종료 **시각**을 담는 이유는,
    /// 화면이 잠겨 앱이 서스펜드되면 `Activity.update(_:)`를 호출할 주체가 사라지기 때문이다.
    /// 시각 구간을 넘겨두면 `Text(timerInterval:)`·`ProgressView(timerInterval:)`가
    /// 앱 없이도 시스템 쪽에서 초를 세고 게이지를 채운다.
    struct ContentState: Codable, Hashable {
        var phase: BreathPhase
        var phaseStart: Date
        var phaseEnd: Date

        /// 타이머 뷰에 그대로 넘기는 단계 구간.
        /// 역전된 구간은 `ClosedRange` 생성 시 크래시를 내므로 방어한다.
        var phaseRange: ClosedRange<Date> {
            phaseStart...max(phaseStart, phaseEnd)
        }

        /// 타이머 뷰를 쓸 수 없는 자리(접근성 레이블 등)를 위한 정수 남은 초.
        var remainingSeconds: Int {
            max(0, Int(phaseEnd.timeIntervalSinceNow.rounded(.up)))
        }
    }
}
