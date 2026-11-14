# Voxel Lighting

Directional, occlusion-aware lighting for voxel worlds. 

## Problem

Standard Minecraft-style flood fill lighting is cheap and fast, but has two visual flaws:

- **Shape.** Light drops by 1 (or some fixed value) per grid step, so a diamond shape is created rather than a circular one.
- **Direction.** Light has no direction, so it simply bends around corners unnaturally.

## Goal

We seek to answer the question: can voxel lighting be directional and occlusion-aware while keeping incremental updates as cheap as flood fill?

## Current Approach

- **Direct light by visibility.** For each light, find the cells within its radius that can see it (shadowcasting family). Lit cells get `level = max - distance`, using straight-line distance.
- **Indirect light by flood fill.** A short-range flood fill seeded from lit cells approximates bounce light around corners.
- **Hybrid.** Flood fill everywhere as the base layer. Directional correction near the camera only.
- **Ground truth.** Ray traced reference lighting for measuring error.

## Rendering

- Light values are necessarily stored separately from meshes. Engine uses a custom greedy-meshing technique which merges adjacent faces.
- Light instead lives in a 3D clipmap textures with wrapped (toroidal) addressing, centered on the camera.
- Faces sample light from the air cell in front of them, in the fragment shader.
- Textures store light levels (RGB block light + sky light channel). Light levels turned into brightness at render time.
- Light is computed on the CPU in the engine's thread pool. (optional: compute shaders)

Note: built with my engine, [Strata](https://github.com/remyj4556/Strata-Voxel-Engine), in mind. Final product will be as engine-agnostic as possible, working with any that fit the above critera.

## Metrics

Each method is compared on:

- Error against ray traced ground truth
- Full rebuild time
- Time to update after a single block change
- Memory per voxel

## Methods compared

| Method | Status |
|---|---|
| Flood fill (Manhattan) | Planned |
| Flood fill (straight-line distance) | Planned |
| Light Propagation Volumes (LPV) style | Planned |
| 3D shadowcasting | Planned |
| Visibility + indirect hybrid (own method) | Planned |


Presently working on a 2D prototype first to test method viability.


## References

- Kaplanyan, *Light Propagation Volumes* (Crytek)
- Sannikov, *Radiance Cascades*
- Recursive shadowcasting (roguelike field of view)
- Minecraft Java Edition lighting model
