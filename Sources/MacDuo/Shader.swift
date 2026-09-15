import Foundation

enum FoldShader {
    /// One original, bottom-hinged Duo transform. The uniform layout mirrors
    /// `FoldUniforms` in Renderer.swift.
    static let source = #"""
    #include <metal_stdlib>
    using namespace metal;

    struct Uniforms {
        float progress;
        float perspective;
        float blur;
        float shadow;
        float2 size;
        float fadeOnly;
        float defocus;
        float coverage;
        float tilt;
        float referenceAngle;
    };
    struct Varying { float4 position [[position]]; float2 uv; };

    vertex Varying foldVertex(uint id [[vertex_id]]) {
        const float2 positions[3] = { float2(-1,-1), float2(3,-1), float2(-1,3) };
        Varying output;
        output.position = float4(positions[id], 0, 1);
        output.uv = float2((positions[id].x + 1) * 0.5f, 1 - (positions[id].y + 1) * 0.5f);
        return output;
    }

    kernel void foldDownsample(texture2d<float, access::sample> source [[texture(0)]],
                               texture2d<float, access::write> target [[texture(1)]],
                               uint2 pixel [[thread_position_in_grid]]) {
        if (pixel.x >= target.get_width() || pixel.y >= target.get_height()) return;
        constexpr sampler samplerState(coord::normalized, address::clamp_to_edge, filter::linear);
        float2 uv = (float2(pixel) + 0.5f) / float2(target.get_width(), target.get_height());
        float2 texel = 1.0f / float2(source.get_width(), source.get_height());
        const float offsets[3] = { -1.2f, 0, 1.2f };
        const float weights[3] = { 0.3125f, 0.375f, 0.3125f };
        float4 color = 0;
        for (uint y = 0; y < 3; y++) for (uint x = 0; x < 3; x++)
            color += source.sample(samplerState, uv + float2(offsets[x], offsets[y]) * texel) * weights[x] * weights[y];
        target.write(color, pixel);
    }

    static float3 sampleDesktop(texture2d<float> desktop, texture2d<float> pyramid,
                                sampler samplerState, float2 uv, float sigmaUV) {
        if (!(sigmaUV > 0.0f)) return desktop.sample(samplerState, uv).rgb;
        float sigma = sigmaUV * float(desktop.get_height());
        float lod = 0.5f * log2(1.0f + sigma * sigma * 2.4f);
        lod = min(lod, float(pyramid.get_num_mip_levels() - 1));
        return pyramid.sample(samplerState, uv, level(lod)).rgb;
    }

    fragment float4 foldFragment(Varying input [[stage_in]],
        texture2d<float> desktop [[texture(0)]], texture2d<float> pyramid [[texture(1)]],
        constant Uniforms& values [[buffer(0)]]) {
        constexpr sampler samplerState(coord::normalized, address::clamp_to_edge, filter::linear, mip_filter::linear);
        const float progress = clamp(values.progress, 0.0f, 1.0f);
        if (progress < 0.00001f) return float4(desktop.sample(samplerState, input.uv).rgb, 1);
        if (values.fadeOnly > 0.5f) return float4(desktop.sample(samplerState, input.uv).rgb * (1 - progress), 1);
        if (progress >= 1) return float4(0, 0, 0, 1);

        const float height = 1 - input.uv.y;
        const float perspective = clamp(values.perspective, 0.0f, 1.0f);
        const float expansion = 1 + progress * (0.12f + mix(0.30f, 0.66f, perspective) * height);
        const float2 sourceUV = float2(0.5f + (input.uv.x - 0.5f) / expansion, 1 - height / expansion);
        const float focus = values.defocus >= 0 ? values.defocus : pow(progress, 0.7f);
        const float spread = 0.12f + 0.88f * pow(height, 1.15f);
        const float sigmaUV = clamp(values.blur, 0.0f, 1.0f) * 0.052f * focus * spread;
        float3 color = sampleDesktop(desktop, pyramid, samplerState, sourceUV, sigmaUV);

        const float softness = clamp(values.blur, 0.0f, 1.0f);
        const float topWidth = progress * (0.075f + 0.15f * softness) + 1.5f * sigmaUV;
        const float sideWidth = (progress * (0.055f + 0.12f * softness) + 1.5f * sigmaUV) * values.size.y / values.size.x;
        const float bottomWidth = progress * (0.012f + 0.025f * softness) + 0.5f * sigmaUV;
        const float mask = smoothstep(0.0f, topWidth, input.uv.y)
            * smoothstep(0.0f, bottomWidth, height)
            * smoothstep(0.0f, sideWidth, input.uv.x)
            * smoothstep(0.0f, sideWidth, 1.0f - input.uv.x);
        const float shade = 1 - clamp(values.shadow, 0.0f, 1.0f) * 0.12f * progress * progress * height;
        const float disappear = 1 - smoothstep(0.86f, 1.0f, progress);
        const float3 folded = color * mask * shade * disappear;
        const float3 original = desktop.sample(samplerState, input.uv).rgb;
        return float4(mix(original, folded, clamp(values.coverage, 0.0f, 1.0f)), 1);
    }
    """#
}
