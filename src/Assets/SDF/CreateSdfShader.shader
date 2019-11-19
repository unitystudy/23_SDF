Shader "SDF/CreateSdfShader"
{
	SubShader
	{
		Tags { "RenderType" = "Opaque" }

		Pass
		{
			CGPROGRAM
			#pragma vertex CustomRenderTextureVertexShader
			#pragma fragment frag

			#include "UnityCustomRenderTexture.cginc"

			float get_distance(float2 p, float r)
			{
				return length(p) - r;
			}

			fixed4 frag(v2f_customrendertexture  i) : SV_Target
			{
				float2 uv = i.globalTexcoord; // [0,1]x[0,1]の範囲で値が入る

				// 中心(0.5, 0.5)から半径0.25の境界からの符号付き距離をオフセット0.5をつけて記録
				float sd = get_distance(uv - 0.5, 0.25);

				fixed4 col;
				col.rgb = sd + 0.5;
				col.a = 1.0;

				return col;
			}
			ENDCG
		}
	}
}
