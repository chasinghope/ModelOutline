Shader "Outlines/BackFaceOutlines" 
{
    Properties 
    {
        _Thickness ("Thickness", Float) = 1 // The amount to extrude the outline mesh
        _OtColor ("Color", Color) = (1, 1, 1, 1) // The outline color
        // If enabled, this shader will use "smoothed" normals stored in TEXCOORD1 to extrude along
        [Toggle(USE_PRECALCULATED_OUTLINE_NORMALS)]_PrecalculateNormals("Use UV1 normals", Float) = 0

        _FresnalColor("FresnalColor", color) = (1,1,1,0)
        _FresnalScale("FresnalScale", float) = 1
    }
    SubShader {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }

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

        Pass
        {
            Name "FresnalOutlines"
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;              
                float4 vertex : SV_POSITION;
                float3 worldNormal: TEXCOORD1;
                float3 WorViewDir: TEXCOORD2;            
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _FresnalColor;
           
            float  _FresnalScale;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                //ģ�Ϳռ�ķ���ת��������ķ���
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                //����һ��ģ�Ϳռ��еĶ���λ�ã���������ռ��дӸõ㵽������Ĺ۲췽��
                o.WorViewDir = WorldSpaceViewDir(v.vertex);
                return o;
            }

            half remap(half x, half t1, half t2, half s1, half s2)
            {
                return (x - t1) / (t2 - t1) * (s2 - s1) + s1;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                //���������ƹ�ʽ���㷨��Ҫ����
                fixed3 worldNor = normalize(i.worldNormal);
                fixed3 worViewDir= normalize(i.WorViewDir);
                //���������ϵ��
                fixed fres = _FresnalScale + (1 - _FresnalScale) * pow(1 - dot(worViewDir, worldNor), 5);

                //������ϵ�����Է���������ɫ,
                //ͨ��������ϵ������Ե���ֻ�����ɫ��ʾ����Ե֮��������ɫ������_FresnalScale����ɫ������������
                //ͨ��Remap��������ӳ�䣬����_SinTime�ȡ����������Է����ǿ�ȣ����������_FresnalScale
                fixed3 fresCol = _FresnalColor * fres*remap(_SinTime,-1,1,0.2,1);


                //����UV������ȡ�����϶�Ӧ��������Ϣ
                fixed4 col = tex2D(_MainTex, i.uv);

                return col+ fixed4(fresCol,1);
              
             
            }
            ENDCG
        }
    }
}