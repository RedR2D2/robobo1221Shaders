const int shadowMapResolution = 2048;
const float rShadowMapResolution = 1.0 / float(shadowMapResolution);
const float shadowDistance = 120.0;

#define torchIlluminance 800.0
#define torchColor (blackbody(2700.0) * torchIlluminance)

#define COLOURED_SHADOWS