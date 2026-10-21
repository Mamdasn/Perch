import Foundation
import AppKit
import SwiftUI

enum MeetingNotes {
    // Convert common calendar HTML without loading remote resources or executing markup.
    // Keep the original wording and expose link destinations that HTML labels hide.
    static func cleaned(_ source: String?) -> String? {
        guard var text = source else { return nil }
        let options: NSRegularExpression.Options = [.caseInsensitive, .dotMatchesLineSeparators]
        func replacing(_ pattern: String, in value: String, with replacement: String) -> String {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return value }
            return regex.stringByReplacingMatches(in: value, range: NSRange(value.startIndex..., in: value), withTemplate: replacement)
        }
        let tags = "p|div|br|a|span|ul|ol|li|table|tr|td|th|h[1-6]|b|strong|i|em|u|html|body|head|style|script|blockquote|pre|hr"
        if text.range(of: "</?(?:\(tags))(?:\\s[^>]*|\\s*/?)>", options: [.regularExpression, .caseInsensitive]) != nil {
            text = replacing("<(script|style|head)\\b[^>]*>.*?</\\1\\s*>", in: text, with: "")
            if let anchors = try? NSRegularExpression(pattern: "<a\\b[^>]*href\\s*=\\s*[\"']([^\"']*)[\"'][^>]*>(.*?)</a\\s*>", options: options) {
                let original = text as NSString
                for match in anchors.matches(in: text, range: NSRange(location: 0, length: original.length)).reversed() {
                    let target = decoded(original.substring(with: match.range(at: 1)))
                    let label = decoded(replacing("</?(?:\(tags))\\b[^>]*>", in: original.substring(with: match.range(at: 2)), with: ""))
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    let replacement = label.isEmpty || label == target ? target : "\(label) (\(target))"
                    if let range = Range(match.range, in: text) { text.replaceSubrange(range, with: replacement) }
                }
            }
            text = replacing("<br\\s*/?>|<hr\\b[^>]*>|</(?:p|div|li|tr|h[1-6]|blockquote|pre)\\s*>", in: text, with: "\n")
            text = replacing("<li\\b[^>]*>", in: text, with: "\n• ")
            text = replacing("</(?:td|th)\\s*>", in: text, with: "  ")
            text = replacing("</?(?:\(tags))\\b[^>]*>", in: text, with: "")
        }
        text = decoded(text).replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\u{00a0}", with: " ")
        var lines: [String] = []
        for line in text.components(separatedBy: "\n") {
            let trimmed = line.replacingOccurrences(of: "[ \\t]+$", with: "", options: .regularExpression)
            if trimmed.isEmpty && (lines.isEmpty || lines.last == "") { continue }
            lines.append(trimmed)
        }
        return Meeting.nonempty(lines.joined(separator: "\n"))
    }

    private static func decoded(_ text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: "&(#x[0-9a-fA-F]+|#[0-9]+|amp|lt|gt|quot|apos|nbsp);") else { return text }
        let entities = ["amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'", "nbsp": " "]
        var result = text
        let original = text as NSString
        for match in regex.matches(in: text, range: NSRange(location: 0, length: original.length)).reversed() {
            let name = original.substring(with: match.range(at: 1))
            var replacement = entities[name]
            if name.hasPrefix("#") {
                let hex = name.hasPrefix("#x")
                if let number = UInt32(name.dropFirst(hex ? 2 : 1), radix: hex ? 16 : 10),
                   let scalar = UnicodeScalar(number), number >= 32 || [9, 10, 13].contains(number) {
                    replacement = String(scalar)
                }
            }
            if let replacement, let range = Range(match.range, in: result) {
                result.replaceSubrange(range, with: replacement)
            }
        }
        return result
    }
}

// A native scroll view lets the disclosure header forward wheel events to the
// same text viewport, including trackpad momentum and scrolling at either edge.
struct NotesTextView: NSViewRepresentable {
    var text: String

    func makeNSView(context: Context) -> NotesScrollView {
        let scroll = NotesScrollView()
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.scrollerStyle = .overlay
        let document = NSTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 104))
        document.isEditable = false
        document.isSelectable = true
        document.drawsBackground = false
        document.font = .systemFont(ofSize: 12)
        document.textColor = .labelColor
        document.textContainerInset = NSSize(width: 0, height: 6)
        document.textContainer?.lineFragmentPadding = 0
        document.textContainer?.widthTracksTextView = true
        document.textContainer?.containerSize = NSSize(width: 300, height: CGFloat.greatestFiniteMagnitude)
        document.isVerticallyResizable = true
        document.isHorizontallyResizable = false
        document.autoresizingMask = [.width]
        document.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        document.setAccessibilityLabel("Meeting notes")
        scroll.documentView = document
        return scroll
    }

    func updateNSView(_ view: NotesScrollView, context: Context) {
        guard let document = view.documentView as? NSTextView, document.string != text else { return }
        document.string = text
        document.sizeToFit()
        view.contentView.scroll(to: .zero)
        view.reflectScrolledClipView(view.contentView)
    }
}

final class NotesScrollView: NSScrollView {
    static func find(in view: NSView) -> NotesScrollView? {
        if let notes = view as? NotesScrollView { return notes }
        for child in view.subviews {
            if let notes = find(in: child) { return notes }
        }
        return nil
    }
}

struct NotesDisclosureStyle: DisclosureGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { configuration.isExpanded.toggle() } label: {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .rotationEffect(.degrees(configuration.isExpanded ? 90 : 0))
                        .accessibilityHidden(true)
                    configuration.label
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, minHeight: 22, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(configuration.isExpanded ? "Expanded" : "Collapsed")
            .help(configuration.isExpanded ? "Hide notes" : "Show notes")
            if configuration.isExpanded { configuration.content }
        }
    }
}
