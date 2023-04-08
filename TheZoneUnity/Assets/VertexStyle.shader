Shader "Unlit/VertexShaderStyle"
{
    Properties
    {
        _Depth("Depth", Range(0, 1)) = .0005
        _ColorA("Color A", Color) = (1,1,1,1)
        _ColorB("Color B", Color) = (1,1,1,1)
        _ColorC("Color C", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldNormal : NORMAL;
                float4 worldPos : TEXCOORD1;
            };

            float3 _ColorA;
            float3 _ColorB;
            float3 _ColorC;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldNormal = mul(unity_ObjectToWorld, v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            float3 GetCol(float3 norm)
            {
                float light = dot(norm, _WorldSpaceLightPos0.xyz);
                float3 ret = lerp(_ColorB, _ColorA, saturate(light));
                ret += (norm.z * .5 + .5) * _ColorC;
                return ret;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                clip(i.worldPos.y);
                float3 col = GetCol(i.worldNormal);
                return float4(col, 1);
            }
            ENDCG
        }

        Tags { "RenderType" = "Transparent" }
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Front
            ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldNormal : NORMAL;
                float4 worldPos : TEXCOORD1;
            };

            float3 _ColorA;
            float3 _ColorB;
            float3 _ColorC;

            float4 GetVertex(float4 worldPos)
            {
                float4 mirroredObj = mul(unity_WorldToObject, worldPos);
                float4 clipPos = UnityObjectToClipPos(mirroredObj);
                clipPos.x += sin(clipPos.y * 5) * worldPos.y * .05;
                return clipPos;
            }

            v2f vert(appdata v)
            {
                v2f o;
                o.worldNormal = mul(unity_ObjectToWorld, v.normal);
                float4 baseWorld = mul(unity_ObjectToWorld, v.vertex);
                float4 mirroredWorld = baseWorld * float4(1, -1, 1, 1);
                o.worldPos = mirroredWorld;
                o.vertex = GetVertex(mirroredWorld);
                return o;
            }

            float3 GetCol(float3 norm)
            {
                float light = dot(norm, _WorldSpaceLightPos0.xyz);
                float3 ret = lerp(_ColorB, _ColorA, saturate(light));
                ret += (norm.z * .5 + .5) * _ColorC;
                return ret;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                clip(-i.worldPos.y);
                float3 col = GetCol(i.worldNormal);
                float toPlane = 1.0 / (0 + abs(i.worldPos.y) * 50);
                return float4(col, toPlane);
            }
            ENDCG
        }
    }
}
