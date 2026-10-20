import AppKit
import SwiftUI

// Standalone renderer only; timing is covered by the app's self-tests.
struct Meeting {
    let start: Date
    let end: Date
    func isCurrent(at now: Date) -> Bool { start <= now && now < end }
}

@main
struct PreviewReminder {
    @MainActor static func main() throws {
        let stages: [(String, Double?)] = [
            ("5 min before", 0), ("3 min before", 0.4),
            ("1 min before", 0.8), ("Just before", 0.997), ("Meeting starts", nil)
        ]
        let renderer = ImageRenderer(content:
            VStack(alignment: .leading, spacing: 20) {
                Text("Notchpop · Meeting reminder").font(.system(size: 24, weight: .semibold))
                Text("Blue → green, then disappears when the meeting starts.")
                    .foregroundStyle(.secondary)
                HStack(alignment: .top, spacing: 14) {
                    ForEach(stages.indices, id: \.self) { index in
                        VStack(spacing: 12) {
                            Text(stages[index].0).font(.system(size: 13, weight: .medium))
                            ZStack(alignment: .top) {
                                LinearGradient(colors: [Color(white: 0.17), Color(white: 0.09)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                                RoundedRectangle(cornerRadius: 10).fill(.black)
                                    .frame(width: 150, height: 50).offset(y: -20)
                                if let progress = stages[index].1 {
                                    MeetingReminderEdge(progress: progress, hasNotch: true, width: 150, height: 30)
                                }
                            }
                            .frame(width: 200, height: 100).clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            ZStack(alignment: .top) {
                                Color(white: 0.13)
                                if let progress = stages[index].1 {
                                    MeetingReminderEdge(progress: progress, hasNotch: false, width: 150, height: 30)
                                }
                            }
                            .frame(width: 200, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                Text("Top: display with a notch   ·   Bottom: display without a notch")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            }
            .padding(28).background(Color(white: 0.055)).environment(\.colorScheme, .dark)
        )
        renderer.scale = 2
        guard let cgImage = renderer.cgImage else { fatalError("Could not render reminder preview") }
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
    }
}
