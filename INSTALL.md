# Artifact Instructions

Both the raw data and the fuzzing framework are available with the public link in Zenodo:

## Obtain and Install the Artifact

### Requirements

We are assuming you already have a relatively recent machine running Linux or macOS.

For the experiments to run properly, you must also install:
- [Docker](https://docs.docker.com/engine/install/).
- The Perl module `Array::Utils` (with e.g., `sudo cpan install Array::Utils`).

Also, for AFL, you need to run `echo core > /proc/sys/kernel/core_pattern` as root (`sudo`).

### Unpack

To install the artifact, just download the .tar from Zenodo or clone its GitHub repository.

Here are the commands for the .tar archive:

```bash
> tar -xf so-many-fuzzers-artifact.tar
> cd so-many-fuzzers-artifact
> export WORKPATH=$PWD
> ls $WORKPATH
INSTALL.md  README.md  LICENSE.md  ...
```

Make sure to set the variable `WORKPATH` with the absolute path to the decompressed folder.
Its contents should include the files LICENSE.md, README.md, and INSTALL.md (this file).

### Experiment Data

The experiment data are archived in `data-220803.tar`.
We also provide a script to show the raw data and the data as formatted into the paper (trials:mean-time-to-exposure).
Executing the next commands will print the raw data and Table 3's row for uIP-overflow.

```bash
> cd $WORKPATH
> tar -xf data-220803.tar
> perl $WORKPATH/src/suites-management/script/print_csv_overview.pl -input=$WORKPATH/data/3.1/uIP/uip-overflow.csv

 -- Campaign CSV Printer --

 Raw Data from $WORKPATH/data/3.1/uIP/uip-overflow.csv:

            afl-clang-fast      : afl-gcc             : angora              : honggfuzz           : intriguer           : mopt                : qsym                : symcc               :
-- run 1  :2781                 :1353                 :10662                :timeout              :3372                 :214                  :2997                 :20                   :
-- run 2  :876                  :438                  :9588                 :timeout              :3418                 :166                  :886                  :46                   :
-- run 3  :2990                 :688                  :796                  :timeout              :1811                 :154                  :1294                 :70                   :
-- run 4  :3091                 :190                  :2618                 :timeout              :640                  :192                  :1334                 :110                  :
-- run 5  :3554                 :1642                 :1664                 :timeout              :2871                 :195                  :5215                 :32                   :
-- run 6  :325                  :245                  :214                  :timeout              :6091                 :211                  :335                  :148                  :
-- run 7  :225                  :198                  :1963                 :timeout              :4623                 :122                  :382                  :118                  :
-- run 8  :3009                 :3312                 :323                  :timeout              :2023                 :224                  :1236                 :167                  :
-- run 9  :1998                 :1678                 :3809                 :timeout              :3442                 :127                  :350                  :171                  :
-- run 10 :2554                 :655                  :450                  :timeout              :1692                 :196                  :365                  :108                  :
-----------------
 NBTrial and Mean Time to Exposure from $WORKPATH/data/3.1/uIP/uip-overflow.csv :
-- afl-clang-fast                :      10:2140   (00:35:40)
-- afl-gcc                       :      10:1040   (00:17:20)
-- angora                        :      10:3209   (00:53:29)
-- honggfuzz                     :       0:0      (00:00:00)
-- intriguer                     :      10:2998   (00:49:58)
-- mopt                          :      10:180    (00:03:00)
-- qsym                          :      10:1439   (00:23:59)
-- symcc                         :      10:99     (00:01:39)
-----------------
```

## Getting Started

The experiments consist of launching a fuzzing campaign for each fuzzer and vulnerability with and without sanitizers.

Let us first see a small example to check that everything is working well.

**Example**: Let us launch _symcc_ for the _uip-overflow_ vulnerability with a timeout of _10_ minutes (we suggest to also allow 2 minutes for the validation).

Running the following commands will launch the campaign:
```sh
> mkdir -p ${WORKPATH}/test
> ${WORKPATH}/src/suites-management/run-ground-truth-campaign.sh -b uip-overflow -f symcc -n 2 -t 10m --output ${WORKPATH}/test/uip-overflow

-Contiki-NG Ground Truth Campaign Configuration-

[+] Get corresponding commit...(before uip-overflow)
  - ... commit found: a1cba5607c44514a9644333b6ca0a9a5e0f3c59e.
[+] Configure for: uip...
[+] Write .env files...
[+] Run: ${WORKPATH}/src/docker/run-fuzzing-campaign.sh with:
    -f symcc
    -s contiki-ground-truth
    -h contiki-ng-fuzzing
    and options: --tag fuzz-symcc-uip-overflow-uip -n 2 -o ${WORKPATH}/test/uip-overflow -t 10m

-Campaign Runner: build and run fuzzing experiments-

...

Use 'docker scan' to run Snyk tests against images to find vulnerabilities and learn how to fix them
[+] Docker Image fuzz-symcc-uip-overflow-uip built.

[+] Run 2 trial(s):
    - of fuzz-symcc-uip-overflow-uip
    - for 10m
    - at 2022-08-01 17:39
    - output folders: ${WORKPATH}/test/uip-overflow

[+] Launch symcc_1 (log in ${WORKPATH}/test/uip-overflow/run1/symcc)
[+] Launch symcc_2 (log in ${WORKPATH}/test/uip-overflow/run2/symcc)
[+] ... Fuzzing In Progress ... [+]
```
The above command requires a building time of 529.0 seconds (i.e., about 10
minutes) on a MacBook Pro.

The command `docker ps` shows the running containers:
```bash
> docker ps
CONTAINER ID   IMAGE                         COMMAND                  CREATED         STATUS         PORTS     NAMES
9e776a008bb2   fuzz-symcc-uip-overflow-uip   "bash -c 'source /ho…"   2 minutes ago   Up 2 minutes             upbeat_roentgen
1dffa87e651c   fuzz-symcc-uip-overflow-uip   "bash -c 'source /ho…"   2 minutes ago   Up 2 minutes             objective_dewdney
```

OK, the campaign is running.
Give SymCC some time to expose the vulnerability.
After about 15 minutes, the container should have finished.
You can now compute the overview and .csv file with the command:

```bash
> perl ${WORKPATH}/src/suites-management/script/print_campaign_overview.pl  -input=${WORKPATH}/test/uip-overflow/

  -- Campaign Result Printer --

  - write raw-data into uip-overflow.csv.
[+] Collect 1 tools and 2 trials

 Raw Data from ${WORKPATH}/test/uip-overflow/:

            symcc               :
-- run 1  :timeout              :
-- run 2  :234                  :
uip-overflow.csv written.
-----------------
 NBTrial and Mean Time to Exposure from ${WORKPATH}/test/uip-overflow/ :
-- symcc                         :       1:234    (00:03:54)
-----------------
```

According to these results, only one trial of SymCC exposed _uip-overflow_ after 234 seconds (3 minutes and 54 seconds).

Finally, you can see the fuzzers' logs in `${WORKPATH}/test/uip-overflow/run1/symcc/log/` and check that nothing wrong happened.

**Note**: Fuzzing campaigns are greedy in disk-usage and memory.
Please be sure you have sufficient resources before running campaigns
and frequently clean Docker's images and campaign's logs.

### Evaluating the Results

The results shown in the previous section use multiple binaries to report bad inputs.
It is convenient to find new crashes and understand a vulnerability but not for evaluating fuzzers.
We provide a second script to evaluate a corpus from a campaign using a specific binary.

####  Feeding corpora for evaluation

In the folder `data`, corpora from our experiment on uip-len are stored.
To feed them to the target with AddressSanitizer instrumentation runs the next command:
```sh
> ${WORKPATH}/src/suites-management/script/validate_corpus.sh uip-len ${WORKPATH}/data/corpuses ${WORKPATH}/test/corpus asan
```

The script builds a docker image for each tool and runs the evaluation.
After all the corpora have been checked (about 2 hours), you
can run the `print_campaign_overview.pl` script to see the result.

```sh
> perl ${WORKPATH}/src/suites-management/script/print_campaign_overview.pl  -input=${WORKPATH}/test/corpus/uip-len
```


####  Corpus Generation
[Ubuntu-tested only]

We provide a script (`gather_corpus.sh <vulnerability> <path_to_campaign> <output_folder>`) to gather all inputs from a campaign and create a corpus.
However, this uses the `rename` command, which you should install (`sudo apt-get install rename` for Ubuntu-like OSes).
It is not mandatory, but there are identical filenames from different input types (hangs/inputs/crashes) that will be lost without it.

To generate a corpus for the example above, run the command:
```sh
> ${WORKPATH}/src/suites-management/script/gather_corpus.sh uip-overflow  ${WORKPATH}/test/  ${WORKPATH}/test/corpuses

-Corpus Gathering-
  - fixname         :uip-overflow
  - inputfolder     :/home/clemp/so-many-fuzzers-artifact/test/
  - outputfolder    :/home/clemp/so-many-fuzzers-artifact/test/corpuses
~/so-many-fuzzers-artifact/src/targets/contiki-ground-truth/container-script ~/so-many-fuzzers-artifact
sync at: ${WORKPATH}/so-many-fuzzers-artifact/test//uip-overflow/run1/symcc/sync_folder
- Collecting 107 inputs from afl-master -
- Collecting 115 inputs from afl-slave -
- Collecting 88 inputs from symcc -
- Collecting crashes from afl-master -
    3 crashes from afl-master.
    2 hangs from afl-master.
- Collecting crashes from afl-slave -
    2 crashes from afl-slave.
    2 hangs from afl-slave.
- Collecting crashes from symcc -
    1 crashes from symcc.
    symcc/hangs empty.
sync at: ${WORKPATH}/so-many-fuzzers-artifact/test//uip-overflow/run2/symcc/sync_folder
- Collecting 123 inputs from afl-master -
- Collecting 131 inputs from afl-slave -
- Collecting 128 inputs from symcc -
- Collecting crashes from afl-master -
    2 crashes from afl-master.
    3 hangs from afl-master.
- Collecting crashes from afl-slave -
    3 crashes from afl-slave.
    2 hangs from afl-slave.
- Collecting crashes from symcc -
    2 crashes from symcc.
    symcc/hangs empty.
~/so-many-fuzzers-artifact
```

Notice that a corpus not only stores inputs generated from a campaign but also their timestamps, which can unfortunately be lost otherwise when manipulating the files.

Finally, try to validate evaluate the uip-overflow campaign with AFL-clang-Asan with the two next commands.

```bash
> ${WORKPATH}/src/suites-management/script/validate_corpus.sh uip-overflow ${WORKPATH}/test/corpuses/ ${WORKPATH}/test/results-with-asan asan

> perl ${WORKPATH}/src/suites-management/script/print_campaign_overview.pl  -input=${WORKPATH}/test/results-with-asan/uip-overflow

  -- Campaign Result Printer --

[+] Collect 1 tools and 2 trials

 Raw Data from /home/clemp/so-many-fuzzers-artifact/test/results-with-asan/uip-overflow:

            symcc               :
-- run 1  :89                   :
-- run 2  :93                   :
-----------------
 NBTrial and Mean Time to Exposure from /home/clemp/so-many-fuzzers-artifact/test/results-with-asan/uip-overflow :
-- symcc                         :       2:91     (00:01:31)
-----------------
```

With AFL-Clang-Asan, both trials detected uip-overflow in 1 minute 31 seconds on average.

This finishes our starter example.

You can now:
- run a fuzzing campaign with the tool/vulnerability/sanitizer you want and all this with -n instances,
- collect each run's corpus, and
- evaluate the detected vulnerabilities with standard or sanitized targets.

Happy fuzzing!

## How to (Try to) Reproduce the Paper Results

### Section 3 Results

For Section 3, we ran a campaign with 10 trials for all combinations `<vulnerability>`, `<tool>` using the commands:
```bash
> cd ${WORKPATH}/src/suites-management
> mkdir -p ${OUTPUT_FOLDER}
> ./run-ground-truth-campaign.sh -b <vulnerability> -f <tool> -n 10 -t 24h --output ${OUTPUT_FOLDER}
```
The paper's raw-data are in `${WORKPATH}/data/3.1`.

### Section 4.1 Results

For the results of Section 4.1, we ran a campaign with 10 trials for all combinations <vulnerability, tool> with AddressSanitizer using the commands:
```bash
> cd ${WORKPATH}/src/suites-management
> mkdir -p ${OUTPUT_FOLDER}
> ./run-ground-truth-campaign.sh --san asan -b <vulnerability> -f <tool> -n 10 -t 24h --output ${OUTPUT_FOLDER}
```
The paper's raw-data are in `${WORKPATH}/data/4.1`.

### Section 4.2 Results

For Section 4.2, we ran a campaign with 10 trials for all combinations <vulnerability, tool> with EffectiveTypeSanitizer using the commands:
```bash
> cd ${WORKPATH}/src/suites-management \
> mkdir -p ${OUTPUT_FOLDER}
> ./run-ground-truth-campaign.sh --san effectivesan -b <vulnerability> -f <tool> -n 10 -t 24h --output ${OUTPUT_FOLDER}
```
The paper's raw-data are in `${WORKPATH}/data/4.2`.

### Values for Tool and Vulnerability

Values for `<tool>` (option `-f`) are: `afl-gcc`, `afl-clang-fast`, `mopt`, `honggfuzz`, `angora`, `qsym`, `intriguer`, `symcc`.

Values for `<vulnerability>` (option `-b`) are: `uip-overflow`, `uip-ext-hdr`, `uip-len`, `6lowpan-frag`, `srh-param`, `nd6-overflow`, `6lowpan-ext-hdr`, `srh-addr-ptr`, `6lowpan-decompr`, `6lowpan-hdr-iphc`, `snmp-oob-varbinds`, `snmp-validate-input`, `uip-rpl-classic-prefix`, `uip-rpl-classic-div`, `6lowpan-udp-hdr`, `6lowpan-payload`, `uip-buf-next-hdr`, `uip-rpl-classic-sllao`.

### Section 4.3 Results

The experiment in Section 4.3 consists in feeding corpora from the 'standard' fuzzing campaigns, i.e. with the usual tool's instrumentation, to a sanitizer.

More precisely, for computing the right columns of Table 13, we ran:
```bash
> ${WORKPATH}/src/suites-management/script/validate_corpus.sh <v> <i> asan
```

Similarly, for computing the right columns of Table 14, we ran:
```bash
> ${WORKPATH}/src/suites-management/script/validate_corpus.sh <v> <i> effectivesan
```
with `<v>` the corresponding vulnerabilities and `<i>` the path to a set of tool's corpus folders.


## Other

### Structure of a campaign folder:
```bash
> tree -L 5 ${WORKPATH}/test/uip-overflow
${WORKPATH}/test/uip-overflow
├── run1
│   └── symcc
│       ├── container.log
│       ├── crash-triage
│       │   └── timestamps
│       ├── log
│       │   ├── afl-master.log
│       │   ├── afl-slave.log
│       │   ├── end_time
│       │   ├── start_time
│       │   ├── symcc.log
│       │   └── triage.log
│       └── sync_folder
│           ├── afl-master
│           │   ├── crashes
│           │   ├── fuzz_bitmap
│           │   ├── fuzzer_stats
│           │   ├── hangs
│           │   ├── plot_data
│           │   └── queue
│           ├── afl-slave
│           │   ├── crashes
│           │   ├── fuzz_bitmap
│           │   ├── fuzzer_stats
│           │   ├── hangs
│           │   ├── plot_data
│           │   └── queue
│           └── symcc
│               ├── bitmap
│               ├── crashes
│               ├── hangs
│               ├── queue
│               └── stats
└── run2
    └── symcc
        ├── container.log
        ├── crash-triage
        │   ├── notfixed
        │   │   ├── 1614488562.stacktrace
        │   │   ├── bad-inputs
        │   │   ├── notfixed-report.txt
        │   │   ├── stacktraces
        │   │   └── valgrind-ea6c68880a.txt
        │   ├── timestamps
        │   ├── undetected
        │   │   └── undetected
        │   └── witnesses
        │       ├── bad-inputs
        │       ├── stacktraces
        │       ├── valgrind-a1cba5607c.txt
        │       └── witness-report.txt
        ├── log
        │   ├── afl-master.log
        │   ├── afl-slave.log
        │   ├── end_time
        │   ├── start_time
        │   ├── symcc.log
        │   ├── triage-compile.log
        │   └── triage.log
        └── sync_folder
            ├── afl-master
            │   ├── crashes
            │   ├── fuzz_bitmap
            │   ├── fuzzer_stats
            │   ├── hangs
            │   ├── plot_data
            │   └── queue
            ├── afl-slave
            │   ├── crashes
            │   ├── fuzz_bitmap
            │   ├── fuzzer_stats
            │   ├── hangs
            │   ├── plot_data
            │   └── queue
            └── symcc
                ├── bitmap
                ├── crashes
                ├── hangs
                ├── queue
                └── stats

42 directories, 38 files
```
(The output may differ depending on whether SymCC found a witness or not.)

The output folder is composed of one folder per trial (named `run<i>`),
containing one folder per tool (give the same output folder to add another tool in the corresponding run<i>).

A tool folder contains:
- a _crash-triage_ giving details on the witnesses and bad inputs found,
- a _log_ folder, and
- a tool's instance folder (the AFL root folder in general).

# Docker

* [docker help](https://docs.docker.com/engine/reference/commandline/cli/)

* `docker ps`: lists (running) containers (add option `-a` to include stopped containers).

* `docker rm`: remove one or more containers.

* `docker images`: lists (built) images.

* `docker rmi`: remove one or more images.

* `docker rm $(docker ps -a -q)`: remove all stopped containers (without stopping the running ones).

