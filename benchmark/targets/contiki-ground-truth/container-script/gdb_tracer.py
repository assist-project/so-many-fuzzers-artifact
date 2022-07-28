import sys
import gdb
import os
import re

## from:https://stackoverflow.com/questions/39602306/tracing-program-function-execution-on-source-line-level

def in_frames(needle):
    """ Check if the passed frame is still on the current stack """
    hay = gdb.newest_frame()
    while hay:
        if hay == needle:
            return True
        hay = hay.older()
    return False

def step_trace():
    counter = 0
    frame = gdb.newest_frame()
    print("Stepping until end of {} @ {}:{}".format(frame.name(), frame.function().symtab, frame.function().line))
    while in_frames(frame):
        counter += 1
        gdb.execute("step")

    print("Done stepping through {} lines.".format(counter))
