import Foundation

#if os(watchOS)
import WatchKit
#elseif os(iOS)
import UIKit
#endif

/// 단계 전환과 세션 완료를 촉각으로 알린다.
///
/// 화면을 보지 않고도 호흡을 따라갈 수 있게 하는 것이 목적이므로,
/// 세 단계가 **서로 확실히 구분되는** 감각을 갖도록 골랐다.
///
/// - watchOS: `WKHapticType`에 방향성 햅틱이 있어 들숨은 올라가는 느낌(`.directionUp`),
///   날숨은 내려가는 느낌(`.directionDown`)으로 그대로 대응된다.
/// - iOS: 방향성 햅틱이 없어 세기 차이(`light` → `rigid` → `heavy`)로 대신한다.
enum BreathHaptics {

    /// 단계가 시작될 때 그 단계에 해당하는 햅틱을 재생한다.
    static func play(for phase: BreathPhase) {
        #if os(watchOS)
        WKInterfaceDevice.current().play(hapticType(for: phase))
        #elseif os(iOS)
        let generator = Generators.shared.impact(for: phase)
        generator.impactOccurred()
        // 다음 단계 전환까지 몇 초 비므로, 재생 직후 다시 준비시켜 지연을 줄인다.
        generator.prepare()
        #endif
    }

    /// 세션을 끝까지 마쳤을 때의 성공 햅틱. 사용자가 중지한 경우에는 재생하지 않는다.
    static func playSessionCompleted() {
        #if os(watchOS)
        WKInterfaceDevice.current().play(.success)
        #elseif os(iOS)
        Generators.shared.notification.notificationOccurred(.success)
        #endif
    }

    /// 첫 단계 전환이 밋밋하게 느껴지지 않도록 세션 시작 직전에 햅틱 엔진을 깨워둔다.
    static func prepare() {
        #if os(iOS)
        Generators.shared.prepareAll()
        #endif
    }
}

#if os(watchOS)
private extension BreathHaptics {
    static func hapticType(for phase: BreathPhase) -> WKHapticType {
        switch phase {
        case .inhale: return .directionUp
        case .hold: return .click
        case .exhale: return .directionDown
        }
    }
}
#endif

#if os(iOS)
/// `UIFeedbackGenerator`는 미리 만들어 두고 `prepare()`를 호출해야 지연이 짧다.
/// 매번 새로 만들면 첫 진동이 늦게 오거나 씹힌다.
private final class Generators {
    static let shared = Generators()

    let light = UIImpactFeedbackGenerator(style: .light)
    let rigid = UIImpactFeedbackGenerator(style: .rigid)
    let heavy = UIImpactFeedbackGenerator(style: .heavy)
    let notification = UINotificationFeedbackGenerator()

    func impact(for phase: BreathPhase) -> UIImpactFeedbackGenerator {
        switch phase {
        case .inhale: return light
        case .hold: return rigid
        case .exhale: return heavy
        }
    }

    func prepareAll() {
        light.prepare()
        rigid.prepare()
        heavy.prepare()
        notification.prepare()
    }
}
#endif
