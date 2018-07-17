import subprocess

import numpy as np

import numpy.polynomial.polynomial as poly

from magli_batch_utils import read_batch_output

import matplotlib.pyplot as plt


def strength_along_z(in_file, out_file_folder, start_z, end_z, steps, radius, along_x):
    z_step = (end_z - start_z) / steps
    r_step = radius * 2. / 1000.
    z_to_strength = {}
    with open(out_file_folder + "/batch.bat", "w") as f:
        f.write("load(" + in_file + ",);\n")
        for z in np.arange(start_z, end_z + z_step, z_step):
            z = round(z, 6)
            # calc(rectangular coordinate system is 0, varying along an axis (2 for z, 0 for x, 1 for y),
            # starting point x,
            # starting point y, starting point z, step size, # steps,, name of output tile.txt);
            if along_x:
                f.write(
                    "calc(0, 0, {0:f}, 0, {1:f}, {2:f}, 1000,, along_x_z={1:f}.txt);\n".format(-radius,  z,
                                                                                                       r_step))
            else:
                f.write(
                    "calc(0, 1, 0, {0:f}, {1:f}, {2:f}, 1000,, along_y_z={1:f}.txt);\n".format(-radius,  z,
                                                                                                       r_step))
    process = subprocess.Popen("./mag -bat batch.bat".split(), stdout=subprocess.PIPE, cwd=out_file_folder)
    output, error = process.communicate()
    print(output)
    print(error)
    for z in np.arange(start_z, end_z + z_step, z_step):
        z = round(z, 6)
        if along_x:
            data = read_batch_output(out_file_folder + "/along_x_z={0:f}.txt".format(z))
        else:
            data = read_batch_output(out_file_folder + "/along_y_z={0:f}.txt".format(z))
        r = []
        By = []
        for line in data:
            if along_x:
                r.append(line[0])
            else:
                r.append(line[1])
            By.append(line[4])
        r = np.array(r)
        By = np.array(By)
        poly_fit = poly.polyfit(r, By, 2)
        z_to_strength[z] = poly_fit[2] * 2.0
    plt.plot(z_to_strength.keys(), z_to_strength.values())
    plt.vlines(0.02113, min(z_to_strength.values()), max(z_to_strength.values()), colors="tab:orange", linestyles="dashed")
    plt.vlines(-0.02113, min(z_to_strength.values()), max(z_to_strength.values()), colors="tab:orange", linestyles="dashed")
    plt.hlines(0, start_z, end_z, linestyles="dashed")
    plt.show()
    print("Integral: " + str((sum(z_to_strength.values()) * (end_z - start_z) / len(z_to_strength.values()))) + " Tesla per meter")
    print("Min: " + str(min(z_to_strength.values())) + " Tesla per square meter")
    print("Max: " + str(max(z_to_strength.values())) + " Tesla per square meter")
    print("Min: " + str(min(z_to_strength.values()) / 0.00033887) + " inverse cubic meters")
    print("Max: " + str(max(z_to_strength.values()) / 0.00033887) + " inverse cubic meters")
    return z_to_strength


print(strength_along_z("BDDBLSP.spc", "/home/noah/Documents/UMER_MagnetDesigner/Specifications", -0.1, 0.1,
                       200, 0.01, True))
# Integral: -9.659138442762684e-05 Tesla per meter
print(strength_along_z("BDDBLSP.spc", "/home/noah/Documents/UMER_MagnetDesigner/Specifications", -0.1, 0.1,
                       200, 0.01, False))
# Integral: -0.00014873792219060312 Tesla per meter
