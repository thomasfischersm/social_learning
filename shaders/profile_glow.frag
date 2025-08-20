#version 100
precision mediump float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uAvatarRadius;
uniform float uGlowStrength;

half4 main(vec2 fragCoord) {
  float strength = clamp(uGlowStrength, 0.0, 1.0);
  if (strength <= 0.0) {
    return vec4(0.0);
  }

  vec2 center = uResolution * 0.5;
  vec2 uv = (fragCoord - center) / uAvatarRadius;

  // Sun center rises toward the top-right as strength increases.
  vec2 sunCenter = vec2(0.35, mix(0.3, -0.35, strength));
  float sunRadius = 0.18;

  float planetDist = length(uv);
  float sunDist = length(uv - sunCenter);

  // 1/x-style halo fade
  float halo = 1.0 / (1.0 + 10.0 * max(sunDist - sunRadius, 0.0));

  // rim highlight hugging the avatar edge
  float rimWidth = 0.02 + 0.08 * strength;
  float rim = (1.0 - smoothstep(1.0, 1.0 + rimWidth, planetDist)) * step(1.0, planetDist);

  // Angular mask so the glow mainly appears near the sun
  float dir = dot(normalize(uv), normalize(sunCenter));
  float arcMask = smoothstep(-0.4, 1.0, dir);

  // Base color transitions: white -> yellow -> orange -> black
  vec3 white = vec3(1.0);
  vec3 yellow = vec3(1.0, 0.9, 0.5);
  vec3 orange = vec3(1.0, 0.6, 0.2);
  vec3 black = vec3(0.0);

  float d = sunDist - sunRadius;
  vec3 color = white;
  color = mix(color, yellow, smoothstep(0.0, 0.1, d));
  color = mix(color, orange, smoothstep(0.1, 0.25, d));
  color = mix(color, black, smoothstep(0.25, 0.6, d));

  // Dark contrast ring for visibility on light backgrounds
  float darkRing = (1.0 - smoothstep(1.02, 1.15, planetDist)) * arcMask;
  color = mix(color, black, darkRing);

  // Sun flares
  float angle = atan(uv.y - sunCenter.y, uv.x - sunCenter.x);
  float flare = pow(max(0.0, cos(angle * 8.0)), 32.0);
  flare *= smoothstep(sunRadius, sunRadius + 0.5, sunDist);
  color += vec3(1.0, 0.8, 0.3) * flare * strength;
  halo += flare * 0.2 * strength;

  float alpha = halo * rim * arcMask;
  return vec4(color, alpha);
}
