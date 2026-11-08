#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

namespace bubble {

// The wave the liquid's surface and the digit split share. The far edge of the surface rides a
// second, slower copy of it.
float wave(float x, float2 size, float amplitude, float phase) {
    float a = min(size.y * 0.06, amplitude);
    float rx = x / size.x;
    return sin(rx * M_PI_F * 1.72 + phase) * a + sin(rx * M_PI_F * 3.34 + phase * 0.68) * a * 0.24;
}

float2 hash2(float2 p) {
    p = float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453);
}

// Bright threads where drifting cells meet, the way a rippled surface gathers light. They fade in
// and out along their length so they never close into a net.
float threads(float2 uv, float t) {
    uv += 0.32 * float2(sin(uv.y * 1.9 + t * 0.5), sin(uv.x * 1.7 - t * 0.4));
    float2 cell = floor(uv);
    float2 f = fract(uv);
    float nearest = 8.0;
    float second = 8.0;
    for (int j = -1; j <= 1; j++) {
        for (int i = -1; i <= 1; i++) {
            float2 offset = float2(float(i), float(j));
            float2 h = hash2(cell + offset);
            float2 r = offset + 0.5 + 0.38 * sin(t * (0.5 + 0.5 * h.yx) + 6.2831853 * h) - f;
            float d = dot(r, r);
            if (d < nearest) {
                second = nearest;
                nearest = d;
            } else if (d < second) {
                second = d;
            }
        }
    }
    float border = 1.0 - smoothstep(0.0, 0.12, sqrt(second) - sqrt(nearest));
    float presence = smoothstep(0.15, 0.85, 0.5 + 0.5 * sin(uv.x * 0.9 + t * 0.3) * sin(uv.y * 0.7 - t * 0.25));
    return border * border * border * presence;
}

// A cross-section of the inside of the glass at `t`, from 0 to 1 across it, from `count` (a, b)
// pairs sampled evenly and stored from pair `first` on.
float2 crossSection(float t, device const float *sections, int first, int count) {
    float f = clamp(t, 0.0, 1.0) * float(count - 1);
    int i0 = min(int(floor(f)), count - 1);
    int i1 = min(i0 + 1, count - 1);
    float k = f - float(i0);
    float2 a = float2(sections[(first + i0) * 2], sections[(first + i0) * 2 + 1]);
    float2 b = float2(sections[(first + i1) * 2], sections[(first + i1) * 2 + 1]);
    return mix(a, b, k);
}

// The distance to the glass from a point that is `h` from it sideways and `v` from it vertically,
// taking the glass between those two points as straight.
float cornerDistance(float h, float v) {
    return h * v / sqrt(h * h + v * v + 1e-4);
}

float squared(float x) {
    return x * x;
}

} // namespace bubble

