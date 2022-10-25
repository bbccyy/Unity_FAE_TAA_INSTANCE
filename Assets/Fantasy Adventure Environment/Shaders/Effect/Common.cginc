////////////////////////////////////////////////////////////////////////////////
//
// 通用的一些结构和函数
//

//#include "UnityCG.cginc"

//#define MAX_INTENSITY 2.0
//#define INV_MAX_INTENSITY 0.5

//half3 EncodeColor(half3 color)
//{
//#ifdef HIGH_DYNAMIC_COLOR
//	return color * INV_MAX_INTENSITY;
//#else
//	return color;
//#endif
//}

//half3 DecodeColor(half3 color)
//{
//#ifdef HIGH_DYNAMIC_COLOR
//	return color * MAX_INTENSITY;
//#else
//	return color;
//#endif
//}

//half3 ACESFilm( half3 x )
//{
//	float a = 2.51f;
//	float b = 0.03f;
//	float c = 2.93f;
//	float d = 0.59f;
//	float e = 0.14f;
//	return saturate((x*(a*x+b))/(x*(c*x+d)+e));
//}