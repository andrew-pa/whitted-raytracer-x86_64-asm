%ifndef DEFINES_INC
%define DEFINES_INC 1

%define MAX_MATERIALS 32
%define MAX_OBJECTS   64
%define MAX_LIGHTS    32

%define VEC3_X 0
%define VEC3_Y 8
%define VEC3_Z 16
%define VEC3_SIZE 24

%define RAY_ORIGIN 0
%define RAY_DIR    24
%define RAY_SIZE   48

%define MAT_DIFFUSE     0
%define MAT_SPEC        24
%define MAT_SHININESS   48
%define MAT_REFLECT     56
%define MAT_TEX_TYPE    64
%define MAT_TEX_PAD     68
%define MAT_TEX_SCALE   72
%define MAT_TEX_COLOR1  80
%define MAT_TEX_COLOR2  104
%define MAT_SIZE        128

%define LIGHT_POS       0
%define LIGHT_COLOR     24
%define LIGHT_INTENSITY 48
%define LIGHT_SIZE      56

%define OBJ_TYPE        0
%define OBJ_PAD0        4
%define OBJ_MAT_INDEX   8
%define OBJ_PAD1        12
%define OBJ_SPH_CENTER  16
%define OBJ_SPH_RADIUS  40
%define OBJ_BOX_MIN     48
%define OBJ_BOX_MAX     72
%define OBJ_SIZE        96

%define HIT_T           0
%define HIT_POINT       8
%define HIT_NORMAL      32
%define HIT_MAT_INDEX   56
%define HIT_OBJ_TYPE    60
%define HIT_SIZE        64

%define TEX_SOLID   0
%define TEX_CHECKER 1
%define TEX_STRIPE  2

%define OBJ_SPHERE 0
%define OBJ_CUBE   1

%define PNG_IMAGE_VERSION 1
%define PNG_FORMAT_RGB 0x02

%define SC_NPROCESSORS_ONLN 84

%define TASK_BUF    0
%define TASK_WIDTH  8
%define TASK_HEIGHT 16
%define TASK_START  24
%define TASK_END    32
%define TASK_SIZE   40

%endif
