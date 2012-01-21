/*
 * MMD Shader for Unity
 *
 * Copyright 2012 Masataka SUMI, Takahiro INOUE
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        http://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */
float4 _Color;
float  _Opacity;
float4 _AmbColor;
float4 _SpecularColor;
float _Shininess;
sampler2D _MainTex;
sampler2D _ToonTex;
sampler2D _SphereAddTex;
sampler2D _SphereMulTex;

struct EditorSurfaceOutput
{
	half3 Albedo;
	half3 Normal;
	half3 Emission;
	half3 Gloss;
	half Specular;
	half Alpha;
	half4 Custom;
};

inline half4 LightingMMD (EditorSurfaceOutput s, half3 lightDir, half3 viewDir, half atten)
{
	half3 h = normalize (lightDir + viewDir);

	half diff = max (0, dot ( lightDir, s.Normal ));

	float nh = max (0, dot (s.Normal, h));
	float spec = pow (nh, s.Specular*128.0);

	half4 res;
	res.rgb = _LightColor0.rgb * diff;
	res.w = spec * Luminance (_LightColor0.rgb);
	res *= atten * 2.0;
	half4 light = res;

	// Specular
	float specularStrength = s.Specular;
	float dirDotNormalHalf = max(0, dot(s.Normal, normalize(lightDir + viewDir)));
	float dirSpecularWeight = pow( dirDotNormalHalf, _Shininess );
	float4 dirSpecular = _SpecularColor * _LightColor0 * dirSpecularWeight;
	// Light
	float lightStrength = (1.0 + dot(lightDir, s.Normal)) / 2.0;
	float lightColor = _LightColor0 * lightStrength;
	// Sphere
	float2 viewNormal = mul( UNITY_MATRIX_MV, float4(s.Normal, 0.0) ).xy;
	float2 sphereUv = viewNormal * 0.5 + 0.5;
	float4 sphereAdd = tex2D( _SphereAddTex, sphereUv );
	float4 sphereMul = tex2D( _SphereMulTex, sphereUv );
	// ToonMap
	float4 toon = tex2D( _ToonTex, float2( specularStrength, lightStrength ) );

	// Output
	float4 color = saturate( _AmbColor + _Color * _LightColor0 );
	color *= float4(s.Albedo, 1.0); // DiffuseTex   Default:White
	color += dirSpecular;           // Specular
	color += sphereAdd;             // SphereAddTex Default:Black
	color *= sphereMul;             // SphereMulTex Default:White
	color *= toon;                  // ToonTex      Default:White
	color.a = s.Alpha;
	return color;
}

struct Input
{
	float2 uv_MainTex;
};

void surf (Input IN, inout EditorSurfaceOutput o)
{
	// Defaults
	//o.Normal = float3(0.0,0.0,1.0);
	o.Emission = 0.0;
	o.Gloss = 0.0;
	o.Specular = 0.0;
	o.Custom = 0.0;

	// UV coord Transform
	float2 uv_coord = float2( IN.uv_MainTex.x, IN.uv_MainTex.y );

	float4 tex_color = tex2D( _MainTex, uv_coord );
	o.Albedo = tex_color.rgb;
	o.Alpha = _Opacity * tex_color.a;
}
