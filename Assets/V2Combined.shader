Shader "Custom/V2Combined"
{
    Properties
    {
	_Color ("Main Color", Color) = (1,1,1,1)
	_OutlineColor ("Outline Color", Color) = (0,0,0,1)
	_OutlineThickness ("Outline Thickness", Range(0.0, 1.0)) = 0.5

	_TintColor("Tint", Color) = (0, 0, 0, 1)
	_WaterTex("Texture", 2D) = "white" {}
	[HDR] _Emission("Emission", color) = (0,0,0)
	_HalftonePattern("Halftone Pattern", 2D) = "white" {}

	_Hatch("Hatch", 2D) = "white" {}
	_BeginHatchFade ("Begin Hatch Fade In", Range(0.0, 1.0)) = 0.5
	_EndHatchFade ("End Hatch Fade In", Range(0.0, 1.0)) = 0.3
	_HatchScale ("Hatch Scale", Float) = 10.0
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
	Tags { "RenderType" = "Opaque"}
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

	//Water color shader
	Tags { "Queue" = "Geometry"}
	CGPROGRAM

	#pragma surface surf Halftone fullforwardshadows
	#pragma target 3.0

	//generic properties
	sampler2D _WaterTex;
	fixed4 _TintColor;
	half3 _Emission;

	//shading properties
	sampler2D _HalftonePattern;
	float4 _HalftonePattern_ST;

	sampler2D _Hatch;
	float _BeginHatchFade;
	float _EndHatchFade;
	float _HatchScale;

	struct HalftoneSurfaceOutput
	{
		fixed3 Albedo;
		float2 ScreenPos;
		half3 Emission;
		fixed Alpha;
		fixed3 Normal;
	};
		
	//maps texture value
	float map(float input, float inMin, float inMax, float outMin,  float outMax)
	{
			// inverse lerp with input range
			float relativeValue = (input - inMin) / (inMax - inMin);

			// lerp with output range
			return lerp(outMin, outMax, relativeValue);
	}

	// lighting function
	float4 LightingHalftone(HalftoneSurfaceOutput s, float3 lightDir, float atten)
	{
		// calculate how much normal points towards light
		float towardsLight = dot(s.Normal, lightDir);

		// constrain values between 0 and 1 
		towardsLight = towardsLight * 0.5 + 0.5;

		// combine shadow and light and force constraint between 0 and 1
		float lightIntensity = saturate(towardsLight * atten).r;

		// calculate halftone value
        float halftoneValue = tex2D(_HalftonePattern, s.ScreenPos).r;

		halftoneValue = map(halftoneValue, 0, 1, 0, 1);

		// create binary division between light and shadow
		float halftoneChange = fwidth(halftoneValue) * 0.25;

		// use inverse of halftone values to create clouding effect 
		lightIntensity = smoothstep(1 - (halftoneValue - halftoneChange), (halftoneValue - halftoneChange) * 2, lightIntensity * 1.25);

		//combine the color
		float4 col;

		// calculate color of the light amplified by light intensity to create "light" spots in clouding
		col.rgb = lightIntensity * s.Albedo * _LightColor0.rgb * 1.5;

		// Adding the hatching effect here
		float lightMul = (lightIntensity-_EndHatchFade)/(_BeginHatchFade-_EndHatchFade);
		float useHatch = max(0, sign(_BeginHatchFade - lightIntensity));
		float useFadeHatch = max(0, sign(lightIntensity - _EndHatchFade));
		float3 fadeHatch = useFadeHatch * clamp(tex2D(_Hatch, s.ScreenPos * _HatchScale).rgb + lightMul, 0, 1);
		float3 fullHatch = (1 - useFadeHatch) * tex2D(_Hatch, s.ScreenPos * _HatchScale).rgb;
		col.rgb *= (1 - useHatch) + useHatch * (fadeHatch + fullHatch);

		//in case we want to make the shader transparent in the future - irrelevant right now
		col.a = s.Alpha;

		return col;
	}
		

	struct Input
	{
		float2 uv_MainTex;
		float4 screenPos;
	};

	// surface shader function; sets lighting function parameters
	void surf(Input i, inout HalftoneSurfaceOutput o)
	{
		//set surface colors
		fixed4 col = tex2D(_WaterTex, i.uv_MainTex);
		col *= _TintColor;
		o.Albedo = col.rgb;

		o.Emission = _Emission;

            	//setup screenspace UVs for lighing function
		float aspect = _ScreenParams.x / _ScreenParams.y;
		o.ScreenPos = i.screenPos.xy / i.screenPos.w;
		o.ScreenPos = TRANSFORM_TEX(o.ScreenPos, _HalftonePattern);
		o.ScreenPos.x = o.ScreenPos.x * aspect;
	}

	ENDCG

    }
}
