import Foundation
import FoldCore

enum CoreCheck {
    private enum Failure: LocalizedError {
        case message(String)
        var errorDescription: String? {
            switch self { case let .message(value): return value }
        }
    }

    static func run() throws {
        guard FoldMath.progress(angle: 105, referenceAngle: 105) == 0,
              FoldMath.progress(angle: 5, referenceAngle: 105) == 1 else {
            throw Failure.message("Reference-angle mapping failed.")
        }
        var stillness = LidStillness()
        guard !stillness.observe(angle: 105, at: 0, delay: 1),
              !stillness.observe(angle: 105, at: 0.5, delay: 1),
              stillness.observe(angle: 105, at: 1, delay: 1),
              !stillness.observe(angle: 102, at: 1.1, delay: 1) else {
            throw Failure.message("Stillness hysteresis failed.")
        }
        var reference = LidMotionReference()
        reference.observe(angle: 98, isStill: true, clearWhenStill: true)
        guard reference.reference(referenceAngle: 105) == 98 else {
            throw Failure.message("Reference rebasing failed.")
        }
        print("Core checks passed: Duo mapping, stillness, and reference rebasing.")
    }
}
