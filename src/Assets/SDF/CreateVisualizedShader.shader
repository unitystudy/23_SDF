Shader "SDF/CreateVisualizedShader"
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

				// 中心(0.5, 0.5)から半径0.25よりも距離が短ければ赤系で、遠ければモノトーンで表示
				const fixed4 red   = fixed4(1, 0, 0, 1);
				const fixed4 white = fixed4(1, 1, 1, 1);

				float sd = get_distance(uv - 0.5, 0.25);

				fixed4 col;
				col.rgb = (sd < 0) ? red * (-sd) : sd;
				col.a = 1.0;

				return col;
			}
			ENDCG
		}
	}
}
