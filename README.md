# Voxelorama
A free and open source extension for [Pixelorama](https://github.com/Orama-Interactive/Pixelorama) that generates 3D voxel art out of 2D pixel art.

![Made with Voxelorama](https://user-images.githubusercontent.com/35376950/185218214-c8356f86-00ed-4f39-b0f8-458a29d0061b.png)

If you wish to support development of this project, please consider becoming a Patron!

[![Become a Patron!](https://c5.patreon.com/external/logo/become_a_patron_button.png)](https://patreon.com/OramaInteractive)

## Download instructions
You can download the latest .pck from [Releases](https://github.com/Orama-Interactive/VoxeloramaExtension/releases). Alternatively, you can simply clone the repository, open the project in Godot 4.1 and export a .pck file, and load it into Pixelorama. Warning, the export .pck filename MUST be "Voxelorama.pck", otherwise it will not work.

To load the .pck to Pixelorama, you can either drag and drop it, or go to the Edit menu, Preferences, Extensions and click on "Add Extension". Make sure to enable it as well, again from the Preferences. Voxelorama currently requires Pixelorama v1.0 and above.

Note that Voxelorama is still in Early Access and is not recommended for production yet, so use at your own risk. Feedback and contributions are welcome, of course!

## Current features
- Convert your pixel art into voxel art. Each pixel is converted to one voxel of the same color.
- Export the generated models as .obj files, with more file types planned for the future.
- Each layer has a different depth.
- A depth tool that lets you set the depth value for each individual pixel that will be converted into a voxel. Pixels with larger depth values will be converted to voxels with more depth than those with smaller depth values.
- No color and size restrictions. However, keep in mind that the model generation and file export will be considerably slow for large images.
- A "merge frames" option that merges the cels of all frames into one. This is useful for drawing different parts of each layer in different places, and during mesh generation have them automatically merge.
- Optimized mesh generation. To reduce the amount of triangles, neighboring cubes are combined into a single 3D rectangle. So for example, a 64x64 filled image will be converted into one big cube instead of smaller 64x64 cubes.
- The UV texture is essentially the sprite itself, and each layer has a different UV texture. In the future we could allow for more traditional UV texture options as well.
