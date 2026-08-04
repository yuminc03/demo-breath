import ActivityKit
import SwiftUI
import WidgetKit

/// 호흡 세션 라이브 액티비티.
///
/// 잠금 화면과 Dynamic Island의 세 가지 표현(compact / minimal / expanded)을 한곳에서 선언한다.
struct BreathLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BreathActivityAttributes.self) { context in
            BreathLockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.4))
                .activitySystemActionForegroundColor(context.state.phase.tintColor)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(
                        context.state.phase.displayName,
                        systemImage: context.state.phase.systemImageName
                    )
                    .font(.headline)
                    .foregroundStyle(context.state.phase.tintColor)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: context.state.phaseRange, countsDown: true)
                        .font(.title2.bold())
                        .monospacedDigit()
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 64)
                        .foregroundStyle(context.state.phase.tintColor)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    BreathGauge(state: context.state)
                }
            } compactLeading: {
                Image(systemName: context.state.phase.systemImageName)
                    .foregroundStyle(context.state.phase.tintColor)
            } compactTrailing: {
                Text(context.state.phase.displayName)
                    .font(.caption.bold())
                    .foregroundStyle(context.state.phase.tintColor)
            } minimal: {
                Image(systemName: context.state.phase.systemImageName)
                    .foregroundStyle(context.state.phase.tintColor)
            }
            .keylineTint(context.state.phase.tintColor)
        }
    }
}

/// 잠금 화면 표현: 단계 문구 + 게이지.
struct BreathLockScreenView: View {
    let context: ActivityViewContext<BreathActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(
                    context.state.phase.displayName,
                    systemImage: context.state.phase.systemImageName
                )
                .font(.title3.bold())
                .foregroundStyle(context.state.phase.tintColor)

                Spacer()

                Text(context.attributes.sessionName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            BreathGauge(state: context.state)
        }
        .padding()
    }
}

/// 단계의 남은 시간을 시스템이 스스로 채워 그리는 게이지.
///
/// 진행률을 숫자로 넘기지 않고 시각 구간을 넘기기 때문에,
/// 앱이 서스펜드된 뒤에도 현재 단계가 끝날 때까지는 게이지가 계속 움직인다.
struct BreathGauge: View {
    let state: BreathActivityAttributes.ContentState

    var body: some View {
        ProgressView(timerInterval: state.phaseRange, countsDown: true)
            .progressViewStyle(.linear)
            .tint(state.phase.tintColor)
            .labelsHidden()
    }
}
