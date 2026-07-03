# Fluid Simulation - GPU (P2D / OpenGL)

This sketch uses the **P2D renderer**, which is GPU-accelerated via OpenGL.

## How to run

1. Open `../imc4_processing_examples/imc4_processing_examples.pde` in Processing.
2. Run the launcher.
3. Click **fluid GPU** to open the simulation in a new window.
4. Use the **particles** slider (ControlP5) to change particle count (2000-50000).
5. Open **fluid CPU** from the same launcher to compare side by side.

You can also open `fluid_gpu.pde` directly in Processing.

## Expected results

With 20000 particles:
- **GPU (P2D)**: typically 60+ FPS
- **CPU (default)**: typically 10-30 FPS (varies by machine)

## The difference

```java
size(800, 600, P2D);   // GPU - uses OpenGL shaders
size(800, 600);        // CPU - uses Java2D software rendering
```

The GPU can draw thousands of shapes in parallel, while the CPU draws them sequentially.

## Try it

- Drag the particles slider and watch FPS change
- Click and drag to interact with the particles

Implementation code: `fluid_gpu.pde`
