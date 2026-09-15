import AppKit
import MetalKit

/// Deterministic GPU checks for AthiDuo's one Duo shader. These never request
/// Screen Recording and can run on a CI or development machine safely.
@MainActor enum RenderCheck {
    private struct Frame {
        let pixels: [UInt8]
        let width: Int
        let height: Int

        var averageBrightness: Double {
            stride(from: 0, to: pixels.count, by: 4)
                .reduce(0.0) { $0 + Double(pixels[$1]) } / Double(width * height)
        }
    }

    private static func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        guard condition() else { throw AppError.message(message) }
    }

    private static func target(_ device: MTLDevice, width: Int, height: Int) throws -> MTLTexture {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false)
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .shared
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw AppError.message("Render-check output texture unavailable.")
        }
        return texture
    }

    private static func render(_ renderer: FoldRenderer, source: MTLTexture, output: MTLTexture, uniforms: FoldUniforms) throws -> Frame {
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = output
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].storeAction = .store
        guard let command = renderer.queue.makeCommandBuffer() else {
            throw AppError.message("Render-check command buffer unavailable.")
        }
        var values = uniforms
        values.size = SIMD2(Float(output.width), Float(output.height))
        try renderer.encode(command: command, pass: pass, texture: source, uniforms: values)
        command.commit()
        command.waitUntilCompleted()
        guard command.status == .completed else {
            throw AppError.message(command.error?.localizedDescription ?? "Duo render check failed.")
        }
        var pixels = [UInt8](repeating: 0, count: output.width * output.height * 4)
        output.getBytes(&pixels, bytesPerRow: output.width * 4, from: MTLRegionMake2D(0, 0, output.width, output.height), mipmapLevel: 0)
        return Frame(pixels: pixels, width: output.width, height: output.height)
    }

    static func run() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw AppError.message("Metal is unavailable.")
        }
        let renderer = try FoldRenderer(device: device)
        let source = try renderer.makePreviewTexture(width: 720, height: 468)
        let output = try target(device, width: 720, height: 468)

        let open = try render(renderer, source: source, output: output, uniforms: FoldUniforms())
        var middleUniforms = FoldUniforms()
        middleUniforms.progress = 0.5
        middleUniforms.defocus = 0.5
        let middle = try render(renderer, source: source, output: output, uniforms: middleUniforms)
        var closedUniforms = FoldUniforms()
        closedUniforms.progress = 1
        closedUniforms.defocus = 1
        let closed = try render(renderer, source: source, output: output, uniforms: closedUniforms)

        try require(open.averageBrightness > 20, "Open Duo frame is unexpectedly dark.")
        try require(middle.averageBrightness > 1 && middle.averageBrightness < open.averageBrightness, "Duo mid-frame lacks a visible transition.")
        try require(closed.averageBrightness < 1, "Closed Duo frame is not black.")

        let report: [String: Any] = [
            "effect": "duo",
            "size": "720x468",
            "openBrightness": open.averageBrightness,
            "middleBrightness": middle.averageBrightness,
            "closedBrightness": closed.averageBrightness
        ]
        let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
        print(String(decoding: data, as: UTF8.self))
    }
}
