//
//  BlackHole.metal
//  dark-hole
//
//  Created by Daniel Amos Soares Junior on 10/02/26.
//

#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    // Bloco 1 (16 bytes)
    float time;
    float angle;
    float nearStarsDensity;    // Controle de estrelas próximas
    float distantStarsDensity; // Controle de estrelas distantes
    
    // Bloco 2 (16 bytes)
    float nebulaIntensity;     // Intensidade da nebulosa
    float rs;                  // Raio de Schwarzschild
    float dt;                  // Delta de tempo (passo do raio)
    float accelerationFactor;  // Intensidade da gravidade (ex: -1.5)
    
    // Bloco 3 (16 bytes)
    float diskInnerLimit;      // Limite interno do disco (multiplicador de rs)
    float diskOuterLimit;      // Limite externo do disco (multiplicador de rs)
    float dopplerIntensity;    // Força do efeito Doppler
    float flowFrequency;       // Frequência das bandas (flow)
    
    float cameraDistance;
    float cameraRotation;
    float isAutoRotation;
};

float hash(float3 p) {
    p = fract(p * 0.3183099 + 0.1);
    p *= 17.0;
    return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(float3 x) {
    float3 p = floor(x);
    float3 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    
    float n = p.x + p.y * 57.0 + 113.0 * p.z;
    
    float res = mix(mix(mix( hash(n + 0.0), hash(n + 1.0), f.x),
                        mix( hash(n + 57.0), hash(n + 58.0), f.x), f.y),
                    mix(mix( hash(n + 113.0), hash(n + 114.0), f.x),
                        mix( hash(n + 170.0), hash(n + 171.0), f.x), f.y), f.z);
    return res;
}

float hash13(float3 p3) {
    p3  = fract(p3 * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float getLayeredStars(float3 dir, float scale, float density) {
    float3 p = dir * scale;
    float3 id = floor(p);
    float3 gv = fract(p) - 0.5;
    
    float h = hash13(id);
    
    if (h < density) return 0.0;
    
    float relativeBrightness = pow((h - density) / (1.0 - density), 3.0);
    float dist = length(gv);
    
    float size = 0.05 + 0.15 * relativeBrightness;
    float star = smoothstep(size, size * 0.5, dist);
    
    return star * relativeBrightness;
}

kernel void blackHoleCompute(texture2d<float, access::write> output [[texture(0)]],
                             texture2d<float, access::sample> skybox [[texture(1)]],
                             constant Uniforms &uniforms [[buffer(0)]],
                             uint2 gid [[thread_position_in_grid]]) {
    
    float width = output.get_width();
    float height = output.get_height();
    if (gid.x >= width || gid.y >= height) return;
    
    float aspect = width / height;
    float2 uv = float2(gid) / float2(width, height);
    uv = uv * 2.0 - 1.0;
    uv.x *= aspect;
    
    float3 pos = float3(0.0, 1.3, -uniforms.cameraDistance);
    float3 vel = normalize(float3(uv.x, uv.y - 0.15, 1.6));
    
    float currentAngle = (uniforms.isAutoRotation > 0.5) ? uniforms.angle : uniforms.cameraRotation;
    
    float sa = sin(currentAngle);
    float ca = cos(currentAngle);
    
    float3 rotPos = float3(pos.x * ca + pos.z * sa, pos.y, -pos.x * sa + pos.z * ca);
    float3 rotVel = float3(vel.x * ca + vel.z * sa, vel.y, -vel.x * sa + vel.z * ca);
        
    pos = rotPos;
    vel = rotVel;
    
    float rs = uniforms.rs;
    float dt = uniforms.dt;
    float3 color = float3(0.0);
    float3 diskColor = float3(1.0, 0.5, 0.15);
    float glowAccum = 0.0;
    float particleAccum = 0.0;
    
    for (int i = 0; i < 450; i++) {
        float r = length(pos);
        float3 oldPos = pos;
        
        float3 L = cross(pos, vel);
        float h2 = dot(L, L);
        float3 acceleration = uniforms.accelerationFactor * rs * h2 * pos / (pow(r, 5.0) + 0.000001);
        vel += acceleration * dt;
        pos += vel * dt;


        if (r > 1.1 * rs && r < 12.0 * rs) {
            float distToPlane = abs(pos.y);

            float pNoise = noise(pos * 1.2 + float3(0, 0, uniforms.time * 1.5));
            particleAccum += smoothstep(0.3, 1.0, pNoise) * (0.015 / (distToPlane + 0.4)) * (1.0 / r);
            
            glowAccum += (0.007 / (distToPlane + 0.2)) * (rs / r);
        }
    
        if (r < rs * 1.005) {
            break;
        }
        
        if (oldPos.y * pos.y < 0.0) {
            float t = -oldPos.y / (pos.y - oldPos.y);
            float3 intersectPos = oldPos + t * (pos - oldPos);
            float d = length(intersectPos);
            
            if (d > uniforms.diskInnerLimit * rs && d < uniforms.diskOuterLimit * rs) {
                float redshift = 1.0 / sqrt(1.0 - rs / d);
                float angle = atan2(intersectPos.x, intersectPos.z);
                
                float vNoise = noise(float3(intersectPos.xz * 0.7, uniforms.time * 1.5));
                float flow = sin(angle * uniforms.flowFrequency - uniforms.time * 3.0 + d * 2.0 + vNoise * 4.0) * 0.5 + 0.5;
                
                float3 diskVel = normalize(float3(-intersectPos.z, 0.0, intersectPos.x));
                float doppler = dot(vel, diskVel);
                
                float intensity = pow(1.5 + doppler * uniforms.dopplerIntensity, 2.0) / (redshift * redshift);
                float diskWidth = (uniforms.diskOuterLimit - uniforms.diskInnerLimit) * rs;
                float falloff = pow(1.0 - (d - uniforms.diskInnerLimit * rs) / diskWidth, 2.5);
                
                float3 thermalColor = mix(diskColor, float3(0.6, 0.02, 0.0), smoothstep(1.1, 2.5, redshift));
                
                color += thermalColor * (0.4 + 0.6 * flow) * intensity * falloff * 0.65;
            }
        }
    
    }
    
    float3 finalSkyColor = float3(0.0);
    float r_final = length(pos);

    if (r_final >= rs * 1.005) {
        float bgStars = getLayeredStars(vel, 800.0, uniforms.distantStarsDensity);
        
        float midStars = getLayeredStars(vel.zxy, 500.0, uniforms.distantStarsDensity) * 1.5;
        
        float sparkle = sin(uniforms.time * 2.0 + hash13(floor(vel * 150.0)) * 6.28) * 0.5 + 0.5;
        float nearStars = getLayeredStars(vel.yzx, 150.0, uniforms.nearStarsDensity) * 3.0 * sparkle;

        float nebNoise = noise(vel * 1.5 + uniforms.time * 0.05); // Reduzimos de 3.5 para 1.5
        float3 nebulaColor = float3(0.05, 0.07, 0.12) * pow(nebNoise, 2.0) * uniforms.nebulaIntensity;
        finalSkyColor = float3(bgStars + midStars + nearStars) + nebulaColor;
        
        float3 starTint = mix(float3(0.9, 0.95, 1.0), float3(1.0, 0.9, 0.8), hash13(floor(vel * 200.0)));
        finalSkyColor *= starTint;
    }

    color += finalSkyColor;

    color = pow(color, float3(1.0 / 2.2));
    output.write(float4(color, 1.0), gid);
}
