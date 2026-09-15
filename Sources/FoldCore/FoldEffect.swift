import Foundation

/// AthiDuo deliberately ships one effect. Keeping the contract explicit lets the
/// renderer and generated-image checks remain independent of the UI.
public enum FoldEffect: String, CaseIterable, Sendable, Identifiable {
    case duo

    public static let fallback = FoldEffect.duo

    public var id: String { rawValue }
    public var persistedIdentifier: String { rawValue }

    /// Mirrored by `Uniforms.effect` in `FoldShader.source`.
    public var shaderIndex: UInt32 {
        0
    }

    /// An unreadable or unknown saved selection returns to the default effect.
    public static func resolve(persisted: String?) -> FoldEffect {
        guard let persisted, let effect = FoldEffect(rawValue: persisted) else { return fallback }
        return effect
    }

    /// The shader applies the same rule for an index it does not recognize.
    public static func resolve(shaderIndex: UInt32) -> FoldEffect {
        shaderIndex == 0 ? .duo : fallback
    }

    public var title: String {
        "Duo"
    }

    public var symbol: String {
        "macbook"
    }

    public var summary: String {
        "The desktop swells around the hinge as the lid closes."
    }

    public var needsPrefilteredSource: Bool { false }
}
