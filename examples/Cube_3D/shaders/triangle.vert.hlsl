struct VSIn
{
    [[vk::location(0)]] float3 position : POSITION;
    [[vk::location(1)]] float3 color    : COLOR0;
};

struct VSOut
{
    float4 position : SV_Position;
    [[vk::location(0)]] float3 color : COLOR0;
};

VSOut main(VSIn input) {
    VSOut output;

    float3 p = input.position * 0.75;

    // Fixed rotation so the cube is visible.
    const float cy = 0.80;
    const float sy = 0.60;
    const float cx = 0.90;
    const float sx = -0.43;

    float3 q;
    q.x = p.x * cy + p.z * sy;
    q.y = p.y;
    q.z = -p.x * sy + p.z * cy;

    float3 r;
    r.x = q.x;
    r.y = q.y * cx - q.z * sx;
    r.z = q.y * sx + q.z * cx;

    // Simple D3D/Vulkan-style 0..1 depth projection.
    const float nearZ = 0.1;
    const float farZ = 10.0;
    const float focal = 1.35;

    float viewZ = r.z + 3.0;
    float clipZ = viewZ * farZ / (farZ - nearZ) - nearZ * farZ / (farZ - nearZ);

    output.position = float4(r.x * focal, r.y * focal, clipZ, viewZ);
    output.color = input.color;

    return output;
}