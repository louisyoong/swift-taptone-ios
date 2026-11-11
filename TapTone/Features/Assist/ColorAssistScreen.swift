import SwiftUI
import UIKit

struct ColorAssistScreen: View {
    private enum PickerSource: Identifiable {
        case camera, gallery
        var id: Int { self == .camera ? 0 : 1 }
    }

    @Environment(\.strings) private var strings
    @Environment(\.palette) private var palette

    @State private var pickerSource: PickerSource?
    @State private var selectedImage: UIImage?
    @State private var activeFilter: AssistFilter?
    @State private var filteredPreviews: [AssistFilter: UIImage] = [:]
    @State private var thumbnails: [String: UIImage] = [:]
    @State private var showingOriginal = false

    private static let thumbnailSide: CGFloat = 192
    nonisolated private static let resetKey = "reset"

    var body: some View {
        GeometryReader { proxy in
            if AdaptiveLayout.isWideLandscape(proxy.size) {
                wideLayout(width: proxy.size.width)
            } else {
                stackedLayout
            }
        }
        .sensoryFeedback(.selection, trigger: activeFilter)
        .task(id: selectedImage.map { ObjectIdentifier($0) }) { await rebuildThumbnails() }
        .onChange(of: activeFilter) { _, filter in renderPreview(for: filter) }
        .fullScreenCover(item: $pickerSource) { source in
            Group {
                switch source {
                case .camera:
                    CameraCaptureView { image in handlePicked(image) }
                        .ignoresSafeArea()
                case .gallery:
                    PhotoLibraryPicker { image in handlePicked(image) }
                        .ignoresSafeArea()
                }
            }
        }
    }

    /// Phones, iPad portrait and unfolded portrait: everything in one column.
    private var stackedLayout: some View {
        VStack(spacing: 0) {
            tagline
            Spacer().frame(height: 12)
            preview
            Spacer().frame(height: 14)
            actionButtons
            Spacer().frame(height: 18)
            filtersHeader
            Spacer().frame(height: 10)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) { filterTiles }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 4)
            }
            .scrollClipDisabled()
            .frame(height: 124)
        }
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 8, trailing: 16))
        .readableWidth(720)
    }

    /// iPad landscape and wide windows: photo on the left, controls on the right.
    private func wideLayout(width: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 28) {
            preview
            VStack(alignment: .leading, spacing: 0) {
                tagline
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                Spacer().frame(height: 16)
                actionButtons
                Spacer().frame(height: 22)
                filtersHeader
                Spacer().frame(height: 12)
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 96), spacing: 12, alignment: .top)],
                        spacing: 14
                    ) { filterTiles }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            // Narrower control column on short landscape screens (folded Duo, iPhone sideways).
            .frame(width: min(340, max(230, width * 0.42)))
        }
        .padding(EdgeInsets(top: 16, leading: 24, bottom: 12, trailing: 24))
        .frame(maxWidth: 1100)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var tagline: some View {
        Text(strings.t("tagline"))
            .font(AppFont.bodyMedium.weight(.medium))
            .lineSpacing(AppFont.bodyLineSpacing)
            .foregroundStyle(palette.onSurfaceVariant)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
    }

    private var preview: some View {
        PhotoPreview(
            image: previewImage,
            label: showingOriginal || activeFilter == nil ? strings.t("original") : activeFilter!.title,
            isFiltered: activeFilter != nil && !showingOriginal,
            canCompare: selectedImage != nil && activeFilter != nil,
            compareLabel: strings.t("original"),
            emptyTitle: strings.t("uploadPhoto"),
            showingOriginal: $showingOriginal,
            onTapEmpty: { pickerSource = .gallery }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Side by side when both labels fit; stacked in narrow columns
    /// (folded iPhone Duo, iPhone held sideways) so they never truncate.
    private var actionButtons: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                takePhotoButton
                uploadPhotoButton
            }
            VStack(spacing: 10) {
                takePhotoButton
                uploadPhotoButton
            }
        }
    }

    private var takePhotoButton: some View {
        Button {
            // image_picker fails without a camera (e.g. Simulator); do nothing there.
            if UIImagePickerController.isSourceTypeAvailable(.camera) { pickerSource = .camera }
        } label: {
            IconLabel(systemImage: "camera.fill", title: strings.t("takePhoto"))
                .fixedSize()
        }
        .buttonStyle(FilledButtonStyle(cornerRadius: 18))
    }

    private var uploadPhotoButton: some View {
        Button { pickerSource = .gallery } label: {
            IconLabel(systemImage: "photo.on.rectangle", title: strings.t("uploadPhoto"))
                .fixedSize()
        }
        .buttonStyle(TonalButtonStyle(cornerRadius: 18))
    }

    private var filtersHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "camera.filters")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(palette.primary)
            Text(strings.t("assistFilters"))
                .font(AppFont.titleMedium)
                .foregroundStyle(palette.onSurface)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var filterTiles: some View {
        FilterTile(
            title: strings.t("reset"),
            image: thumbnails[Self.resetKey],
            isSelected: activeFilter == nil,
            badgeSystemImage: "arrow.counterclockwise",
            onTap: { select(nil) }
        )
        ForEach(AssistFilter.allCases) { filter in
            FilterTile(
                title: filter.title,
                image: thumbnails[filter.title],
                isSelected: activeFilter == filter,
                badgeSystemImage: "checkmark",
                onTap: { select(AssistFilter.byTitle(filter.title)) }
            )
        }
    }

    private var previewImage: UIImage? {
        guard let selectedImage else { return nil }
        guard let activeFilter, !showingOriginal else { return selectedImage }
        return filteredPreviews[activeFilter] ?? selectedImage
    }

    private func select(_ filter: AssistFilter?) {
        withAnimation(.easeInOut(duration: 0.2)) { activeFilter = filter }
    }

    private func handlePicked(_ image: UIImage?) {
        pickerSource = nil
        guard let image else { return }
        selectedImage = image.normalized(maxWidth: 2400)
        filteredPreviews = [:]
        activeFilter = nil
    }

    private func renderPreview(for filter: AssistFilter?) {
        guard let filter, let source = selectedImage, filteredPreviews[filter] == nil else { return }
        let matrix = filter.matrix
        Task.detached(priority: .userInitiated) {
            let output = ColorMatrixRenderer.shared.uiImage(matrix, from: source)
            await MainActor.run {
                if let output, selectedImage === source { filteredPreviews[filter] = output }
            }
        }
    }

    private func rebuildThumbnails() async {
        let base = selectedImage ?? UIImage(named: "DefaultFilterPreview")
        guard let base else { return }
        let side = Self.thumbnailSide
        let result = await Task.detached(priority: .userInitiated) { () -> [String: UIImage] in
            let thumb = base.squareThumbnail(side: side)
            var output: [String: UIImage] = [Self.resetKey: thumb]
            for filter in AssistFilter.allCases {
                output[filter.title] = ColorMatrixRenderer.shared.uiImage(filter.matrix, from: thumb) ?? thumb
            }
            return output
        }.value
        thumbnails = result
    }
}

