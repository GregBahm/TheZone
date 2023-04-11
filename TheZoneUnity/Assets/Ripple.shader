Shader "Unlit/Ripple"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _RippleParam("Ripple Param", Range(0, 1)) = .5
    }
    SubShader
    {
        Tags { "Queue"="Transparent" }
        LOD 100

        Pass
        {
            ZWrite Off
            Blend One One
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            float _RippleParam;
            float4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float center = length(i.uv - .5);
                float alpha = saturate(1 - center * 2);
                alpha = pow(alpha, 3);
                float ripple = abs(center - _RippleParam * .5);
                ripple = saturate(0.05 - ripple) * 20;
                float topRipple = pow(ripple, 10) * 2;
                float bottomRipple = pow(ripple, 6);
                float ret = topRipple - bottomRipple;
                ret = lerp(0, ret, alpha);
                return ret * _Color;
            }
            ENDCG
        }
    }
}
