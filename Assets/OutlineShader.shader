Shader "Tutorial/Outline"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
	_Color ("Main Color", Color) = (1,1,1,1)
	_OutlineColor ("Outline Color", Color) = (0,0,0,1)
	_OutlineThickness ("Outline Thickness", Range(0.0, 1.0)) = 0.5
    }
    CGINCLUDE
    #include "UnityCG.cginc"

    struct appdata
    {
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float2 uv : TEXCOORD0;
    };

    struct v2f
    {
	float4 pos : POSITION;
	float4 color : COLOR;
	float3 normal : NORMAL;
	float2 uv : TEXCOORD0;
    };
    ENDCG
    SubShader
    {
	Tags { "RenderType" = "Opaque" }
        Pass //actual outline
        {
		Cull Front
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag

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

	Pass //Regular Render
	{
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		
		float4 _Color;
		sampler2D _MainTex;

		v2f vert (appdata v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv = v.uv;
			o.normal = UnityObjectToWorldNormal(v.normal);
			o.color = _Color;
			return o;
		}

		fixed4 frag (v2f i) : SV_Target {
			fixed4 pixelColor = tex2D(_MainTex, i.uv);
			return pixelColor * _Color;
		}
		ENDCG	
	}
    }
}
