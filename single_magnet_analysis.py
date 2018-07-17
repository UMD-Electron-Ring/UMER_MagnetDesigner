import subprocess

import numpy as np

import numpy.polynomial.polynomial as poly

from magli_batch_utils import read_batch_output

from matplotlib import pyplot as plt

from matplotlib import animation


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
                f.write("calc(0, 0, {0:f}, 0, {1:f}, {2:f}, 1000,, along_x_z={1:f}.txt);\n".format(-radius, z, r_step))
            else:
                f.write("calc(0, 1, 0, {0:f}, {1:f}, {2:f}, 1000,, along_y_z={1:f}.txt);\n".format(-radius, z, r_step))
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
    plt.vlines(0.02113, min(z_to_strength.values()), max(z_to_strength.values()), colors="tab:orange",
               linestyles="dashed")
    plt.vlines(-0.02113, min(z_to_strength.values()), max(z_to_strength.values()), colors="tab:orange",
               linestyles="dashed")
    plt.hlines(0, start_z, end_z, linestyles="dashed")
    plt.xlabel("Z (meters)")
    plt.ylabel("Sextupole Strength (T/(m^2))")
    plt.title("Strength of "+in_file+" with radius "+str(radius))
    plt.show()
    print("Integral: " + str(
        (sum(z_to_strength.values()) * (end_z - start_z) / len(z_to_strength.values()))) + " Tesla per meter")
    print("Min: " + str(min(z_to_strength.values())) + " Tesla per square meter")
    print("Max: " + str(max(z_to_strength.values())) + " Tesla per square meter")
    print("Min: " + str(min(z_to_strength.values()) / 0.00033887) + " inverse cubic meters")
    print("Max: " + str(max(z_to_strength.values()) / 0.00033887) + " inverse cubic meters")
    return z_to_strength


def field_plot(in_file, out_file_folder, z, radius, grid_square_length, force=False, draw=True):
    with open(out_file_folder + "/batch.bat", "w") as f:
        f.write("load(" + in_file + ",);\n")
        for y in np.arange(-radius, radius, grid_square_length):
            y = round(y, 6)
            x_lim = abs(radius * np.math.sin(np.math.acos(y / radius)))
            # calc(rectangular coordinate system is 0, varying along an axis (2 for z, 0 for x, 1 for y),
            # starting point x,
            # starting point y, starting point z, step size, # steps,, name of output tile.txt);
            f.write("calc(0, 0, {0:f}, {1:f}, {2:f}, {3:f}, {4:f},, along_x_y={1:f}.txt);\n".format(-x_lim, y, z,
                                                                                                    grid_square_length,
                                                                                                    2. * x_lim /
                                                                                                    grid_square_length))
    process = subprocess.Popen("./mag -bat batch.bat".split(), stdout=subprocess.PIPE, cwd=out_file_folder)
    output, error = process.communicate()
    x = []
    y = []
    Bx = []
    By = []
    for file_y in np.arange(-radius, radius, grid_square_length):
        file_y = round(file_y, 6)
        data = read_batch_output(out_file_folder + "/along_x_y={0:f}.txt".format(file_y))
        for line in data:
            x.append(line[0])
            y.append(line[1])
            Bx.append(line[3])
            By.append(line[4])
    By = np.array(By)
    if draw:
        plt.xlabel("X (meters)")
        plt.ylabel("Y (meters)")
        plt.title("B-field inside "+in_file+" at Z="+str(z))
        plt.quiver(x, y, Bx, By, pivot="mid")
        plt.savefig("B-field inside "+in_file+" at Z="+str(z)+".png")
        plt.show()
        plt.xlabel("X (meters)")
        plt.ylabel("Y (meters)")
        plt.title("Forces on an electron into "+in_file+" at Z="+str(z))
        plt.quiver(x, y, -By, Bx, pivot="mid")
        plt.savefig("Forces on an electron into "+in_file+" at Z="+str(z)+".png")
        plt.show()
    if force:
        return x, y, Bx, By
    else:
        return x, y, -By, Bx


def field_animation(in_file, out_file_folder, start_z, end_z, steps, radius, grid_square_length, fps, force=False):
    x, y, u, v = field_plot(in_file, out_file_folder, 0, radius, grid_square_length, force=force, draw=False)
    fig = plt.figure(figsize=(24, 18))
    ax = plt.axes(xlim=(min(x), max(x)), ylim=(min(y), max(y)))
    quiver = ax.quiver(x, y, u, v, pivot='mid')

    def update_quiver(z):
        _, _, new_u, new_v = field_plot(in_file, out_file_folder, z, radius, grid_square_length, force=force, draw=False)
        quiver.set_UVC(new_u, new_v)
        return quiver

    anim = animation.FuncAnimation(fig, update_quiver, frames=np.linspace(start_z, end_z, steps), interval=1000./fps, blit=False)
    if force:
        anim.save("Forces on electron into "+in_file+" from Z="+str(start_z)+" to Z="+str(end_z)+".mp4")
    else:
        anim.save("B-field of " + in_file + " from Z=" + str(start_z) + " to Z=" + str(end_z) + ".mp4")
    plt.show()


# field_animation("LeftRight_0.97.spc", "/home/noah/Documents/UMER_MagnetDesigner/Specifications", -0.05, 0.05, 30, 0.015, 0.001, 30, force=False)
field_plot("LeftRight_0.97.spc", "/home/noah/Documents/UMER_MagnetDesigner/Specifications", 0.0, 0.015, 0.001)
# print(
#     strength_along_z("BDDBLSP.spc", "/home/noah/Documents/UMER_MagnetDesigner/Specifications", -0.09, -0.0188, 75,
# 0.01,
#                      True))
# print(strength_along_z("BDDBLSP.spc", "/home/noah/Documents/UMER_MagnetDesigner/Specifications", -0.0188, 0.0188, 75,
#                        0.01, True))
# print(strength_along_z("BDDBLSP.spc", "/home/noah/Documents/UMER_MagnetDesigner/Specifications", 0.0188, 0.09, 75,
# 0.01,
#                        True))
# print(
#     strength_along_z("BDDBLSP.spc", "/home/noah/Documents/UMER_MagnetDesigner/Specifications", -0.09, -0.0188, 75,
# 0.01,
#                      False))
# print(strength_along_z("BDDBLSP.spc", "/home/noah/Documents/UMER_MagnetDesigner/Specifications", -0.0188, 0.0188, 75,
#                        0.01, False))
# print(strength_along_z("BDDBLSP.spc", "/home/noah/Documents/UMER_MagnetDesigner/Specifications", 0.0188, 0.09, 75, 0.01,
#                        False))
# Integral: -9.659138442762684e-05 Tesla per meter
# Integral: -0.00014873792219060312 Tesla per meter
