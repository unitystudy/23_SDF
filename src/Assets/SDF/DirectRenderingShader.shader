Shader "SDF/DirectRenderingShader"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex CustomRenderTextureVertexShader
            #pragma fragment frag

            #include "UnityCustomRenderTexture.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;

            fixed4 frag (v2f_customrendertexture  i) : SV_Target
            {
				float2 uv = i.globalTexcoord; // [0,1]x[0,1]の範囲で値が入る

				// 中心(0.5, 0.5)から半径0.25以内を赤、それ以外を白にする 
				const fixed4 red   = fixed4(1, 0, 0, 1);
				const fixed4 white = fixed4(1, 1, 1, 1);

				uv -= 0.5;
				fixed4 col = (dot(uv, uv) < 0.25 * 0.25) ? red : white;

                return col;
            }
            ENDCG
        }
    }
}
