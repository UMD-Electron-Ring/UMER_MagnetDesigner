import xml.etree.ElementTree
import math

# MagLi reference frame: y is up, x is across, z is down the tube
# Eagle reference frame: x is across, y is up
# To convert, lines in Eagle parallel to the y axis become lines in MagLi parallel to z.
# Eagle lines parallel to x become arcs in the XY plane.
# All units are amps, degrees, and millimeters until conversion to meters for output.

# Thickness of the PCB that the wires are on
PCB_THICKNESS_MM = 0.3


class Wire:
    """
    Representation of a single, straight segment of wire on a PCB.
    """

    def __init__(self, x1, y1, x2, y2, width, zFromBack):
        """
        Simple constructor
        :param x1: The x-coordinate, in the Eagle reference frame, of the end of the wire current flows from.
        :param y1: The y-coordinate, in the Eagle reference frame, of the end of the wire current flows from.
        :param x2: The x-coordinate, in the Eagle reference frame, of the end of the wire current flows to.
        :param y2: The x-coordinate, in the Eagle reference frame, of the end of the wire current flows from.
        :param width: The width of the wire.
        :param zFromBack: How far from the back of the PCB the wire is.
        """
        self.x1 = x1
        self.y1 = y1
        self.x2 = x2
        self.y2 = y2
        self.width = width
        self.zFromBack = zFromBack

    def is_arc(self):
        """
        :return: True if the wire becomes an arc when wrapped around a cylinder, false otherwise.
        """
        return self.x1 != self.x2

    def length(self):
        """
        :return: The length of the wire.
        """
        return math.sqrt((self.x1 - self.x2) ** 2 + (self.y1 - self.y2) ** 2)

    def __str__(self):
        return str(self.width) + " mm wide wire from (" + str(self.x1) + ", " + str(self.y1) + ") to (" + str(
            self.x2) + ", " + str(self.y2) + ") that's " + str(self.zFromBack) + " mm from the back. "


def read_brd(filename):
    """
    Reads in a .brd file from Autodesk Eagle and turns it into a list of Wires. Tested with Eagle 9.1.0.
    :param filename: The name of the file to read from.
    :return: A list of wires representing all the wires in the brd file.
    """
    wires = []
    e = xml.etree.ElementTree.parse(filename).getroot()
    for signal in e.iter("signal"):
        for wire in signal.findall("wire"):
            if wire.get("layer") == "1":
                # Add the PCB thickness to wires on the top because they'll be on the inside.
                wires.append(
                    Wire(float(wire.get("x1")), float(wire.get("y1")), float(wire.get("x2")), float(wire.get("y2")),
                         float(wire.get("width")), PCB_THICKNESS_MM))
            else:
                wires.append(
                    Wire(float(wire.get("x1")), float(wire.get("y1")), float(wire.get("x2")), float(wire.get("y2")),
                         float(wire.get("width")), 0))
    return wires


def arc(center_z, radius, start_angle, end_angle, x_rot, y_rot, z_rot, segments, current):
    """
    Convert information about an arc of wire to a MagLi command.
    :param center_z: The z coordinate of the arc.
    :param radius: The radius of the arc.
    :param start_angle: The angle of the end of the wire current flows from.
    :param end_angle: The angle of the end of the wire current flows to.
    :param x_rot: How much to rotate the arc around the X-axis.
    :param y_rot: How much to rotate the arc around the Y-axis.
    :param z_rot: How much to rotate the arc around the Z-axis.
    :param segments: How many line segments should be used to draw the arc.
    :param current: The current flowing through the wire.
    :return: A string representing the arc as a MagLi command.
    """
    return "arc(0, 0, 0, {0:.5f}, {1:.5f}, {2:.5f}, {3:.5f}, {4:.5f}, {5:.5f}, {6:.5f}, {7:.5f}, {8:.5f});\n".format(
        center_z / 1000., x_rot, y_rot, z_rot, start_angle, end_angle, radius / 1000., segments, current)


def line(center_x, center_y, center_z, length, segments, current):
    """
    Convert information about a line of wire to a MagLi command.
    :param center_x: The x coordinate of the center of the line.
    :param center_y: The y coordinate of the center of the line.
    :param center_z: The z coordinate of the center of the line.
    :param length: The length of the wire.
    :param segments: How many line segments should be used to draw the line.
    :param current: The current flowing through the wire. Positive current flows one way and negative flows the other
    but the manual doesn't say which is which.
    :return: A string representing the line as a MagLi command.
    """
    return "line(2, {0:.5f}, {1:.5f}, {2:.5f}, 0, 0, 0, {3:.5f}, {4:.5f}, {5:.5f});\n".format(center_x / 1000.,
                                                                                              center_y / 1000.,
                                                                                              center_z / 1000.,
                                                                                              length / 1000., segments,
                                                                                              current)


def x_to_angle(angle_reference, radius, x):
    """
    Convert an x-coordinate in the Eagle reference frame to an angle when wrapped around a cylinder.
    :param angle_reference: A tuple or list of (x-coordinate, angle) to establish a reference point.
    :param radius: The radius of the cylinder.
    :param x: The x-coordinate in the Eagle frame.
    :return: The angle of the point, in degrees.
    """
    delta_x = x - angle_reference[0]
    return angle_reference[1] + 360. * delta_x / (2. * math.pi * radius)


def x_to_xy(angle_reference, radius, x):
    """
    Convert an x-coordinate in the Eagle reference frame to an (x, y) coordinate in the MagLi reference frame.
    :param angle_reference: A tuple or list of (x-coordinate, angle) to establish a reference point.
    :param radius: The radius of the cylinder.
    :param x: The x-coordinate in the Eagle frame.
    :return: a tuple of the (x, y) coordinate of the point.
    """
    angle = x_to_angle(angle_reference, radius, x)
    return radius * math.cos(math.radians(angle)), radius * math.sin(math.radians(angle))


def write_magli(filename, mode, wires, current, radius, angle_reference, segments):
    """
    Create a MagLi specification file describing the given wires wrapped around a cylinder.
    :param filename: The name of the file to write the MagLi commands to.
    :param mode: The mode to write in, 'a' to append and 'w' to overrwrite.
    :param wires: The list of wires to convert to the MagLi format.
    :param current: The current going through the wires.
    :param radius: The radius of the cylinder the wires are being wrapped around.
    :param angle_reference: A tuple or list of (wire x-coordinate, angle around cylinder) to establish a reference point
    :param segments: How many line segments should be used to represent each wire.
    """
    f = open(filename, mode)
    arcs = ""
    for wire in wires:
        if wire.is_arc() and wire.y1 == wire.y2:
            wire_rad = radius - wire.zFromBack
            arcs += arc(wire.y1, wire_rad, x_to_angle(angle_reference, wire_rad, wire.x1),
                        x_to_angle(angle_reference, wire_rad, wire.x2), 0, 0, 0, segments, current)
        elif wire.is_arc():
            print("Complicated arc: " + str(wire))
        else:
            xy = x_to_xy(angle_reference, radius - wire.zFromBack, wire.x1)
            if wire.y1 > wire.y2:
                current_mult = -1
            else:
                current_mult = 1
            f.write(line(xy[0], xy[1], (wire.y1 + wire.y2) / 2., wire.length(), segments, current_mult * current))
    f.write(arcs)
    f.close()
