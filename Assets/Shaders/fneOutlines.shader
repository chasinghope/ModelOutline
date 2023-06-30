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

                //ģ�Ϳռ�ķ���ת��������ķ���
                o.worldNormal = TransformObjectToWorldNormal(v.normal);
                //����һ��ģ�Ϳռ��еĶ���λ�ã���������ռ��дӸõ㵽������Ĺ۲췽��
                o.WorViewDir = input.positionVS;
                o.positionCS = input.positionCS;
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
                return o;
            }


            half4 frag(v2f i) : SV_Target
            {
                //���������ƹ�ʽ���㷨��Ҫ����
                half3 worldNor = normalize(i.worldNormal);
                half3 worViewDir= normalize(i.WorViewDir);
                //���������ϵ��
                half fres = _FresnalScale + (1 - _FresnalScale) * pow(1 - dot(worViewDir, worldNor), 5);

                //������ϵ�����Է���������ɫ,
                //ͨ��������ϵ������Ե���ֻ�����ɫ��ʾ����Ե֮��������ɫ������_FresnalScale����ɫ������������
                //ͨ��Remap��������ӳ�䣬����_SinTime�ȡ����������Է����ǿ�ȣ����������_FresnalScale
                half3 fresCol = _FresnalColor * fres * remap(_SinTime,-1,1,0.2,1);
                //����UV������ȡ�����϶�Ӧ��������Ϣ
                half4 col = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);

                return col + half4(fresCol,1);                          
            }
            ENDHLSL
        }
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
