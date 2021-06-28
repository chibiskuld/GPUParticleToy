Shader "Skuld/Effects/GPU Particles/Render PointCloud"
{
	Properties
	{
		[hdr]_Buffer("Compute Input Texture", 2D) = "white" {}
		_Vertices("Number of Vertices in Default Shape", int) = 0
		_Size("Particle Size", float) = 1
		[Toggle] _ZWrite("Z-Write",Float) = 1
	}
		SubShader
		{
			Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
			cull Off
			Blend SrcAlpha One
			Lighting Off
			SeparateSpecular Off
			ZWrite[_ZWrite]

			Pass
			{
				CGPROGRAM
				#pragma target 3.0
				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile_instancing
				#pragma multi_compile

				#include "shared.cginc"
				#include "UnityCG.cginc"

				struct appdata
				{
					float4 position : POSITION;
					uint id : SV_VertexID;
				};

				struct v2f
				{
					float4 position : SV_POSITION;
					float3 wposition : W_POS;
					uint id : VERTEXID;
					float4 color : COLOR;
				};

				sampler2D _Buffer;
				float4 _Buffer_ST;
				float4 _Buffer_TexelSize;
				float _Size;
				uint _Vertices;

				float4 getPosition(uint index) {
					float2 uv = IndexToUV(index, _Buffer_TexelSize);
					float4 output = tex2Dlod(_Buffer, float4(uv,0,0));
					return output;
				}

				v2f vert(appdata v)
				{
					v2f o;
					o.color.r = (float)v.id /(float)_Vertices;
					o.color.g = 0;
					o.color.b = 1;
					o.color.a = 1;
					o.color = saturate(o.color);
					o.wposition = getPosition(v.id);
					o.position = UnityWorldToClipPos(o.wposition);
					float2 uv = o.wposition.yz;
					uv *=2;
					o.id = v.id;
					return o;
				}

				float4 frag(v2f i) : SV_Target
				{
					int index = i.id;
					float2 uv = IndexToUV(index, _Buffer_TexelSize);
					uv.y += .5f;
					float4 trajectory = tex2Dlod(_Buffer, float4(uv, 0, 0));

					float4 output = i.color;
					float l = length(trajectory.xyz);
					output = shiftColor(output, l);

					return output;
				}
				ENDCG
			}
		}
}
