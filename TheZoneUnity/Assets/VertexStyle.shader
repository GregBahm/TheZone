// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/VertexShaderStyle"
{
    Properties
    {
        _WaterTexture("Water Texture", 2D) = "white" {}
        _Depth("Depth", Range(0, 1)) = .0005
        _ColorA("Color A", Color) = (1,1,1,1)
        _ColorB("Color B", Color) = (1,1,1,1)
        _ColorC("Color C", Color) = (1,1,1,1)
        _UnderwaterColor("Underwater Color", Color) = (1,1,1,1)
        _ReflectColor("Reflect Color", Color) = (1,1,1,1)
        _ShadowCol("Shadow Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass // MAIN
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
            float3 _UnderwaterColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldNormal = mul(unity_ObjectToWorld, v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            float3 GetCol(float3 norm, float y)
            {
                float underwater = y > 0;
                float light = dot(norm, _WorldSpaceLightPos0.xyz);
                float3 ret = lerp(_ColorB, _ColorA, saturate(light));
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
                float3 col = GetCol(i.worldNormal, i.worldPos.y);
                float waterLine = pow(saturate(1 - abs(i.worldPos.y)), 10);
                col += waterLine * _ColorC;
                return float4(col, 1);
            }
            ENDCG
        }

        Pass // REFLECTION
        {
            Cull Front
            ZWrite Off
            ZTest Always
            Blend One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldNormal : NORMAL;
                float4 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD0;
            };

            sampler2D _WaterTexture;

            float3 _ColorA;
            float3 _ColorB;
            float3 _ColorC;
            float3 _ReflectColor;

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
                float toPlane = 1 - saturate(-i.worldPos.y * .1);
                toPlane = pow(toPlane, 20);
                col *= toPlane * .5;
                col *= _ReflectColor;
                return float4(col, 1);
            }
            ENDCG
        }

        Pass // SHADOW
        {
            ZWrite Off
            BlendOp Min

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float4 _ShadowCol;

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 worldPos : TEXCOORD1;
            };

            float3 RayPlaneIntersection(float3 rayOrigin, float3 rayDirection, float3 planeNormal, float3 planePos)
            {
                float t = dot((planePos - rayOrigin), planeNormal) / dot(rayDirection, planeNormal);
                return rayOrigin + t * rayDirection;
            }

            float3 GetPlaneProjection(float3 rayOrigin)
            {
                float3 rayDirection = _WorldSpaceLightPos0.xyz;

                float3 planeNormal = mul(unity_WorldToObject, float4(0, 1, 0, 0));
                float3 planePos = mul(unity_WorldToObject,float4(0, 0, 0, 1));
                float3 intersection = RayPlaneIntersection(rayOrigin, rayDirection, normalize(planeNormal.xyz), planePos.xyz);
                return intersection;
            }

            v2f vert(appdata v)
            {
                v2f o;
                float4 baseWorld = mul(unity_ObjectToWorld, v.vertex);

                float3 planePos = GetPlaneProjection(v.vertex);

                o.worldPos = baseWorld;
                o.vertex = UnityObjectToClipPos(float4(planePos, 1));
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                clip(i.worldPos.y);
                float4 ret = _ShadowCol;
                ret += (i.worldPos.y - .1) * .002;
                ret = saturate(ret);
                return ret;
            }
            ENDCG
        }
    }
}
