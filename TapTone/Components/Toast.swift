import SwiftUI

/// Lightweight stand-in for a Material SnackBar.
struct ToastModifier: ViewModifier {
    @Binding var message: String?
    @Environment(\.palette) private var palette

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let message {
                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(palette.onInverseSurface)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 4).fill(palette.inverseSurface)
                    )
                    .padding(12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task(id: message) {
                        try? await Task.sleep(for: .seconds(4))
                        withAnimation { self.message = nil }
                    }
            }
        }
        .animation(.easeOut(duration: 0.25), value: message)
    }
}

extension View {
    func toast(_ message: Binding<String?>) -> some View {
        modifier(ToastModifier(message: message))
    }
}
