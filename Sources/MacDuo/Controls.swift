import SwiftUI
import MetalKit
import FoldCore

struct MetalPreview: NSViewRepresentable {
    @ObservedObject var model: AppModel

    func makeNSView(context: Context) -> MTKView {
        let view = MTKView()
        guard let device = model.device else { return view }
        do {
            let renderer = try FoldRenderer(device: device)
            renderer.fallback = try renderer.makePreviewTexture()
            renderer.parameters = { [weak model] in model?.uniforms(preview: true) ?? FoldUniforms() }
            renderer.animatedState = { [weak model] in model?.animatedState(preview: true) }
            renderer.blendsWithDesktop = true
            renderer.pausesWhenSettled = true
            renderer.onFailure = { [weak model] message in model?.status = message }
            renderer.configure(view)
            context.coordinator.renderer = renderer
            model.previewRenderer = renderer
            model.previewView = view
        } catch { model.status = error.localizedDescription }
        return view
    }

    func updateNSView(_ view: MTKView, context: Context) {
        view.preferredFramesPerSecond = min(60, model.fps)
        context.coordinator.renderer?.wake(view)
    }

    static func dismantleNSView(_ view: MTKView, coordinator: Coordinator) {
        view.isPaused = true
        view.delegate = nil
    }

    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator { var renderer: FoldRenderer? }
}

struct Controls: View {
    @ObservedObject var model: AppModel

    var body: some View {
        settings
            .background(Color(nsColor: .windowBackgroundColor))
            .tint(.accentColor)
    }

    private var settings: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                preview
                primaryControls
                footer
            }
            .padding(24)
            .frame(maxWidth: 620)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(nsImage: AppBrand.mark)
                .resizable().scaledToFit().frame(width: 44, height: 44)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("AthiDuo").font(.system(size: 28, weight: .semibold, design: .rounded))
                Text("Your desktop, gently following the hinge.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            statusPill
        }
    }

    private var statusPill: some View {
        Label {
            Text(model.enabled ? "Active" : "Paused").font(.caption.weight(.semibold))
        } icon: {
            Circle().fill(model.enabled ? Color.green : Color.secondary).frame(width: 7, height: 7)
        }
        .foregroundStyle(model.enabled ? Color.primary : Color.secondary)
        .padding(.horizontal, 11).padding(.vertical, 7)
        .background(.ultraThinMaterial, in: Capsule())
        .accessibilityLabel(model.enabled ? "AthiDuo is active" : "AthiDuo is paused")
    }

    private var preview: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .bottomLeading) {
                MetalPreview(model: model)
                    .frame(height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text("DUO").font(.caption.weight(.bold)).tracking(1.2)
                    Text("Move the slider to feel the fold").font(.caption).foregroundStyle(.secondary)
                }
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(14)
            }
        }
        .padding(12)
        .glassCard()
    }

    private var primaryControls: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(model.enabled ? "Following your lid" : "Ready when you are").font(.headline)
                    Text(model.status).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                }
                Spacer(minLength: 16)
                Button(model.enabled ? "Pause" : "Activate") {
                    model.enabled ? model.pause() : model.enable()
                }
                .buttonStyle(.borderedProminent).controlSize(.large).disabled(model.checkingPermission)
            }
            Divider()
            LabeledContent("Intensity") {
                HStack(spacing: 10) {
                    Slider(value: $model.perspective, in: 0.35...1).frame(width: 190)
                    Text(Intensity.nearest(to: model.perspective).label)
                        .font(.caption.weight(.medium)).foregroundStyle(.secondary).frame(width: 58, alignment: .trailing)
                }
            }
            Toggle("Hold the image while the lid is still", isOn: Binding(
                get: { !model.clearWhenStill }, set: { model.clearWhenStill = !$0 }
            ))
            Toggle("Open at login", isOn: Binding(
                get: { model.launchAtLogin }, set: { model.setLaunchAtLogin($0) }
            ))
        }
        .padding(18)
        .glassCard()
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill").imageScale(.small)
            Text("Screen snapshots stay in memory on this Mac.")
        }
        .font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .center)
    }
}

private extension View {
    func glassCard() -> some View {
        background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            }
    }
}