/// Soft primary-tinted button for the secondary action next to a filled one.
private struct TonalButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 14

    func makeBody(configuration: Configuration) -> some View {
        TonalBody(configuration: configuration, cornerRadius: cornerRadius)
    }

    private struct TonalBody: View {
        let configuration: ButtonStyleConfiguration
        let cornerRadius: CGFloat
        @Environment(\.palette) private var palette

        var body: some View {
            let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            configuration.label
                .font(AppFont.labelLarge)
                .foregroundStyle(palette.onPrimaryContainer)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(shape.fill(palette.primaryContainer.opacity(palette.isDark ? 0.7 : 0.8)))
                .overlay(shape.fill(palette.primary.opacity(configuration.isPressed ? 0.12 : 0)))
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
                .contentShape(shape)
        }
    }
}

private struct PhotoPreview: View {
    let image: UIImage?
    let label: String
    let isFiltered: Bool
    let canCompare: Bool
    let compareLabel: String
    let emptyTitle: String
    @Binding var showingOriginal: Bool
    let onTapEmpty: () -> Void
    @Environment(\.palette) private var palette

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .transition(.opacity)
                        .id(ObjectIdentifier(image))
                } else {
                    emptyState
                }
            }
            .clipShape(shape)
            .overlay(shape.strokeBorder(palette.cardBorder.opacity(image == nil ? 0 : 1), lineWidth: 1))
            .overlay(alignment: .topLeading) {
                if image != nil {
                    PreviewLabel(text: label, systemImage: isFiltered ? "camera.filters" : "photo")
                        .padding(14)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if canCompare { compareButton.padding(14) }
            }
            .shadow(color: .black.opacity(image == nil || palette.isDark ? 0 : 0.12), radius: 18, y: 10)
            .animation(.easeInOut(duration: 0.2), value: image.map { ObjectIdentifier($0) })
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        Button(action: onTapEmpty) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [palette.primaryContainer.opacity(palette.isDark ? 0.25 : 0.45), palette.card],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(palette.primary.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [7, 6]))
                VStack(spacing: 14) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(palette.primary)
                        .frame(width: 84, height: 84)
                        .background(Circle().fill(palette.card))
                        .shadow(color: palette.primary.opacity(0.15), radius: 12, y: 6)
                    Text(emptyTitle)
                        .font(AppFont.titleSmall.weight(.bold))
                        .foregroundStyle(palette.primary)
                }
            }
        }
        .buttonStyle(PressableStyle())
    }

    /// Press and hold to see the unfiltered photo.
    private var compareButton: some View {
        Image(systemName: showingOriginal ? "eye.fill" : "eye")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 46, height: 46)
            .background(Circle().fill(Color.black.opacity(showingOriginal ? 0.55 : 0.35)))
            .glassEffect(.clear.interactive(), in: Circle())
            .environment(\.colorScheme, .dark)
            .scaleEffect(showingOriginal ? 1.1 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: showingOriginal)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: 60, perform: {}, onPressingChanged: { pressing in
                showingOriginal = pressing
            })
            .accessibilityLabel(compareLabel)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { showingOriginal.toggle() }
    }
}

private struct FilterTile: View {
    let title: String
    let image: UIImage?
    let isSelected: Bool
    let badgeSystemImage: String
    let onTap: () -> Void
    @Environment(\.palette) private var palette

    var body: some View {
        let side: CGFloat = 84
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        palette.surfaceContainerHigh
                    }
                }
                .frame(width: side, height: side)
                .clipShape(shape)
                .padding(3)
                .overlay(
                    RoundedRectangle(cornerRadius: 25, style: .continuous)
                        .strokeBorder(isSelected ? palette.primary : palette.cardBorder, lineWidth: isSelected ? 2.5 : 1)
                )
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Image(systemName: badgeSystemImage)
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(palette.onPrimary)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(palette.primary))
                            .overlay(Circle().strokeBorder(palette.scaffold, lineWidth: 2))
                            .offset(x: 6, y: -6)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .scaleEffect(isSelected ? 1 : 0.96)
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isSelected ? palette.primary : palette.onSurfaceVariant)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: side + 6)
            .contentShape(Rectangle())
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
