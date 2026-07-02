# Fluid Simulation - GPU (P2D / OpenGL)

This sketch uses the **P2D renderer**, which is GPU-accelerated via OpenGL.

## How to compare

1. Run this sketch (`fluid_gpu`)
2. Run `fluid_cpu` in another window
3. Compare the FPS displayed in each

## Expected results

With 8000 particles:
- **GPU (P2D)**: typically 60+ FPS
- **CPU (default)**: typically 10-30 FPS (varies by machine)

## The difference

```java
size(800, 600, P2D);   // GPU - uses OpenGL shaders
size(800, 600);        // CPU - uses Java2D software rendering
```

The GPU can draw thousands of shapes in parallel, while the CPU draws them sequentially.

## Try it

- Change `numParticles` to 2000, 8000, 20000 and observe how each renderer scales
- Click and drag to interact with the particles
