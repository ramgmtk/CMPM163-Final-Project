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
	Tags { "Queue" = "Transparent" }
        Pass //actual outline
        {
		Tags { "LightMode" = "Always" }
		ZWrite Off //stop writing to depth buffer
		//Cull Off
		//ZTest Always
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag

		float4 _OutlineColor;
   		float _OutlineThickness;

    		v2f vert(appdata v)
    		{
			//v.vertex.xyz *= _OutlineThickness;
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.normal = UnityObjectToWorldNormal(v.normal);

			//credit for code below
			//http://wiki.unity3d.com/index.php/Silhouette-Outlined_Diffuse
			float3 norm   = mul ((float3x3)UNITY_MATRIX_IT_MV, v.normal);
			float2 offset = TransformViewToProjection(norm.xy);
			o.pos.xy += offset * o.pos.z * _OutlineThickness;

			o.color = _OutlineColor;
			o.uv = v.uv;
			return o;
    		}
		
		half4 frag(v2f i) : COLOR
		{
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
