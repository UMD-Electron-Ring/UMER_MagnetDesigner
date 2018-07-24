import subprocess
import numpy as np
import numpy.polynomial.polynomial as poly
from magli_batch_utils import read_batch_output
from matplotlib import pyplot as plt
from matplotlib import animation
import os


def strength_along_z(in_file, start_z, end_z, steps, radius, along_x, edge_z):
    """
    Measure how the sextupole strength of a magnet varies with respect to z.
    :param in_file: The name .spc file representing the magnet. Should not include the path.
    :param start_z: The starting value of z.
    :param end_z: The final value of z.
    :param steps: How many values z should take on between the starting and final values.
    :param radius: The radius to measure strength within. Should be less than the actual radius to avoid weirdness.
    :param along_x: Whether to measure strength along x or along y.
    :param edge_z: The distance from the edge of the magnet to the center along z, in meters.
    :return: a dictionary mapping z-coordinate to sextupole strength.
    """
    # We want 1000 steps total, across the diameter.
    r_step = radius * 2. / 1000.
    z_to_strength = {}
    z_to_r_squared = {}
    folder = "Specifications"
    with open(os.path.join(folder, "batch.bat"), "w") as f:
        f.write("load(" + in_file + ",);\n")
        for z in np.linspace(start_z, end_z, steps):
            # Round to avoid floating point errors
            z = round(z, 6)
            # calc(rectangular coordinate system is 0, varying along an axis (2 for z, 0 for x, 1 for y),
            # starting point x,
            # starting point y, starting point z, step size, # steps,, name of output tile.txt);
            if along_x:
                f.write("calc(0, 0, {0:f}, 0, {1:f}, {2:f}, 1000,, along_x_z={1:f}.txt);\n".format(-radius, z, r_step))
            else:
                f.write("calc(0, 1, 0, {0:f}, {1:f}, {2:f}, 1000,, along_y_z={1:f}.txt);\n".format(-radius, z, r_step))
    # Run the batch file
    if os.name == "posix":
        process = subprocess.Popen("./mag -bat batch.bat".split(), stdout=subprocess.PIPE, cwd=folder)
    else:
        process = subprocess.Popen("MagLi.exe -bat batch.bat".split(), stdout=subprocess.PIPE, cwd=folder)
    for z in np.linspace(start_z, end_z, steps):
        # Round to avoid floating point errors
        z = round(z, 6)
        if along_x:
            data = read_batch_output(os.path.join(folder, "along_x_z={0:f}.txt".format(z)))
        else:
            data = read_batch_output(os.path.join(folder, "along_y_z={0:f}.txt".format(z)))
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
        poly_fit = poly.polyfit(r, By, 2, full=True)
        poly_function = poly.polyval(r, poly_fit[0])
        # Calculate R^2
        z_to_r_squared[z] = 1. - (poly_fit[1][0][0] / sum(poly_function ** 2))
        z_to_strength[z] = poly_fit[0][2] * 2.0
    # Plot the strength along z.
    plt.plot(z_to_strength.keys(), z_to_strength.values())
    # Plot the edges of the sextupole magnet
    plt.vlines(edge_z, min(z_to_strength.values()), max(z_to_strength.values()), colors="tab:orange",
               linestyles="dashed")
    plt.vlines(-edge_z, min(z_to_strength.values()), max(z_to_strength.values()), colors="tab:orange",
               linestyles="dashed")
    # Plot y = 0
    plt.hlines(0, start_z, end_z, linestyles="dashed")
    plt.xlabel("Z (meters)")
    plt.ylabel("Sextupole Strength ($\\frac{T}{m^2}$)")
    if along_x:
        plt.title("Strength of " + in_file + " along x with radius " + str(radius))
    else:
        plt.title("Strength of " + in_file + " along y with radius " + str(radius))
    plt.show()

    # Plot the R^2 along z
    plt.plot(z_to_r_squared.keys(), z_to_r_squared.values())
    # Plot the edges of the sextupole magnet
    plt.vlines(edge_z, min(z_to_r_squared.values()), max(z_to_r_squared.values()), colors="tab:orange",
               linestyles="dashed")
    plt.vlines(-edge_z, min(z_to_r_squared.values()), max(z_to_r_squared.values()), colors="tab:orange",
               linestyles="dashed")
    plt.xlabel("Z (meters)")
    plt.ylabel("$R^2$")
    if along_x:
        plt.title("$R^2$ of " + in_file + " along x with radius " + str(radius))
    else:
        plt.title("$R^2$ of " + in_file + " along y with radius " + str(radius))
    plt.show()
    # Print useful numbers
    print("Integral: " + str(
        (sum(z_to_strength.values()) * (end_z - start_z) / len(z_to_strength.values()))) + " Tesla per meter")
    print("Min: " + str(min(z_to_strength.values())) + " Tesla per square meter")
    print("Max: " + str(max(z_to_strength.values())) + " Tesla per square meter")
    # This assumes a 10 KeV electron.
    print("Min: " + str(min(z_to_strength.values()) / 0.00033887) + " inverse cubic meters")
    print("Max: " + str(max(z_to_strength.values()) / 0.00033887) + " inverse cubic meters")
    return z_to_strength