// The liquid inside the bubble, applied as a layer effect to the layer that holds the countdown.
// Above the wave line the digits keep their glass treatment; below it they are seen through the
// liquid, magnified a little by the round vessel, bent by the surface, and filtered by the tint.
//
// surface:   water line y, surface center x, surface half width, perspective depth (0 = no surface)
// waveState: amplitude, phase, far-edge phase, time for the caustic threads
// look:      dark (1) or light (0), tint density, fill ratio, caustic strength
// bounds:    the inside of the glass: top, bottom, left, right
// sections:  (left, right) pairs on rows from its top to its bottom, then as many (top, bottom)
//            pairs on columns from its left to its right
[[ stitchable ]] half4 bubbleLiquid(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float4 surface,
    float4 waveState,
    half4 tintColor,
    half4 deepColor,
    half4 glowColor,
    half4 backdropColor,
    float4 look,
    float cue,
    float4 bounds,
    device const float *sections,
    int sectionCount
) {
    float2 q = position;
    float4 dry = float4(layer.sample(q));
    bool dark = look.x > 0.5;
    const float aa = 0.45;

    float frontWave = bubble::wave(q.x, size, waveState.x, waveState.y);
    float farWave = bubble::wave(q.x, size, waveState.x * 0.6, waveState.z);
    float hasSurface = step(0.5, surface.w);
    float us = (q.x - surface.y) / max(surface.z, 1.0);
    float span = sqrt(max(0.0, 1.0 - us * us));
    float spread = surface.w * span;
    float splitY = surface.x + frontWave;
    float nearY = splitY + spread;
    float farY = min(surface.x - spread + mix(frontWave, farWave, span), nearY);
    float inLiquid = smoothstep(farY - aa, farY + aa, q.y);
    if (inLiquid <= 0.0) {
        return half4(dry);
    }

    // Where the glass is on this row and in this column. Its distance is taken from both, so the
    // liquid meets the glass the same way along the bottom as along the sides.
    int pairs = max(sectionCount / 4, 2);
    float2 extent = bubble::crossSection((q.y - bounds.x) / max(bounds.y - bounds.x, 1.0), sections, 0, pairs);
    float2 heights = bubble::crossSection((q.x - bounds.z) / max(bounds.w - bounds.z, 1.0), sections, pairs, pairs);
    float halfWidth = max((extent.y - extent.x) * 0.5, 1.0);
    float centerX = (extent.x + extent.y) * 0.5;
    float u = clamp((q.x - centerX) / halfWidth, -1.0, 1.0);
    float path = sqrt(max(0.0, 1.0 - u * u));
    float toLeft = max(q.x - extent.x, 0.0);
    float toRight = max(extent.y - q.x, 0.0);
    float toTop = max(q.y - heights.x, 0.0);
    float toBottom = max(heights.y - q.y, 0.0);
    float wall = min(
        min(bubble::cornerDistance(toLeft, toBottom), bubble::cornerDistance(toRight, toBottom)),
        min(bubble::cornerDistance(toLeft, toTop), bubble::cornerDistance(toRight, toTop))
    );
    float depthBelow = max(q.y - nearY, 0.0);
    float slope = (bubble::wave(q.x + 1.0, size, waveState.x, waveState.y)
                   - bubble::wave(q.x - 1.0, size, waveState.x, waveState.y)) * 0.5;

    // The digits behind the liquid, refracted: magnified a little sideways by the round vessel,
    // squeezed toward the glass, and bent by the moving surface near the top.
    float2 seen = q;
    seen.x = centerX + (q.x - centerX) / 1.03;
    seen += float2(slope * 5.0, 1.0 + abs(slope) * 2.0) * exp(-depthBelow / 45.0);
    seen.x -= u * (1.0 - path) * 4.0;
    float2 dispersion = float2((q.x - centerX) * 0.0015, 0.0);
    float4 refracted = float4(layer.sample(seen + dispersion).r,
                              layer.sample(seen).g,
                              layer.sample(seen - dispersion).b,
                              layer.sample(seen).a);
    float below = smoothstep(splitY - aa, splitY + aa, q.y);
    float4 behind = refracted * below;

    // Beer-Lambert: the longer the light's path through the liquid, the more of its tint, and the
    // less light reaches the deeper parts of a fuller vessel.
    float3 tint = float3(tintColor.rgb);
    float3 glow = float3(glowColor.rgb);
    float3 backdrop = float3(backdropColor.rgb);
    float3 absorb = -log(clamp(tint, 0.02, 0.98));
    float thickness = mix(0.35, 1.0, path) * (dark ? 1.35 : 0.6) * look.y;
    float3 transmitted = exp(-absorb * thickness);
    float leastTransmitted = min(transmitted.r, min(transmitted.g, transmitted.b));
    float lightLeft = mix(0.28, 1.0, exp(-depthBelow / 80.0));
    float scattered = 1.0 - (transmitted.r + transmitted.g + transmitted.b) / 3.0;
    float3 light = glow * scattered * lightLeft * (dark ? 0.62 : 0.22);

    // Light bent by the curved glass gathers along the side wall away from the light. It follows
    // the side walls only, so it does not run along the bottom as a streak.
    float sideWall = min(toLeft, toRight);
    float rim = exp(-bubble::squared((sideWall - 3.2) / 2.6))
        * smoothstep(-0.1, 0.85, u)
        * smoothstep(0.30, 0.85, q.y / size.y);
    light += glow * rim * (dark ? 0.30 : 0.35);

    if (look.w > 0.0) {
        float t = waveState.w;
        float threadLight = bubble::threads(q / 34.0, t * 0.55) * 0.7 + bubble::threads(q / 22.0 + 7.3, t * 0.7) * 0.3;
        float gather = smoothstep(0.45, 0.98, q.y / size.y) * smoothstep(-0.3, 0.7, u) * smoothstep(10.0, 48.0, depthBelow);
        float depth = clamp((look.z - 0.06) / 0.45, 0.0, 1.0);
        light += glow * threadLight * gather * depth * look.w * (dark ? 0.06 : 0.03);
    }

    // The glass behind the liquid is not in this layer, so the liquid is returned as a
    // premultiplied color that, laid over the glass, filters it by the tint and adds the light it
    // scatters. `backdropColor` approximates that glass so its tint can be reproduced.
    float alpha = 1.0 - (1.0 - behind.a) * leastTransmitted;
    float3 rgb = behind.rgb * transmitted + light + (1.0 - behind.a) * backdrop * (transmitted - leastTransmitted);

    // A thin denser edge where the liquid meets the glass.
    float edge = exp(-wall / 1.3) * 0.28;
    rgb *= 1.0 - edge;
    alpha = 1.0 - (1.0 - alpha) * (1.0 - edge);

    if (hasSurface > 0.5) {
        float onSurface = 1.0 - smoothstep(nearY - aa, nearY + aa, q.y);
        float ts = clamp((q.y - farY) / max(nearY - farY, 0.5), 0.0, 1.0);

        // The far part of the surface mirrors its surroundings; nearer, it looks into the liquid.
        float fresnel = mix(0.45, 0.06, ts) * onSurface;
        float3 sky = dark ? mix(glow, float3(1.0), 0.35) * 0.5 : float3(1.0);
        rgb = rgb * (1.0 - fresnel) + sky * fresnel;
        alpha = alpha * (1.0 - fresnel) + fresnel;

        // Glints: the light from the top left, reflected by the moving surface.
        float z = mix(-1.0, 1.0, ts) * surface.z * span;
        float3 surfacePoint = float3(q.x - size.x * 0.5, 0.0, z);
        float3 normal = normalize(float3(slope * 1.8, 1.0, (farWave - frontWave) * 0.06));
        float3 toLight = normalize(float3(-190.0, 260.0, -120.0) - surfacePoint);
        float3 toEye = normalize(float3(0.0, 300.0, 900.0) - surfacePoint);
        float glint = pow(max(dot(normal, normalize(toLight + toEye)), 0.0), 140.0) * onSurface;
        rgb += glint * (dark ? 0.8 : 0.85);
        alpha = min(1.0, alpha + glint);

        // The edges fade toward the glass, so they read as light on the surface, not as outlines.
        // The surface reaches past the glass, which cuts it off, so the fade follows the glass.
        float fade = (1.0 - smoothstep(0.80, 1.0, abs(us))) * smoothstep(0.5, 8.0, wall) * (1.0 - cue * 0.2);
        float side = clamp(us * 0.5 + 0.5, 0.0, 1.0);
        float farLine = exp(-bubble::squared((q.y - farY) / 0.55)) * fade * mix(1.0, 0.45, side) * (dark ? 0.55 : 0.40);
        float nearLine = exp(-bubble::squared((q.y - nearY) / 0.55)) * fade * mix(1.0, 0.6, side) * (dark ? 0.60 : 0.50);
        float3 deep = float3(deepColor.rgb) * 0.8;
        rgb = mix(rgb, dark ? float3(1.0) : deep, farLine);
        alpha = mix(alpha, 1.0, farLine);
        rgb = mix(rgb, dark ? glow : deep, nearLine);
        alpha = mix(alpha, 1.0, nearLine);

        // The liquid climbs the glass a little where they meet.
        float meniscus = exp(-bubble::squared(wall / 4.0))
            * exp(-bubble::squared((q.y - splitY) / (surface.w + 2.0))) * 0.35;
        rgb = mix(rgb, float3(1.0), meniscus);
        alpha = mix(alpha, 1.0, meniscus);
    }

    float4 liquid = float4(min(rgb, float3(alpha)), alpha);

    // Above the wave line the digits stay in front of the surface, crisp and in their glass colors.
    float4 dryAbove = dry * (1.0 - below);
    float4 composite = dryAbove + liquid * (1.0 - dryAbove.a);
    return half4(mix(dry, composite, inLiquid));
}
