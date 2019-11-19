Shader "SDF/SDFShader"
{
    Properties
    {
        _SDF("SDF", 2D) = "white" {}
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
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _SDF;
            float4 _SDF_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _SDF);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				// 符号付距離が正なら白、正なら赤でで表示
				const fixed4 red   = fixed4(1, 0, 0, 1);
				const fixed4 white = fixed4(1, 1, 1, 1);

				float sd = tex2D(_SDF, i.uv).r - 0.5; // オフセットの分を引く

				fixed4 col = (0 < sd) ? white : red;

				return col;
            }
            ENDCG
        }
    }
}
