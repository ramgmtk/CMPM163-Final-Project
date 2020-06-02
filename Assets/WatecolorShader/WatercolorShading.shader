Shader "WatercolorShading"
{
	Properties
	{
		_Color("Tint", Color) = (0, 0, 0, 1)
		_MainTex("Texture", 2D) = "white" {}
		[HDR] _Emission("Emission", color) = (0,0,0)

		_HalftonePattern("Halftone Pattern", 2D) = "white" {}

	}
		SubShader {
		Tags{ "RenderType" = "Opaque" "Queue" = "Geometry"}

		CGPROGRAM

		#pragma surface surf Halftone fullforwardshadows
		#pragma target 3.0

        // generic properties
		sampler2D _MainTex;
		fixed4 _Color;
		half3 _Emission;

        // shading properties
		sampler2D _HalftonePattern;
		float4 _HalftonePattern_ST;

		// properties for calculating halftone
		struct HalftoneSurfaceOutput
		{
			fixed3 Albedo;
			float2 ScreenPos;
			half3 Emission;
			fixed Alpha;
			fixed3 Normal;
		};

        // maps texture value 
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
			fixed4 col = tex2D(_MainTex, i.uv_MainTex);
			col *= _Color;
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
		FallBack "Standard"
}