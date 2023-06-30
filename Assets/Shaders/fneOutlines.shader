Shader "Universal Render Pipeline/fneOutlines"
{
    Properties
    {
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        [MainColor] _BaseColor("Color", Color) = (1,1,1,1)


        _Thickness ("Thickness", Float) = 1 // The amount to extrude the outline mesh
        _OtColor ("OtColor", Color) = (1, 1, 1, 1) // The outline color
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
