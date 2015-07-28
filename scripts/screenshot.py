#!/bin/python
""" A simple tool to grab a screenshot of the monitor
that is currently active"""


from subprocess import check_output, call
from json import loads
from time import strftime
from os.path import expanduser


SCR_PATH = expanduser("~/screenshots/")
call(["mkdir", "-p", SCR_PATH])
QUALITY = "95"

# Read the workspace setup from i3-msg
JSON_INPUT = check_output(["i3-msg", "-t", "get_workspaces"])
MODEL = loads(JSON_INPUT.decode("utf-8"))

# Find the workspace that is focused
for workspace in MODEL:
    if workspace["focused"]:
        # Get the geometry of the active monitor
        posX = workspace["rect"]["x"]
        posY = workspace["rect"]["y"]
        width = workspace["rect"]["width"]
        height = workspace["rect"]["height"]
        # Focused Workspace found, ignore the rest
        break

GEOMETRY = "%sx%s+%s+%s" % (width, height, posX, posY)
DATESTR = strftime("%Y%m%d-%H%M%S")
FILENAME = SCR_PATH + DATESTR + ".png"

# Take and save the screenshot
call(["import", "-window", "root", "-crop", GEOMETRY,
      "-quality", "100", FILENAME])