#!/usr/bin/env bash
mkdir -p BoardMacros
mkdir  -p PCBData
octave --eval "optimize($1, $2, $3, $4)"
python3 -c "from convert_to_magli import *; batch_scr_to_magli_asymmetric('BoardMacros/BoardMacroLeft_', 'BoardMacros/BoardMacroRight_', 'Specifications/LeftRight_', $1, $2, $3, 1, 30, 40)"
python3 -c "from magli_batch_utils import *; run_tests_batched('LeftRight_', 'batch_', $1, $2, $3,
                ('calc(0, 0, -0.006, 0, 0, 0.000012, 1000,, across_x_',
                 'calc(0, 1, 0, -0.006, 0, 0.000012, 1000,, across_y_'));print(find_most_nth_magnet('Specifications/across_x_', 6, 'x', $1, $2, $3))"
