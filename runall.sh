#!/usr/bin/env bash
octave --eval "optimize($1, $2, $3)"
python3 -c "from convert_to_magli import *; batch_scr_to_magli_assym('./BoardMacros/BoardMacroLeft_', './BoardMacros/BoardMacroRight_', './Specifications/LeftRight_', $1, $2, $3, 1, 30, 40)"
python3 -c "from magli_batch_utils import *; make_batch_file('DoubleLeft_', '/home/noah/Documents/UMER_MagnetDesigner/Specifications/batch_', $1, $2, $3,
                ('calc(0, 0, -0.006, 0, 0, 0.000012, 1000,, across_x_',
                 'calc(0, 1, 0, -0.006, 0, 0.000012, 1000,, across_y_'));print(find_most_nth_poly('/home/noah/Documents/UMER_MagnetDesigner/Specifications/across_x_', 2, 'x', $1, $2, $3))"
