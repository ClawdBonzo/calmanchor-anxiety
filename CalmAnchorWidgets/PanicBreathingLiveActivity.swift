import ActivityKit
import WidgetKit
import SwiftUI

/// Lock-screen banner + Dynamic Island UI for the Panic SOS breathing session.
struct PanicBreathingLiveActivity: Widget {
    private let teal = Color(red: 0, green: 0.788, blue: 0.718)

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PanicBreathingAttributes.self) { context in
            // Lock screen / banner
            HStack(spacing: 14) {
                Image(systemName: "wind")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(teal)
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.phase.instruction)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Text("Breath \(context.state.cycle) of \(context.attributes.totalCycles)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                ProgressView(timerInterval: Date()...context.state.phaseEndsAt, countsDown: true) {
                    EmptyView()
                } currentValueLabel: { EmptyView() }
                    .progressViewStyle(.circular)
                    .tint(teal)
                    .frame(width: 36, height: 36)
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.6))
            .activitySystemActionForegroundColor(teal)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "wind").foregroundStyle(teal)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.phase.instruction)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Breath \(context.state.cycle) of \(context.attributes.totalCycles)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "wind").foregroundStyle(teal)
            } compactTrailing: {
                Text(timerInterval: Date()...context.state.phaseEndsAt, countsDown: true)
                    .frame(width: 38)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            } minimal: {
                Image(systemName: "wind").foregroundStyle(teal)
            }
        }
    }
}
