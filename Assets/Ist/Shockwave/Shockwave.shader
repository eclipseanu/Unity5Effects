Shader "Ist/Shockwave" {

CGINCLUDE
#include "UnityCG.cginc"


sampler2D _FrameBuffer_Shockwave;
float4 _Params1;

#define _Radius             _Params1.x
#define _AttenuationPow     _Params1.y
#define _Reverse            _Params1.z
#define _Highlighting       _Params1.w

float4 _Scale;
float4 _OffsetCenter;
half4 _ColorBias;

float3 GetObjectPosition()
{
    return float3(_Object2World[0][3], _Object2World[1][3], _Object2World[2][3]);
}

struct ia_out
{
    float4 vertex : POSITION;
    float4 normal : NORMAL;
};
struct vs_out
{
    float4 vertex : SV_POSITION;
    float4 screen_pos : TEXCOORD0;
    float4 center : TEXCOORD1;
    float4 params : TEXCOORD2;
};
struct ps_out
{
    half4 color : SV_Target;
};

vs_out vert (ia_out I)
{
    vs_out O;
    O.vertex = mul(UNITY_MATRIX_MVP, I.vertex);
    O.screen_pos = ComputeScreenPos(O.vertex);
    O.center = ComputeScreenPos(mul(UNITY_MATRIX_VP, float4(GetObjectPosition() + _OffsetCenter.xyz, 1)));
    O.params = 0;

    float3 obj_pos = GetObjectPosition();
    float4 world_pos = mul(_Object2World, float4(I.vertex.xyz / _Scale.xyz, 1));
    float3 camera_dir = normalize(_WorldSpaceCameraPos.xyz - world_pos.xyz);
    float3 pos_rel = world_pos.xyz - obj_pos;
    float s_dist = dot(pos_rel, camera_dir);
    float3 pos_proj = world_pos.xyz - s_dist*camera_dir;
    float opacity = saturate(1 - length(pos_proj - world_pos)*2);
    opacity = pow(opacity, _AttenuationPow);
    opacity = lerp(opacity, 1 - opacity, _Reverse);
    O.params.x = opacity;
    return O;
}

ps_out frag (vs_out I)
{
    float2 coord = I.screen_pos.xy / I.screen_pos.w;
    float2 center = I.center.xy / I.center.w;
    float opacity = I.params.x;

    float2 dir = (coord - center);
    float4 color = tex2D(_FrameBuffer_Shockwave, coord - dir*(_Radius*opacity));
    float h = lerp(1 + opacity, 1 + (1 - opacity), _Reverse);

    ps_out O;
    O.color.rgb = color.rgb * lerp(1, h, _Highlighting);
    O.color.a = 1;

#if ENABLE_DEBUG
    O.color.rgb = opacity;
    O.color.a = 1;
#endif
    return O;
}
ENDCG

Subshader {
    Tags { "Queue"="Overlay+80" "RenderType"="Opaque" }
    //Cull Front
    //ZTest Off
    ZWrite Off

    GrabPass {
        "_FrameBuffer_Shockwave"
    }
    Pass {
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma multi_compile ___ ENABLE_DEBUG
        ENDCG
    }
}
}