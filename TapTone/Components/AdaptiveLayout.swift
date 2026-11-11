import SwiftUI

extension View {
    /// Caps content at a comfortable width and centers it, so lists, cards and
    /// buttons don't stretch edge to edge on iPad or an unfolded iPhone.
    /// No effect on phone widths.
    func readableWidth(_ maxWidth: CGFloat = 680) -> some View {
        frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }
}

enum AdaptiveLayout {
    /// True for wide, landscape-ish containers (iPad landscape, an unfolded
    /// iPhone held sideways, large Split View panes) where content reads
    /// better side by side than stacked.
    static func isWideLandscape(_ size: CGSize) -> Bool {
        size.width >= 480 && size.width > size.height * 1.05
    }

    /// True for containers wide enough to use larger artwork (iPad,
    /// an unfolded iPhone).
    static func isRoomy(_ size: CGSize) -> Bool {
        size.width >= 600
    }
}
