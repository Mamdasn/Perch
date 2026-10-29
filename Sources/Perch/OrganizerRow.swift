import SwiftUI

struct OrganizerRow: View {
    var name: String?
    var email: String?

    private var displayName: String {
        if let name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return name }
        return email ?? "Organizer unavailable"
    }

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle().fill(.white.opacity(0.10))
                if name != nil || email != nil {
                    Text(displayName.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined().uppercased())
                        .font(.system(size: 8, weight: .semibold))
                } else {
                    Image(systemName: "person.fill").font(.system(size: 10))
                }
            }
            .frame(width: 22, height: 22).clipShape(Circle()).accessibilityHidden(true)
            Text(displayName).font(.system(size: 11)).lineLimit(1).foregroundStyle(.secondary)
        }
        .help("Organizer: \(displayName)")
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Organizer: \(displayName)")
    }
}
