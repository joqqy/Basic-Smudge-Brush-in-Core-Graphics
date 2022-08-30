# Simple implementation on how to do "smudge" and "wetbrush" etc. in Core Graphics.

## NOTE: this is not very performant, it simply illustrates the logic that goes into implementing a smudge brush. This is just a test suite I made for later implementation in Metal.

For smudging, thi example draws a starting image into a UIImage, the UIImage draws itself into the context.

For each touch, we copy a portion(the size of the brush), for the previous touch positions, from the current CGContext, crop and mask it, and then draw that into the current context with appropriate settings. The resulting image updates the UIImage.

The UIImage draws itself into the context as to update each incremental change.

To implement a production code, you would use the same basic logic (there are no rules, just do whatever fits your needs), but implement it in Metal (or any other framework that takes advantage of the GPU).

Wet brush is related to the smudge brush, with the main difference that the wet brush also hold an intrinsic color, that blends bidirectionally with paint lying on the canvas

<img src="images/screenshot3.PNG" width="350"/>
<img src="images/screenshot_wet.PNG" width="350"/>
<img src="images/screenshot4.PNG" width="350"/>
<img src="images/screenshot2.PNG" width="350"/>


