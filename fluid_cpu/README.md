# Fluid Simulation - CPU (Default / Java2D)

This sketch uses the **default renderer**, which runs entirely on the CPU.

## How to compare

1. Run this sketch (`fluid_cpu`)
2. Run `fluid_gpu` in another window
3. Compare the FPS displayed in each

## Expected results

With 8000 particles:
- **CPU (default)**: typically 10-30 FPS (varies by machine)
- **GPU (P2D)**: typically 60+ FPS

## The difference

```java
size(800, 600);        // CPU - uses Java2D software rendering
size(800, 600, P2D);   // GPU - uses OpenGL shaders
```

The CPU draws shapes one at a time. The GPU can process thousands in parallel.

## Try it

- Change `numParticles` to 2000, 8000, 20000 and observe how each renderer scales
- Click and drag to interact with the particles
