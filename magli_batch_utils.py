import math

import numpy as np
import numpy.polynomial.polynomial as poly
import matplotlib.pyplot as plt
import subprocess

# The format of the .bat file that you plan on running in Maglinux is as so:
# load(qmag83.spc, );
# calc(0, 2, .001, 0, -.1, .001, 200,, testl.txt);
# calc(0, 2, .002, 0, -.1, .001, 200,, test2.txt);
# and so on ...
#
# Translated:
# load(.spc file which is a prototype of the magnet for Maglinux to test)
# calc(rectangular coordinate system is 0, varying along an axis (2 for z, 0 for x, 1 for y), starting point x,
# starting point y, starting point z, step size, # steps,, name of output tile.txt);
#
# MagLi is dumb so the batch file needs to go in the same directory as the spec files.

X_AXIS_MAP = {"x": 0, "y": 1, "z": 2}
Y_AXIS_MAP = {"x": 4, "y": 4, "z": 3}


def make_batch_file(in_file_prefix, out_file_prefix, min_a, max_a, step, tests_prefix):
    command = "#!/bin/bash\n" \
              "cd "+"/".join(out_file_prefix.split("/")[:-1])+"\n"
    for a in np.arange(min_a, max_a + step, step):
        a_str = "{0:g}".format(a)
        with open(out_file_prefix + a_str + ".bat", "w") as f:
            f.write("load(" + in_file_prefix + a_str + ".spc,);\n")
            for test in tests_prefix:
                f.write(test + a_str + ".txt);\n")
            command += "./mag -bat " + f.name + "\n"
    f = open(out_file_prefix + "all.sh", "w")
    f.write(command)
    f.close()
    subprocess.call(out_file_prefix + "all.sh")


def read_batch_output(filename):
    to_ret = []
    with open(filename, "r") as f:
        f.readline()
        f.readline()
        skip = False
        for line in f:
            if skip:
                skip = False
            else:
                line_list = []
                for entry in line.split():
                    line_list.append(float(entry))
                if not len(line_list) == 0:
                    to_ret.append(line_list)
                skip = True
    return to_ret


def find_most_nth_poly(in_file_prefix, degree, axis, min_a, max_a, step):
    a_to_r_squared = {}
    a_to_strength = {}
    max_r_squared_a = -1
    max_strength_a = -1
    for a in np.arange(min_a, max_a + step, step):
        a = round(a, -round(math.log(step, 10)))
        a_str = "{0:g}".format(a)
        data = read_batch_output(in_file_prefix + a_str + ".txt")
        x = []
        y = []
        for line in data:
            x.append(line[X_AXIS_MAP.get(axis)])
            y.append(line[Y_AXIS_MAP.get(axis)])
        x = np.array(x)
        y = np.array(y)
        poly_fit = poly.polyfit(x, y, degree, full=True)
        poly_function = poly.polyval(x, poly.polyfit(x, y, degree))
        a_to_r_squared[a] = 1 - (poly_fit[1][0][0] / sum(poly_function**2))
        a_to_strength[a] = poly_fit[0][2] * 2.0
        if a / 0.1 == int(a / 0.1):
            plt.plot(x, y, "r.")
            plt.plot(x, poly_function)
            plt.ylabel("By")
            plt.xlabel("X (m)")
            plt.title("a = "+str(a))
            plt.show()
        if max_r_squared_a == -1 or a_to_r_squared[a] > a_to_r_squared[max_r_squared_a]:
            max_r_squared_a = a
        if max_strength_a == -1 or abs(a_to_strength[a]) > abs(a_to_strength[max_strength_a]):
            max_strength_a = a
    print("Maximum R^2 was "+str(a_to_r_squared[max_r_squared_a])+" at a = "+str(max_r_squared_a))
    print("Maximum strength was "+str(a_to_strength[max_strength_a])+" at a = "+str(max_strength_a))
    plt.plot(a_to_r_squared.keys(), a_to_r_squared.values())
    plt.show()
    plt.plot(a_to_strength.keys(), a_to_strength.values())
    plt.show()
    return a_to_r_squared


# make_batch_file("DoubleLeft_", "/home/noah/Documents/UMER_MagnetDesigner/Specifications/batch_", 0.9, 1., 0.001,
#                 ("calc(0, 0, -0.012, 0, 0, 0.000024, 1000,, across_x_",
#                  "calc(0, 1, 0, -0.012, 0, 0.000024, 1000,, across_y_"))
# print(find_most_nth_poly("/home/noah/Documents/UMER_MagnetDesigner/Specifications/across_x_", 2, "x", 0.9, 1., 0.001))
