%include "src/asm/defines.inc"

default rel

section .bss
alignb 16

global materials
materials: resb MAT_SIZE * MAX_MATERIALS

global material_count
material_count: resd 1

alignb 16
global objects
objects: resb OBJ_SIZE * MAX_OBJECTS

global object_count
object_count: resd 1

alignb 16
global lights
lights: resb LIGHT_SIZE * MAX_LIGHTS

global light_count
light_count: resd 1

alignb 16
global camera_pos
camera_pos: resq 3

global camera_lookat
camera_lookat: resq 3

global camera_up
camera_up: resq 3

global camera_fov
camera_fov: resq 1

global image_width
image_width: resd 1

global image_height
image_height: resd 1

global max_depth
max_depth: resd 1

alignb 16
global ambient_color
ambient_color: resq 3

global background_color
background_color: resq 3

alignb 16
global cam_forward
cam_forward: resq 3

global cam_right
cam_right: resq 3

global cam_true_up
cam_true_up: resq 3
