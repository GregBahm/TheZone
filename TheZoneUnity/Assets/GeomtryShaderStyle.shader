Shader "Unlit/GeometryShaderStyle"
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
            #pragma geometry geo
            #pragma fragment frag

            #include "UnityCG.cginc"
            float _Depth;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2g
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float3 worldNormal : TEXCOORD2;
                float3 viewDir : TEXCOORD1;
            };

            struct g2f
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float3 worldNormal : TEXCOORD2;
                float3 viewDir : TEXCOORD1;
                float4 worldPos : POSITION2;
                float dist : TEXCOORD3;
            };

            float3 _ColorA;
            float3 _ColorB;
            float3 _ColorC;

            float3 GetCol(float3 norm)
            {
                float light = dot(norm, _WorldSpaceLightPos0.xyz);
                float3 ret = lerp(_ColorB, _ColorA, saturate(light));
                ret += (norm.z * .5 + .5) * _ColorC;
                return ret;
            }

            v2g vert(appdata v)
            {
                v2g o;
                o.vertex = v.vertex;
                o.normal = v.normal;
                o.worldNormal = mul(unity_ObjectToWorld, v.normal);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                return o;
            }

            float4 GetWorldPos(v2g input, float dist)
            {
                dist = (dist - .5) * 2;
                dist *= _Depth;

                float4 baseWorld = mul(unity_ObjectToWorld, input.vertex);

                float planeDist = abs(baseWorld.y);

                float3 vertOffset = input.normal * dist * planeDist;
                input.vertex += float4(vertOffset, 0);
                float4 offsetWorld = mul(unity_ObjectToWorld, input.vertex);


                return offsetWorld * float4(1, -1, 1, 1);
            }

            float4 GetVertex(float4 worldPos)
            {
                float4 mirroredObj = mul(unity_WorldToObject, worldPos);
                float4 clipPos = UnityObjectToClipPos(mirroredObj);
                clipPos.x += sin(clipPos.y * 5) * worldPos.y * .05;
                return clipPos;
            }

            void ApplyToTristream(v2g p[3], inout TriangleStream<g2f> triStream, float dist)
            {
                g2f o;
                o.dist = dist;

                o.normal = p[0].normal;
                o.viewDir = p[0].viewDir;
                o.worldNormal = p[0].worldNormal;
                o.worldPos = GetWorldPos(p[0], dist);
                o.vertex = GetVertex(o.worldPos);
                triStream.Append(o);

                o.normal = p[1].normal;
                o.viewDir = p[1].viewDir;
                o.worldNormal = p[1].worldNormal;
                o.worldPos = GetWorldPos(p[1], dist);
                o.vertex = GetVertex(o.worldPos);
                triStream.Append(o);

                o.normal = p[2].normal;
                o.viewDir = p[2].viewDir;
                o.worldNormal = p[2].worldNormal;
                o.worldPos = GetWorldPos(p[2], dist);
                o.vertex = GetVertex(o.worldPos);
                triStream.Append(o);
            }

#define SliceCount 10

            [maxvertexcount(3 * SliceCount)]
            void geo(triangle v2g p[3], inout TriangleStream<g2f> triStream)
            {
                for (int i = 0; i < SliceCount; i++)
                {
                    float dist = (float)i / SliceCount;
                    ApplyToTristream(p, triStream, dist);
                    triStream.RestartStrip();
                }
            }

            fixed4 frag(g2f i) : SV_Target
            {
                clip(-i.worldPos.y);
                float toPlane = 1.0 / (1 + abs(i.worldPos.y) * 100);
                float3 col = GetCol(i.worldNormal);
                return float4(col, toPlane);
            }
            ENDCG
        }
    }
}
