/*
data should be:
[0][0] Position of Vertex 1
[0][512] Direction/Velocity of Vertex 1
*/
Shader "Skuld/Effects/GPU Particles/Compute (Render Texture)"
{
    Properties
    {
		_Speed("Speed of Simulation",float) = .1
		_Strength("Strength of gravity",float) = 1
		_Range("Range of gravity",float) = 10
		_Decelleration("Rate of Deceleration",float ) = 0
		_Reset("reset",range(0,1)) = 0
		[hdr]_MainTex ("Default Shape", 2D) = "white" {}
		_Scale("Default Shape Scale",float) = 100
		_Offset("Default Shape Offset",Vector ) = (0,0,0,1)
		_Rotation("Default Shade Rotation",Vector) = (0,0,0,1)
		[hdr]_Buffer("Computer Input Texture:",2D) = "Gray" {}
		_Vertices("Number of Vertices in Default Shape", int) = 0
		_GravityPoint("Gravity Point",Vector) = (0,0,0,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
		cull Back

        Pass
        {
			Tags { "LightMode" = "ForwardBase" }
            CGPROGRAM

			#include "UnityCustomRenderTexture.cginc"
            #include "UnityCG.cginc"
			#include "shared.cginc"

			#pragma target 5.0
            #pragma vertex CustomRenderTextureVertexShader
            #pragma fragment frag
            // make fog work
            #pragma multi_compile

			sampler2D_float _MainTex;
			float4 _MainTex_ST;
			float4 _MainTex_TexelSize;
			float _Scale;
			sampler2D _Buffer;
			float4 _Buffer_ST;
			float4 _Buffer_TexelSize;
			float4 _Offset;
			float4 _Rotation;
			float _Reset;
			uint _Vertices;
			float _Speed;
			float _Range;
			float _Strength;
			float _Decelleration;
			float4 _GravityPoint;

			//for global use
			float speed;


			float4 AddInfluence(float4 influence,float4 position,float4 trajectory) 
			{
				float3 gravity = normalize(influence.xyz - position.xyz);
				float G = length(gravity);
				G = _Range - G;
				G = max(0, G);
				G *= G;
				float weight = G * _Strength * speed;
				gravity *= weight;
				
				trajectory.xyz += gravity;
				
				//velocity for the output color
				trajectory.w = G;

				return trajectory;
			}

			float4 CalculateTrajectory(v2f_init_customrendertexture i) {
				float4 position = tex2D(_Buffer, float2(i.texcoord.x, i.texcoord.y - .5f));
				float4 trajectory = tex2D(_Buffer, i.texcoord);
				float3 gravity = float4(normalize(float3(0, 0, 0) - position.xyz), 0);

				//if vertex lights are on, I want it to shut the fake center point off
				float4 defaultPos = _GravityPoint;
				//defaultPos.y += 1;
				trajectory = AddInfluence(defaultPos, position, trajectory);

				//Decelleration
				trajectory.xyz *= 1 - (_Decelleration * (unity_DeltaTime.x / 100.0f) );
				return trajectory;
			}

			float4 frag (v2f_init_customrendertexture i) : SV_Target
            {
				float4 resat = float4(0,0,0,1);
				//set the initial velocity
				UNITY_BRANCH
				if (i.texcoord.y > .5f) {
					resat = float4(10, 0, 0, .1f);
					resat.xy = rotate2(resat.xy, (_Time.z * 10) + ((i.texcoord.y * 10) + i.texcoord.x) * 1666);
					resat.yz = rotate2(resat.yz, (_Time.z * 10) + ((i.texcoord.y * 10) - i.texcoord.x) * 1666);
				}
				else {
					uint index = UVToIndex(i.texcoord, _Buffer_TexelSize);
					index = index % _Vertices;
					float2 uv = IndexToUV(index, _MainTex_TexelSize);
					float4 position = tex2D(_MainTex, uv );
					position = mul(unity_ObjectToWorld, position);
					position *= _Scale;
					position -= _Offset;
					position.xy = rotate2(position.xy,_Rotation.z);
					position.xz = rotate2(position.xz,_Rotation.y);
					position.yz = rotate2(position.yz,_Rotation.x);
					resat = position;
				}

				float4 compute = float4(0, 0, 0, 1);
				speed = _Speed * (unity_DeltaTime.x / 100.0f);
				UNITY_BRANCH
				if (i.texcoord.y > .5f) {
					compute = CalculateTrajectory(i);
				}
				//compute position change.
				else {
					float4 position = tex2D(_Buffer, i.texcoord);
					float4 trajectory = tex2D(_Buffer, float2(i.texcoord.x, i.texcoord.y + .5f));
					position.xyz += trajectory.xyz * speed;
					compute = position;
				}
				
				float4 col = lerp(compute, resat, _Reset*_Reset*_Reset);
				if (isnan(col.x)) {
					resat = 0;
				}
				if (isnan(col.y)) {
					resat = 0;
				}
				if (isnan(col.z)) {
					resat = 0;
				}
				if (isnan(col.w)) {
					resat = 0;
				}

                return col;
            }
            ENDCG
        }
    }
}
