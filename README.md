# Whitted Raytracer (x86_64 Assembly)

This project is a minimal Whitted-style raytracer written entirely in x86_64 NASM for Linux. It parses a simple scene description from **stdin** and writes a PNG image to **stdout** using libpng's simplified API.

## Features

- Spheres and axis-aligned cubes
- Point lights with diffuse + specular shading
- Procedural textures (solid, checker, stripe)
- Recursive reflections (Whitted)
- PNG output to stdout

## Build

Dependencies: `nasm`, `gcc`, `libpng`, `zlib`.

```sh
make
```

## Run

```sh
./raytrace < scenes/sample.scene > out.png
```

## Scene format

Whitespace-separated tokens (comments start with `#`). All values are numeric except texture type.

```
image <width> <height>
camera <px> <py> <pz> <lx> <ly> <lz> <upx> <upy> <upz> <fov_deg>
ambient <r> <g> <b>
background <r> <g> <b>
maxdepth <n>

material <id>
  <diff_r> <diff_g> <diff_b>
  <spec_r> <spec_g> <spec_b>
  <shininess>
  <reflect>
  <texture_type>
  [texture params...]

sphere <cx> <cy> <cz> <radius> <material_id>
cube <minx> <miny> <minz> <maxx> <maxy> <maxz> <material_id>
light <px> <py> <pz> <r> <g> <b> <intensity>
```

Texture params:

- `solid` — no extra params (uses diffuse color)
- `checker <scale> <r1> <g1> <b1> <r2> <g2> <b2>`
- `stripe  <scale> <r1> <g1> <b1> <r2> <g2> <b2>`

## Notes

- Output is always 8-bit RGB PNG.
- The renderer expects reasonable numeric input (no extensive validation).
