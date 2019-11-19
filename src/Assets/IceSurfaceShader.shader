Shader "Custom/IceSurfaceShader"
{
    Properties
    {
		_MainTex("Texture", 2D) = "white" {}
		_EnvTex("Env map", CUBE) = "white" {}
		[PowerSlider(5.)]_HeightScale("Height Scale", Range(0.01, 10.0)) = 1.0
		[PowerSlider(5.)]_SphericScale("Spheric Scale", Range(0.00, 10.0)) = 0.3
		[PowerSlider(5.)]_TessFactor("Tess Factor",Range(1.0, 1000.0)) = 30
	}
    SubShader
    {
        Tags { "RenderType"="Transparent" }
		Blend One OneMinusSrcAlpha
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
			#pragma hull     hull
			#pragma domain   dom
			#pragma fragment frag

            #include "UnityCG.cginc"
			#include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

			struct v2h {
				float3 pos    : POS;
				float2 uv     : TEXCOORD0;
				float3 normal : NORMAL;
			};
			struct h2d_main {
				float3 pos    : POS;
				float2 uv     : TEXCOORD0;
				float3 normal : NORMAL;
			};
			struct h2d_const {
				float tess_factor[3]   : SV_TessFactor;
				float InsideTessFactor : SV_InsideTessFactor;
			};
			struct d2f {
				float4 pos    : SV_POSITION;
				float2 uv     : TEXCOORD0;
				float3 vPos   : TEXCOORD1;// ビュー空間での位置
				float3 normal : NORMAL;
			};

            sampler2D _MainTex;
			samplerCUBE _EnvTex;
			float4 _MainTex_ST;
			float _HeightScale;
			float _TessFactor;
			float _SphericScale;

			fixed3 random3(float3 st) {
				st = float3(dot(st, float3(127.1, 311.7, 509.3)),
						    dot(st, float3(269.5, 183.3, 470.1)),
							dot(st, float3(692.3, 295.6, 195.4))
					);
				return -1.0 + 2.0 * frac(sin(st) * 43758.5453123);
			}

			float Noise(float3 st)
			{
				float3 p = floor(st);
				float3 f = frac(st);
				float3 u = f * f * (3.0 - 2.0 * f);

				return lerp(
					lerp(lerp(dot(random3(p + float3(0.0, 0.0, 0.0)), f - float3(0.0, 0.0, 0.0)),
						      dot(random3(p + float3(1.0, 0.0, 0.0)), f - float3(1.0, 0.0, 0.0)), u.x),
						 lerp(dot(random3(p + float3(0.0, 1.0, 0.0)), f - float3(0.0, 1.0, 0.0)),
							  dot(random3(p + float3(1.0, 1.0, 0.0)), f - float3(1.0, 1.0, 0.0)), u.x), u.y),
					lerp(lerp(dot(random3(p + float3(0.0, 0.0, 1.0)), f - float3(0.0, 0.0, 1.0)),
						      dot(random3(p + float3(1.0, 0.0, 1.0)), f - float3(1.0, 0.0, 1.0)), u.x),
						 lerp(dot(random3(p + float3(0.0, 1.0, 1.0)), f - float3(0.0, 1.0, 1.0)),
							  dot(random3(p + float3(1.0, 1.0, 1.0)), f - float3(1.0, 1.0, 1.0)), u.x), u.y),
					u.z);
			}

			float Fbm(float3 texcoord)
			{
				float3 tc = float3(1, +1.0, 0) - texcoord;// 適当な場所にずらす
				float time = -0.1 * _Time.y;
				float noise = sin(tc.y +
					abs(Noise(tc *  1.0)) +
					abs(Noise(tc *  2.0)) * 0.5 +
					abs(Noise(tc *  4.0)) * 0.25 +
					abs(Noise(tc *  8.0)) * 0.125 +
					abs(Noise(tc * 16.0)) * 0.0625 +
					abs(Noise(tc * 32.0)) * 0.03125 +
					abs(Noise(tc * 64.0)) * 0.015625 +
					abs(Noise(tc *128.0)) * 0.0078125);
				noise = noise / (1.0 + 0.5 + 0.25 + 0.125 + 0.0625 + 0.03125 + 0.015625 + 0.0078125); // 正規化

				return noise;
			}


			v2h vert (appdata v)
            {
				v2h o;
                o.pos = v.vertex.xyz;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.normal = normalize(v.vertex);// 原点からの向きを法線に
				return o;
            }

			h2d_const HSConst(InputPatch<v2h, 3> i) {
				h2d_const o = (h2d_const)0;
				o.tess_factor[0] = _TessFactor;
				o.tess_factor[1] = _TessFactor;
				o.tess_factor[2] = _TessFactor;
				o.InsideTessFactor = _TessFactor;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[outputcontrolpoints(3)]
			[patchconstantfunc("HSConst")]
			h2d_main hull(InputPatch<v2h, 3> i, uint id:SV_OutputControlPointID) {
				h2d_main o = (h2d_main)0;
				o.pos = i[id].pos;
				o.uv = i[id].uv;
				o.normal = i[id].normal;
				return o;
			}

			// bの倍の長さを持つ原点に置かれたキューブからの符号付距離を符号を含めて求める
			float3 get_distance_cube(float3 p, float3 b)
			{
				float3 q = p;
				q = (b < q) ? b : q;
				q = (q <-b) ?-b : q;
				return q - p;
			}

			[domain("tri")]
			d2f dom(h2d_const hs_const_data, const OutputPatch<h2d_main, 3> i, float3 bary:SV_DomainLocation) {
				d2f o = (d2f)0;
				o.uv = i[0].uv * bary.x + i[1].uv * bary.y + i[2].uv * bary.z;
				float3 nrm = i[0].normal * bary.x + i[1].normal * bary.y + i[2].normal * bary.z;
				float3 pos0 = i[0].pos * bary.x + i[1].pos * bary.y + i[2].pos * bary.z;

				// ★変更点★ 少し丸くする
				float3 signed_distance = get_distance_cube(pos0, 0.5 - _SphericScale);
				float3 pos = pos0 + signed_distance * (1 - _SphericScale/ length(signed_distance)); 
								// _SphericScale だけ話して符号付の方向に動かす

				nrm = normalize(pos);

				// 凹凸をつける
				float height = Fbm(pos.xyz) * _HeightScale;
				pos = pos + nrm * height;

				o.pos = UnityObjectToClipPos(float4(pos, 1));
				o.vPos = UnityObjectToViewPos(float4(pos, 1)).xyz;

				// 法線の再計算(近傍との差を計算する)
				float3 du, dv;
				if (bary.y < bary.x && bary.z < bary.x) {
					du = pos0 + (i[1].pos - pos0) * 0.01;
					dv = pos0 + (i[2].pos - pos0) * 0.01;
				}
				else if(bary.x < bary.y && bary.z < bary.y){
					du = pos0 + (i[2].pos - pos0) * 0.01;
					dv = pos0 + (i[0].pos - pos0) * 0.01;
				}
				else {
					du = pos0 + (i[0].pos - pos0) * 0.01;
					dv = pos0 + (i[1].pos - pos0) * 0.01;
				}
				// 少し丸くする
				float3 sdu = get_distance_cube(du, 0.5 - _SphericScale);
				float3 sdv = get_distance_cube(dv, 0.5 - _SphericScale);
				du = du + sdu * (1 - _SphericScale / length(sdu));
				dv = dv + sdv * (1 - _SphericScale / length(sdv));
				// 凹凸をつける 
				du = (du - pos) + nrm * Fbm(du) * _HeightScale;
				dv = (dv - pos) + nrm * Fbm(dv) * _HeightScale;
				// 接ベクトルの外積から法線を求める
				nrm = normalize(cross(du, dv));

				o.normal = UnityObjectToWorldNormal(nrm);
				return o;
			}

			fixed4 frag (d2f i) : SV_Target
            {
				// ビュー空間で計算
				float3 light_dir = normalize(mul(UNITY_MATRIX_V, _WorldSpaceLightPos0.xyz) - i.vPos);
				float3 view_dir = -normalize(i.vPos);
				float3 normal = normalize(mul(UNITY_MATRIX_V, i.normal));

				// 表面の色
				fixed4 albedo = tex2D(_MainTex, i.uv);
				fixed3 diffuse = 0.15 * albedo * _LightColor0 * max(dot(light_dir, normal), 0);

				// 環境マップ
				float fresnel = 0.08 + (1 - 0.08) * pow(1 - dot(view_dir, normal), 5);
				fixed4 envmap = fresnel * texCUBE(_EnvTex, normal);

				fixed3 specular = 10.0 * fresnel * _LightColor0 * 
					pow(max(dot(normal, normalize(view_dir + light_dir)), 0), 80);

				fixed3 col = diffuse + specular + envmap;
				fixed alpha = fresnel;// 反射しなかった分を透けさせる

				return   fixed4(col, alpha);
            }
            ENDCG
        }
    }
}
