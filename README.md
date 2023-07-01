# ModelOutline



https://zhuanlan.zhihu.com/p/306060840

https://zhuanlan.zhihu.com/p/446473650

只是外边缘描边的话可以直接用深度图卷积来做，就是深度变化大的地方会被检测为边缘



## 法线外扩

```c
        _Thickness ("Thickness", Float) = 1 // The amount to extrude the outline mesh
        _OtColor ("Color", Color) = (1, 1, 1, 1) // The outline color


        Pass 
        {
            Name "Outlines"
            // Cull front faces
            Cull Front

            HLSLPROGRAM
            // Standard URP requirements
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x

            // Register our material keywords
            #pragma shader_feature USE_PRECALCULATED_OUTLINE_NORMALS

            // Register our functions
            #pragma vertex Vertex
            #pragma fragment Fragment

            // Include our logic file
            //#include "Inc/BackFaceOutlines.hlsl"    
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float _Thickness;
                float4 _OtColor;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            #ifdef USE_PRECALCULATED_OUTLINE_NORMALS
                float3 smoothNormalOS   : TEXCOORD1; // Calculated "smooth" normals to extrude along in object space
            #endif
            };

            struct VertexOutput
            {
                float4 positionCS : SV_POSITION;
                float4 originposCS : TEXCOORD0;
            };

            VertexOutput Vertex(Attributes input)
            {
                VertexOutput output = (VertexOutput) 0;

                float3 normalOS = input.normalOS;
            #ifdef USE_PRECALCULATED_OUTLINE_NORMALS
                normalOS = input.smoothNormalOS;
            #else
                normalOS = input.normalOS;
            #endif

                // Extrude the object space position along a normal vector
                float3 posOS = input.positionOS.xyz + normalOS * _Thickness;
                // Convert this position to world and clip space
                output.positionCS = GetVertexPositionInputs(posOS).positionCS;
                return output;
            }

            float4 Fragment(VertexOutput input) : SV_Target
            {
                return _OtColor;
            }

            ENDHLSL
        }
```



# 菲涅耳

```c
Shader "Universal Render Pipeline/fneOutlines"
{
    Properties
    {
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        [MainColor] _BaseColor("Color", Color) = (1,1,1,1)

        _FresnalColor("FresnalColor", color) = (1,1,1,0)
        _FresnalScale("FresnalScale", float) = 1
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "UniversalMaterialType" = "Lit"
            "IgnoreProjector" = "True"
        }
        LOD 300

        Pass
        {
            Name "fneOutlines"
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;              
                float4 positionCS : SV_POSITION;
                float3 worldNormal: TEXCOORD1;
                float3 WorViewDir: TEXCOORD2;            
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _FresnalColor;
                float  _FresnalScale;
                float4 _BaseMap_ST;
			CBUFFER_END



            
            half remap(half x, half t1, half t2, half s1, half s2)
            {
                return (x - t1) / (t2 - t1) * (s2 - s1) + s1;
            }

            v2f vert (appdata v)
            {
                v2f o;
                VertexPositionInputs input = GetVertexPositionInputs(v.positionOS);

                //模型空间的法线转化到世界的法线
                o.worldNormal = TransformObjectToWorldNormal(v.normal);
                //输入一个模型空间中的顶点位置，返回世界空间中从该点到摄像机的观察方向
                o.WorViewDir = input.positionVS;
                o.positionCS = input.positionCS;
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
                return o;
            }


            half4 frag(v2f i) : SV_Target
            {
                //菲涅尔近似公式的算法需要标量
                half3 worldNor = normalize(i.worldNormal);
                half3 worViewDir= normalize(i.WorViewDir);
                //计算菲涅尔系数
                half fres = _FresnalScale + (1 - _FresnalScale) * pow(1 - dot(worViewDir, worldNor), 5);

                //菲涅尔系数乘以菲涅尔的颜色,
                //通过菲涅尔系数，边缘部分会有颜色显示，边缘之外则无颜色，调节_FresnalScale，颜色会向中央蔓延
                //通过Remap函数，重映射，输入_SinTime等。用来控制自发光的强度，即变相调节_FresnalScale
                half3 fresCol = _FresnalColor * fres * remap(_SinTime,-1,1,0.2,1);
                //根据UV坐标提取纹理上对应的像素信息
                half4 col = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);

                return col + half4(fresCol,1);                          
            }
            ENDHLSL
        }
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}

```

```
Properties {
        _FresnelPow ("FresnelPow", Range(0, 1)) = 0.5
    }
    SubShader {
        Tags {
            "RenderType"="Opaque"
        }
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
            
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #include "UnityCG.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma target 3.0
            UNITY_INSTANCING_BUFFER_START( Props )
                UNITY_DEFINE_INSTANCED_PROP( float, _FresnelPow)
            UNITY_INSTANCING_BUFFER_END( Props )
            struct VertexInput {
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float4 posWorld : TEXCOORD0;
                float3 normalDir : TEXCOORD1;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID( v );
                UNITY_TRANSFER_INSTANCE_ID( v, o );
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.pos = UnityObjectToClipPos( v.vertex );
                return o;
            }
            float4 frag(VertexOutput i) : COLOR {
                UNITY_SETUP_INSTANCE_ID( i );
                i.normalDir = normalize(i.normalDir);
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                float3 normalDirection = i.normalDir;

                float _FresnelPow_var = UNITY_ACCESS_INSTANCED_PROP( Props, _FresnelPow );
                float node_2909 = ceil((pow(dot(i.normalDir,viewDirection),_FresnelPow_var)*2.0+-1.0));
                float3 emissive = float3(node_2909,node_2909,node_2909);
                float3 finalColor = emissive;
                return fixed4(finalColor,1);
            }
            ENDCG
```

