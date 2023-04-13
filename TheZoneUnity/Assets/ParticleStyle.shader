Shader "Unlit/ParticleStyle"
{
    Properties
    {
        _ReflectionIntensity("_ReflectionIntensity", Float) = 1
        _ReflectionFadeRate("ReflectionFadeRate", Float) = 1
        _ColorB("Shadow Color", Color) = (1,1,1,1)
        _ColorC("Secondary Light", Color) = (1,1,1,1)
        _UnderwaterColor("Underwater Color", Color) = (1,1,1,1)
        _ReflectColor("Reflect Color", Color) = (1,1,1,1)
        _ShadowCol("Shadow Color", Color) = (1,1,1,1)
    }
    SubShader
    {
            Tags { "Queue" = "Transparent"}
        Pass // MAIN
        {
            Tags { "LightMode" = "UniversalForward"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float3 color : COLOR0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldNormal : NORMAL;
                float4 worldPos : TEXCOORD1;
                float3 color : COLOR0;
            };

            float3 _ColorB;
            float3 _ColorC;
            float3 _UnderwaterColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldNormal = mul(unity_ObjectToWorld, v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.color = v.color;
                return o;
            }

            float3 GetCol(float3 norm, float y, float3 mainCol)
            {
                float underwater = y > 0;
                float light = dot(norm, _WorldSpaceLightPos0.xyz);
                float3 ret = lerp(_ColorB, mainCol, saturate(light));
                ret += (norm.z * .5 + .5) * _ColorC;
                float3 underwaterCol = _ColorB;
                underwaterCol += (norm.y * .5) * _ColorC;
                float underFade = 1 - (abs(y) * .1  );
                underFade = saturate(underFade);
                underFade = pow(underFade, 20);
                underwaterCol *= underFade;
                underwaterCol = max(_UnderwaterColor, underwaterCol);
                ret = lerp(underwaterCol, ret, underwater);
                return ret;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 col = GetCol(i.worldNormal, i.worldPos.y, i.color);
                float waterLine = pow(saturate(1 - abs(i.worldPos.y)), 10);
                col += waterLine * _ColorC;
                return float4(col, 1);
            }
            ENDCG
        }

        Pass // REFLECTION
        {
            Tags { "LightMode" = "SRPDefaultUnlit" "Queue" = "Transparent"}
            Cull Front
            //ZWrite Off
            //ZTest Always
            //Blend One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float3 color : COLOR0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldNormal : NORMAL;
                float4 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD0;
                float3 color : COLOR0;
            };

            sampler2D _WaterTexture;

            float3 _ColorB;
            float3 _ColorC;
            float3 _ReflectColor;
            float _ReflectionFadeRate;
            float _ReflectionIntensity;

            float3 RayPlaneIntersection(float3 rayOrigin, float3 rayDirection, float3 planeNormal)
            {
                float t = dot((-rayOrigin), planeNormal) / dot(rayDirection, planeNormal);
                return rayOrigin + t * rayDirection;
            }

            float2 GetUV(float2 screenPos)
            {
                screenPos = screenPos / _ScreenParams.xy;
                screenPos *= 10;
                float3 rayOrigin = float3(screenPos.x, screenPos.y, 0);
                float3 cameraForward = mul(float4(0, 0, 1, 0), UNITY_MATRIX_V).xyz;
                float3 intersectionPoint = RayPlaneIntersection(rayOrigin, cameraForward, float3(0, 1, 0));
                float2 ret = intersectionPoint.xz;
                return ret;
            }

            float4 GetVertex(float4 worldPos)
            {
                float4 mirroredObj = mul(unity_WorldToObject, worldPos);
                float4 clipPos = UnityObjectToClipPos(mirroredObj);
                float2 uv = GetUV(clipPos.xy);
                //clipPos.x += sin(clipPos.y * 5 + _Time.z);// * worldPos.y * .05;
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
                o.uv = GetUV(o.vertex.xy);
                o.color = v.color;
                return o;
            }

            float3 GetCol(float3 norm, float3 mainCol)
            {
                float light = dot(norm, _WorldSpaceLightPos0.xyz);
                float3 ret = lerp(_ColorB, mainCol, saturate(light));
                ret += (norm.z * .5 + .5) * _ColorC;
                return ret;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                clip(-i.worldPos.y);
                float3 col = GetCol(i.worldNormal, i.color);
                float toPlane = 1 - saturate(-i.worldPos.y * _ReflectionFadeRate);
                toPlane = pow(toPlane, 20);
                col *= toPlane * _ReflectionIntensity;
                col *= _ReflectColor;
                return float4(col, 1);
            }
            ENDCG
        }
    }
}
