import WidgetKit
import SwiftUI
import HealthKit

// MARK: - データ

struct RapperEntry: TimelineEntry {
    let date: Date
    let snap: WidgetSnapshot

    /// 未同期の歩数で、あと何ポイントもらえるか
    var pendingPoints: Int { max(0, (snap.steps - snap.syncedSteps) / 100) }
}

enum StepReader {
    /// 今日の歩数（許可はアプリ側で取っておく。取れなければ nil）
    static func todaySteps() async -> Int? {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }
        let store = HKHealthStore()
        let type = HKQuantityType(.stepCount)
        let start = Calendar.current.startOfDay(for: .now)
        let query = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(
                type: type,
                predicate: HKQuery.predicateForSamples(withStart: start, end: .now)
            ),
            options: .cumulativeSum
        )
        guard let sum = try? await query.result(for: store)?.sumQuantity() else { return nil }
        return Int(sum.doubleValue(for: .count()))
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> RapperEntry {
        RapperEntry(date: .now, snap: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (RapperEntry) -> Void) {
        completion(RapperEntry(date: .now, snap: SharedStore.load() ?? .sample))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RapperEntry>) -> Void) {
        Task {
            var snap = SharedStore.load() ?? .sample
            // 日付が変わっていたら歩数はリセット
            if !Calendar.current.isDateInToday(snap.stepsDate) {
                snap.steps = 0
                snap.syncedSteps = 0
            }
            if let live = await StepReader.todaySteps() {
                snap.steps = max(snap.steps, live)
            }
            let entry = RapperEntry(date: .now, snap: snap)
            let next = Date.now.addingTimeInterval(30 * 60)   // 30分後に更新
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }
}

// MARK: - 見た目

struct RapperWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: RapperEntry

    var body: some View {
        switch family {
        case .systemSmall: small
        default: medium
        }
    }

    private var small: some View {
        VStack(spacing: 4) {
            Text(entry.snap.emoji)
                .font(.system(size: 52))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(entry.snap.name)
                .font(.caption.bold())
                .lineLimit(1)
            Label("\(entry.snap.steps)", systemImage: "figure.walk")
                .font(.caption2)
                .foregroundStyle(.secondary)
            if entry.pendingPoints > 0 {
                Text("+\(entry.pendingPoints)pt もらえる！")
                    .font(.caption2.bold())
                    .foregroundStyle(.orange)
            }
        }
    }

    private var medium: some View {
        HStack(spacing: 16) {
            Text(entry.snap.emoji)
                .font(.system(size: 64))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .frame(width: 110)

            VStack(alignment: .leading, spacing: 6) {
                Text(entry.snap.name).font(.headline).lineLimit(1)
                Text(entry.snap.stageName + (entry.snap.styleName.map { "・\($0)" } ?? ""))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ProgressView(value: min(max(entry.snap.progress, 0), 1))
                    .tint(.orange)
                HStack {
                    Label("\(entry.snap.steps)歩", systemImage: "figure.walk")
                    Spacer()
                    Text("\(entry.snap.points)pt")
                }
                .font(.caption)
                if entry.pendingPoints > 0 {
                    Text("アプリを開くと +\(entry.pendingPoints)pt 🎤")
                        .font(.caption2.bold())
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}

// MARK: - ウィジェット本体

struct RapperWidget: Widget {
    let kind = "RapperWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            RapperWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("ラッパー育成")
        .description("キャラと今日の歩数を表示します")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemMedium) {
    RapperWidget()
} timeline: {
    RapperEntry(date: .now, snap: .sample)
}
