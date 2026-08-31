import SwiftUI

/// 호흡 사이클의 한 단계(들숨/멈춤/날숨)를 나타낸다.
///
/// 앱 타깃과 위젯 익스텐션 타깃이 함께 사용하므로 별도 파일로 분리했다.
/// 라이브 액티비티의 `ContentState`에 실려 프로세스 간 인코딩/디코딩되므로
/// `String` 원시값을 두어 인코딩 결과가 케이스 순서에 흔들리지 않도록 했다.
enum BreathPhase: String, Codable, Hashable, CaseIterable {
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

    /// Dynamic Island와 잠금 화면에서 단계를 나타내는 SF Symbol 이름.
    var systemImageName: String {
        switch self {
        case .inhale: return "arrow.down.circle.fill"
        case .hold: return "pause.circle.fill"
        case .exhale: return "arrow.up.circle.fill"
        }
    }

    /// 단계별 강조 색상. 앱 본체와 위젯이 같은 색을 쓰도록 한곳에서 관리한다.
    var tintColor: Color {
        switch self {
        case .inhale: return .blue
        case .hold: return .purple
        case .exhale: return .green
        }
    }
}
