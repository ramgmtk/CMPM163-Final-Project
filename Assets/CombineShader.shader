Shader "Tutorial/Combine"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "red" {}
	_Color ("Main Color", Color) = (1,1,1,1)
	_OutlineColor ("Outline Color", Color) = (0,0,0,1)
	_OutlineThickness ("Outline Thickness", Range(0.0, 1.0)) = 0.5
	_Hatch0("Hatch 0", 2D) = "white" {}
	_Hatch1("Hatch 1", 2D) = "white" {}
    }
    CGINCLUDE
    #include "UnityCG.cginc"

    struct appdata
    {
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float2 uv : TEXCOORD0;
    };	

    ENDCG
    SubShader
    {
	Tags { "RenderType" = "Opaque" }
	LOD 100
        Pass //actual outline
        {
		Cull Front
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag

		struct v2f
    		{
			float4 pos : POSITION;
			float4 color : COLOR;
			float3 normal : NORMAL;
			float2 uv : TEXCOORD0;
    		};

		float _OutlineThickness;
		float4 _OutlineColor;

		
		//credit for code to
		//Doug valenta https://www.videopoetics.com/tutorials/pixel-perfect-outline-shaders-unity/
		v2f vert(appdata v) {
			v2f o;
			o.normal = UnityObjectToWorldNormal(v.normal);
			v.vertex.xyz += v.normal * _OutlineThickness;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.color = _OutlineColor;
			o.uv = v.uv;
			return o;
		}

		fixed4 frag(v2f i) : SV_TARGET {
			return i.color;
		}
		ENDCG   
        }

	Pass
	{
            // apply directional light and lightmaps to shader
		Tags{ "LightMode" = "ForwardBase" }

		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag

		struct v2f
		{
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD0;
			float3 nrm : TEXCOORD1;
			float3 wPos : TEXCOORD2;
		};

		sampler2D _MainTex;
		float4 _MainTex_ST;

		sampler2D _Hatch0;
		sampler2D _Hatch1;
		float4 _LightColor0;
			
		v2f vert (appdata v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv = v.uv * _MainTex_ST.xy + _MainTex_ST.zw;
			o.nrm = mul(float4(v.normal, 0.0), unity_WorldToObject).xyz;
			o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
			return o;
		}


		//this blends between two samples of the texture, to allow for tiling the texture when you zoom in. 
		//the floored_log_dist selects powers of two based on your current distance.
		//I added a min to uv_scale because it looks awful when it tries to select less of the texture when you're far away
		//also likely too expensive to do unless you really need it. 

		// Only took the shading technique from reference:
		// http://kylehalladay.com/blog/tutorial/2017/02/21/Pencil-Sketch-Effect.html
		fixed3 Magic(float2 _uv, half _intensity, float _dist) {
			float log2_dist = log2(_dist);
			float uv_blend = abs(frac(log2_dist * 0.5) * 2.0 - 1.0);

			half3 overbright = max(0, _intensity - 1.0);
			half3 weightsA = saturate((_intensity * 6.0) + half3(-0, -1, -2));
			half3 weightsB = saturate((_intensity * 6.0) + half3(-3, -4, -5));

			weightsA.xy -= weightsA.yz;
			weightsA.z -= weightsB.x;
			weightsB.xy -= weightsB.yz;

			half3 hatch0 = tex2D(_Hatch0, _uv).rgb * weightsA;
			if(weightsA.g == 0) return 1 - tex2D(_Hatch0, _uv).rgb;
			return fixed3(0,0,0);
		}
			
		fixed4 frag (v2f i) : SV_Target {
			fixed4 color = tex2D(_MainTex, i.uv);
			fixed3 diffuse = color.rgb * _LightColor0.rgb * dot(_WorldSpaceLightPos0, normalize(i.nrm));

			fixed intensity = dot(diffuse, fixed3(0.2326, 0.7152, 0.0722));

			//color.rgb = HatchingConstantScale(i.uv * 3, intensity, distance(_WorldSpaceCameraPos.xyz, i.wPos) * unity_CameraInvProjection[0][0]);
			color.rgb -= Magic(i.uv * 3, intensity, distance(_WorldSpaceCameraPos.xyz, i.wPos) * unity_CameraInvProjection[0][0]);

			return color;
		}
		ENDCG
	}
    }
}
