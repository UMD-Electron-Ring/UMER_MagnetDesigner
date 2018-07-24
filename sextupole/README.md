# Description

Easily generate and analyze sextupole printed circuit board designs for particle accelerator nonlinear optics.

# Dependencies

- [Python 3](https://www.python.org/downloads/) (tested with 3.6 and 3.7)
- [NumPy](https://pypi.org/project/numpy/) (tested with 1.12.1 and 1.15.0)
- [Matplotlib](https://matplotlib.org/users/installing.html) (tested with 2.2.2)
- [Octave](https://www.gnu.org/software/octave/download.html) (tested with 4.4.0). Matlab could also work but you'd need
to modify the `runall` scripts.
- (Optional) [Autodesk EAGLE](https://www.autodesk.com/products/eagle/free-download) to manually
edit PCBs (tested with 8.7.1, 9.1.0, and 9.1.1)


# How To
### UMER PCB spacing
To test a range of PCB spacing values for UMER, run `runall.cmd` on Windows or `runall.sh` on Mac or Linux.
To run these scripts you need to cd to this folder in a terminal or command line, then run
```
runall.cmd [min_spacing] [max_spacing] [spacing_step] [design radius]
```
on Windows or
```
./runall.sh [min_spacing] [max_spacing] [spacing_step] [design radius]
```
on Mac/Linux. The spacing values are arbitrary unitless, usually around 1. I'd recommend playing around with spacing
values, using the [non-batched version](..) to generate files and Eagle to view them, to get a feel for what the 
values mean. The design radius, which is in millimeters, determines the PCB width- the magnet will have a width equal
to half of the circumference of the circle defined by the design radius. All values generated are per amp.
### Everything else
If you're designing for a different accelerator or doing something other than testing spacing values, check the
documentation and inline comments on the python code for more info. `convert_to_magli` has methods to covert a few
types of file into magli's `.scr` file format. `magli_batch_utils` has methods for doing things with a large number
of `.scr` files. `single_magnet_analysis` is for when you've narrowed it down to a single `.scr` file, and can analyze
how the strength of the magnet changes along the axis and visualize its magnetic or force field, either as a static
image or a really cool animation!