def field_plot(in_file, z, radius, grid_square_length, force=False, draw=True):
    """
    Create a vector field plot of the magnetic or force field inside a magnet at a given z.
    :param in_file: The .spc file describing the magnet. Should not include the path.
    :param z: The z value to display the field at.
    :param radius: The radius to measure field within. Should be less than the actual radius to avoid weirdness.
    :param grid_square_length: How far apart each vector's tail should be, in meters.
    :param force: Whether to return the values for the force plot or the magnetic field plot.
    :param draw: Whether to draw the created plot.
    :return: Four lists: x, y, vector x components, and vector y components.
    """
    folder = "Specifications"
    with open(os.path.join(folder, "batch.bat"), "w") as f:
        f.write("load(" + in_file + ",);\n")
        for y in np.arange(-radius, radius, grid_square_length):
            # Avoid floating point errors
            y = round(y, 6)
            # Find the point on the circle at the given y using trig
            start_x = abs(radius * np.math.sin(np.math.acos(y / radius)))
            # Round down to the nearest multiple of grid square length
            start_x = start_x - start_x % grid_square_length
            # calc(rectangular coordinate system is 0, varying along an axis (2 for z, 0 for x, 1 for y),
            # starting point x,
            # starting point y, starting point z, step size, # steps,, name of output tile.txt);
            f.write("calc(0, 0, {0:f}, {1:f}, {2:f}, {3:f}, {4:f},, along_x_y={1:f}.txt);\n".format(-start_x, y, z,
                                                                                                    grid_square_length,
                                                                                                    2. * start_x /
                                                                                                    grid_square_length))
    if os.name == "posix":
        process = subprocess.Popen("./mag -bat batch.bat".split(), stdout=subprocess.PIPE, cwd=folder)
    else:
        process = subprocess.Popen("MagLi.exe -bat batch.bat".split(), stdout=subprocess.PIPE, cwd=folder)
    output, error = process.communicate()
    x = []
    y = []
    Bx = []
    By = []
    for file_y in np.arange(-radius, radius, grid_square_length):
        # Avoid floating point errors
        file_y = round(file_y, 6)
        data = read_batch_output(os.path.join(folder, "along_x_y={0:f}.txt".format(file_y)))
        for line in data:
            x.append(line[0])
            y.append(line[1])
            Bx.append(line[3])
            By.append(line[4])
    # Convert By to an array so we can make it negative for the force field
    By = np.array(By)
    if draw:
        plt.xlabel("X (meters)")
        plt.ylabel("Y (meters)")
        plt.title("B-field inside " + in_file + " at Z=" + str(z))
        # This scale factor may have to be changed for other magnets
        plt.quiver(x, y, Bx, By, pivot="mid", scale=0.005, scale_units="width")
        plt.savefig("B-field inside " + in_file + " at Z=" + str(z) + ".png")
        plt.show()
        plt.xlabel("X (meters)")
        plt.ylabel("Y (meters)")
        plt.title("Forces on an electron into " + in_file + " at Z=" + str(z))
        plt.quiver(x, y, -By, Bx, pivot="mid")
        plt.savefig("Forces on an electron into " + in_file + " at Z=" + str(z) + ".png")
        plt.show()
    if force:
        return x, y, -By, Bx
    else:
        return x, y, Bx, By


def field_animation(in_file, start_z, end_z, steps, radius, grid_square_length, fps, force=False):
    """
    Animate the magnetic or force field of a manget along a range of Z values.
    :param in_file: The .spc file describing the magnet. Should not include the path.
    :param start_z: The starting value of z.
    :param end_z: The final value of z.
    :param steps: How many values z should take on between the starting and final values.
    :param radius: The radius to measure field within. Should be less than the actual radius to avoid weirdness.
    :param grid_square_length: How far apart each vector's tail should be, in meters.
    :param fps: How many frames to display per second.
    :param force: Whether to return the values for the force plot or the magnetic field plot.
    :return: The animation created.
    """
    x, y, u, v = field_plot(in_file, 0, radius, grid_square_length, force=force, draw=False)
    fig = plt.figure(figsize=(16, 12))
    # Force a square plot
    axes = plt.axes(xlim=(-radius * 1.1, radius * 1.1), ylim=(-radius * 1.1, radius * 1.1))
    if force:
        axes.set_title("Forces on electron into " + in_file + " from Z=" + str(start_z) + " to Z=" + str(end_z))
    else:
        axes.set_title("B-field of " + in_file + " from Z=" + str(start_z) + " to Z=" + str(end_z))
    axes.set_xlabel("X (meters)")
    axes.set_ylabel("Y (meters)")
    # Set a fixed scaling for the whole animation
    quiver = axes.quiver(x, y, u, v, pivot='tail', scale=0.005, scale_units="width")
    axes.scatter(x, y)

    def update_quiver(z):
        """
        Modify the quiver plot to be at the given z.
        :param z: The Z value to draw the quiver plot at
        :return: The updated quiver plot.
        """
        _, _, new_u, new_v = field_plot(in_file, z, radius, grid_square_length, force=force, draw=False)
        quiver.set_UVC(new_u, new_v)
        return quiver

    anim = animation.FuncAnimation(fig, update_quiver, frames=np.linspace(start_z, end_z, steps), interval=1000. / fps,
                                   blit=False)
    if force:
        anim.save("Forces on electron into " + in_file + " from Z=" + str(start_z) + " to Z=" + str(end_z) + ".mp4")
    else:
        anim.save("B-field of " + in_file + " from Z=" + str(start_z) + " to Z=" + str(end_z) + ".mp4")
    return anim


# strength_along_z("sextupole_routed.spc", -0.045, 0.045, 20, 0.015, True, 0.0245)
field_plot("sextupole_routed.spc", 0, 0.03, 0.001)
