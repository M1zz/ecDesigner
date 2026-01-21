import SwiftUI
import AppKit

class WindowHelper {
    static func openMilestoneEditor(
        milestone: Binding<Milestone>,
        fontScale: CGFloat,
        onSave: @escaping (Milestone) -> Void,
        onDelete: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        let contentView = MilestoneEditorView(
            milestone: milestone,
            fontScale: fontScale,
            onSave: onSave,
            onDelete: onDelete,
            onCancel: onCancel
        )

        let hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 700),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.center()
        window.title = "Milestone Editor"
        window.contentViewController = hostingController
        window.makeKeyAndOrderFront(nil)

        // Keep window alive
        window.isReleasedWhenClosed = false
    }
}
