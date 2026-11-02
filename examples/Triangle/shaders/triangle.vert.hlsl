struct VSOut {
    float4 position : SV_Position;
    float3 color    : COLOR0;
};

VSOut main(uint vertexID : SV_VertexID) {
    float2 positions[3] = {
        float2( 0.0, -0.6),
        float2( 0.6,  0.6),
        float2(-0.6,  0.6)
    };

    float3 colors[3] = {
        float3(1.0, 0.1, 0.1),
        float3(0.1, 1.0, 0.1),
        float3(0.1, 0.3, 1.0)
    };

    VSOut o;
    o.position = float4(positions[vertexID], 0.0, 1.0);
    o.color = colors[vertexID];
    return o;
}