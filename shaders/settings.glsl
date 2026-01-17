
#define SHADOWS //Shadow Settings

#define COLOR //Color correction settings.
    #define JedSliderRed 0.00 //Jed Slider [0.00 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
    #define JedSliderBlue 0.00 //Jed Slider [0.00 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
    #define JedSliderGreen 0.00 //Jed Slider [0.00 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
    #define Gray_Amount 0.00 //Gray [0.00 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]


#define LIGHTING //Lighting Settings
    #define LIGHTING_STYLE 0 // 0: Old Lighting. 1: JedLighting [0 1]
    #define TORCH_COLOR_RED 1.0 //[0.00 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
    #define TORCH_COLOR_GREEN 1.0 //[0.00 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
    #define TORCH_COLOR_BLUE 0.0 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]

#define SHADOWS
    #define FOG_ON 1 // [0 1]
    #define CUSTOM_FOG_START 10 // [5 10 15 20 25 30 35 40 45 50 55 60]
    #define CUSTOM_FOG_END   15 // [5 10 15 20 25 30 35 40 45 50 55 60 100 150 200 250 300 350 400 450 500]
    #define MAX_FOG_VALUE 1.0 // [0.0 0.25 0.5 0.75 1.0]
    #define BORDER_FOG 1 //[0 1]
    #define BORDER_FOG_START 0.75 //[0.75 0.8 0.9]
    #define USE_CUSTOM_FOG_SETTINGS 1 //[0 1]

#define WAVING_BLOCKS
    #define WAVING_GRASS
    #define WAVING_LEAVES

#define EXCLUDE_FOLIAGE

#define DEBUG_VIEW 1 //[0 1 2 3]

#define COLORED_SHADOWS 1 //0: Stained glass will cast ordinary shadows. 1: Stained glass will cast colored shadows. 2: Stained glass will not cast any shadows. [0 1 2]
#define SHADOW_BRIGHTNESS 0.75 //Light levels are multiplied by this number when the surface is in shadows [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]