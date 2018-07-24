import math
import numpy as np
import numpy.polynomial.polynomial as poly
import matplotlib.pyplot as plt
import subprocess
import os

# The format of the .bat file that you plan on running in Magli is as so:
# load(qmag83.spc, );
# calc(0, 2, .001, 0, -.1, .001, 200,, testl.txt);
# calc(0, 2, .002, 0, -.1, .001, 200,, test2.txt);
# and so on ...
#
# Translated:
# load(.spc file which is a prototype of the magnet for Magli to test)
# calc(rectangular coordinate system is 0, varying along an axis (2 for z, 0 for x, 1 for y), starting point x,
# starting point y, starting point z, step size, # steps,, name of output tile.txt);
#
# The MagLi program, batch files, and .spc files all need to go in the same directory.


# Mapping each variable to the column in the MagLi output file it's in. The output map can change depending on the field
INPUT_COLUMN_MAP = {"x": 0, "y": 1, "z": 2}
OUTPUT_COLUMN_MAP = {"x": 4, "y": 4, "z": 3}


def run_tests_batched(in_file_prefix, out_file_prefix, min_a, max_a, step, tests_prefix):
    """
    Runs MagLi commands on any number of .spc files with names ending in "a.spc", where a is a number, and saves the
    output as text files. This should work on MacOS, Windows, and Linux but has only been tested on Linux.
    :param in_file_prefix: The prefix of where all the .spc files are. This should include the filename up to a,
    but not the filepath.
    :param out_file_prefix: The prefix for all the .bat files to be created. This should not contain the filepath.
    :param min_a: The minimum value of a.
    :param max_a: The maximum value of a.
    :param step: How much to change a by to get from one file to the next.
    :param tests_prefix: A list of the magli commands to run on each .spc file, but with each only up to the end of
    the filename because a will appended to the end.
    """
    # The directory we want the output files to go in.
    folder = "Specifications"
    command = ""
    if os.name == "posix":
        command += "#!/bin/bash\n"
    command += "cd " + folder + "\n"
    for a in np.arange(min_a, max_a, step):
        a_str = "{0:g}".format(a)
        out_filename = out_file_prefix + a_str
        with open(os.path.join(folder, out_filename + ".bat"), "w") as f:
            f.write("load(" + in_file_prefix + a_str + ".spc,);\n")
            # Add the a value to the end of each test output filename to avoid overwriting
            for test in tests_prefix:
                f.write(test + a_str + ".txt);\n")
            # Add each .bat script to the script
            if os.name == "posix":
                command += "./mag"
            else:
                command += "MagLi.exe"
            command += " -bat " + out_filename + ".bat" + "\n"
    if os.name == "posix":
        command_name = out_file_prefix + "all.sh"
    else:
        command_name = out_file_prefix + "all.cmd"
    f = open(os.path.join(folder, command_name), "w")
    f.write(command)
    f.close()
    if os.name == "posix":
        # Allow executing as a script
        subprocess.Popen(("chmod a+x " + command_name).split(), stdout=subprocess.PIPE, cwd=folder)
    # MagLi batching only allows one .spc file to be loaded per .bat file, so we have to make a Unix script to run
    # the batch file for each .spc.
    subprocess.call(os.path.join(folder, command_name))


def read_batch_output(filename):
    """
    Read in a magli output file to a list.
    :param filename: The name of the file to read.
    :return: A 6xn list where n is the number of data points in the given magli file.
    """
    to_ret = []
    with open(filename, "r") as f:
        # The file starts with the headers then a blank line and we don't care about either.
        f.readline()
        f.readline()
        skip = False
        for line in f:
            # Every other line is blank so we skip it.
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


def find_most_nth_magnet(in_file_prefix, n_poles, axis, min_a, max_a, step):
    """
    Finds which magnet has the purest n-pole field and which has the strongest, given a bunch of Magli output files.
    :param in_file_prefix: The prefix of where all the data files are. This should include the filename up to a,
    complete with filepath.
    :param n_poles: The number of poles of the component you want to test for strength and purity.
    :param axis: The axis the data was collected along, either 'x', 'y', or 'z'.
    :param min_a: The minimum value of a.
    :param max_a: The maximum value of a.
    :param step: How much to change a by to get from one file to the next.
    :return: A dictionary mapping each a value to the R^2 of a polynomial fit of the data from that a value.
    """
    # Calculate polynomial degree from number of poles.
    degree = int(n_poles / 2. - 1.)
    a_to_r_squared = {}
    a_to_strength = {}
    # Placeholder
    max_r_squared_a = -1
    max_strength_a = -1
    for a in np.arange(min_a, max_a, step):
        # Round to avoid floating point errors
        a = round(a, -round(math.log(step, 10)))
        a_str = "{0:g}".format(a)
        data = read_batch_output(in_file_prefix + a_str + ".txt")
        x = []
        y = []
        for line in data:
            x.append(line[INPUT_COLUMN_MAP.get(axis)])
            y.append(line[OUTPUT_COLUMN_MAP.get(axis)])
        # Convert to np arrays
        x = np.array(x)
        y = np.array(y)
        # Fit the function with full=True to get the fit and error
        poly_fit = poly.polyfit(x, y, degree, full=True)
        # Get the outputs
        poly_function = poly.polyval(x, poly_fit[0])
        # Calculate R^2
        a_to_r_squared[a] = 1. - (poly_fit[1][0][0] / sum(poly_function ** 2))
        # Strength is equal to the nth derivative
        a_to_strength[a] = poly.polyder(poly_fit[0], degree)[0]

        # Check maximums
        if max_r_squared_a == -1 or a_to_r_squared[a] > a_to_r_squared[max_r_squared_a]:
            max_r_squared_a = a
        if max_strength_a == -1 or abs(a_to_strength[a]) > abs(a_to_strength[max_strength_a]):
            max_strength_a = a
    print("Maximum R^2 was " + str(a_to_r_squared[max_r_squared_a]) + " at a = " + str(max_r_squared_a))
    print("Maximum strength was " + str(a_to_strength[max_strength_a]) + " at a = " + str(max_strength_a))

    # Plot output
    plt.plot(a_to_r_squared.keys(), a_to_r_squared.values())
    plt.title("Effect of A on $R^2$ of " + str(degree) + " degree polynomial fit")
    plt.xlabel("A")
    plt.ylabel("$R^2$")
    plt.show()
    plt.plot(a_to_strength.keys(), a_to_strength.values())
    plt.title("Effect of A on " + str(n_poles) + "-pole strength")
    plt.xlabel("A")
    plt.ylabel("Strength ($\\frac{T}{m^" + str(degree) + "}$)")
    plt.show()
    return a_to_r_squared
