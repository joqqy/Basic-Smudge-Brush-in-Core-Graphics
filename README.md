# Simple implementation on how to do smudging in Core Graphics.

# Warning, this is not very performant, it simply illustrates the logic that goes into implementing a smudge brush. This is just a test suite for what we will implement in Metal.

## This example draws a starting image into an UIImage.
## For each touch, we copy a portion(the size of the brush) of the current CGContext, mask it, and then draws that into the context.
## The UIImage draws itself into the context as to update each change.
