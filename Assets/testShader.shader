Shader "Tutorial/Basic" {
    Properties {
	_MainTex("Texture", 2D) = "white" {}
        _Color ("Main Color", Color) = (1,1,1,1)
	[HDR]
	_RimColor("Rim Color", Color) = (1,1,1,1)
	_RimAmount("Rim Amount", Range(0, 1)) = 0.716
    }
    SubShader {
        Pass {
		Tags {
			"LightMode" = "ForwardBase"
			"PassFlag" = "OnlyDirectional"
		}

		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag

		#include "UnityCG.cginc"

		struct appdata {
			float4 vertex : POSITION;
			float2 uv : TEXCOORD0;
			float3 normal: NORMAL;
		};
		
		struct v2f {
			float4 pos :  SV_POSITION;
			float2 uv : TEXCOORD0;
			float3 worldNormal : NORMAL;
			float3 viewDir : TEXCOORD1;
		};

		fixed4 _Color;
		sampler2D _MainTex;
		float4 _RimColor;
		float _RimAmount;
		
		v2f vert (appdata v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv = v.uv;
			o.worldNormal = UnityObjectToWorldNormal(v.normal);
			o.viewDir = WorldSpaceViewDir(v.vertex);
			return o;
		}

		fixed4 frag (v2f i) : SV_Target {
			float3 normal = normalize(i.worldNormal);
			float3 viewDir = normalize(i.viewDir);
			float NdotL = dot(_WorldSpaceLightPos0, normal);

			float4 rimDot = 1 - dot(viewDir, normal);
			float rimIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, rimDot);
			float4 rim = rimIntensity * _RimColor;

			fixed4 pixelColor = tex2D(_MainTex, i.uv);
			return pixelColor * _Color * (NdotL + rim);
		}
		ENDCG
        }
    }
}