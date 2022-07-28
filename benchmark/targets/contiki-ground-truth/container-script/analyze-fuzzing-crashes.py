#!/usr/bin/env python3

import glob
import os
import re
import shutil
import subprocess
import sys

# Configuration options.
valgrind_timeout = 3
valgrind_error_exitcode = 50
standard_output = True
fuzzing_file = "fuzzing-input"

def filter_output(valgrind_output):
    pattern = re.compile("==.*by .*")
    lines = pattern.findall(valgrind_output)
    return lines

def run_valgrind(protocol, exec_file, test_file):
#    shutil.copyfile(test_file, fuzzing_file)
    os.environ['ENTRY_POINT'] = protocol
    os.environ['FUZZ_FILE'] = test_file
    proc = subprocess.Popen(["valgrind",
                             "-q", "--error-exitcode=" + str(valgrind_error_exitcode),
                             exec_file, test_file],
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    try:
        proc_output, proc_error = proc.communicate(timeout=valgrind_timeout)
        if standard_output is True:
            print(proc_output)

        filtered_output = filter_output(proc_error)
        print("Stack trace for ({0}, {1}):\n".format(exec_file, test_file))
        for line in filtered_output:
            line = re.sub("==\d+==", "", line)
            line = re.sub("by 0x[0-9a-fA-F]+:", "", line)
            print("| {0}".format(line.strip()))
    except subprocess.TimeoutExpired:
        print("Process timed out")
        proc.kill()
        proc_output, proc_error = proc.communicate()

    print("valgrind return code: {0}".format(proc.returncode))

if len(sys.argv) != 3 and len(sys.argv) != 4:
    print("Usage: python {0} <exec file> <crash dir> [protocol]".format(sys.argv[0]))
    exit(1)

exec_file = sys.argv[1]
crash_dir = sys.argv[2]

if len(sys.argv) == 4:
    protocol = sys.argv[3]
else:
    protocol = "uip"


print("Executing {0} with the input samples in {1}".format(exec_file, crash_dir))

if os.path.exists(exec_file) is False:
    print("{0} does not exist".format(exec_file))
    exit(1)

if os.path.isdir(crash_dir) is False:
    print("{0} is not a directory".format(crash_dir))
    exit(1)

crash_pattern = crash_dir + "/*"
input_files = glob.glob(crash_pattern)

if len(input_files) == 0:
    print("Found no input files matching the pattern {0}".format(crash_pattern))
    exit(1)

for input_file in input_files:
    print("Testing with {0} as input".format(input_file))
    run_valgrind(protocol, exec_file, input_file);
