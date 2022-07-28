# Artifact Instructions 

Both the raw-data and the fuzzing framework are available with the public link in Zenodo:

## Obtain and Install the Artifact 

### Requirements 

For the frameworks' scripts to run properly, you must install:
- [docker](https://docs.docker.com/engine/install/), and
- the Perl module `Array::Utils` (`sudo cpan install Array::Utils`).

### Install

To install the artifact, just download the .tar from Zenodo or clone the GitHub repository. Here are the commands from the .tar archive:

```
tar -xf so-many-fuzzers-artifact.tar
cd so-many-fuzzers-artifact
WORKPATH=$(PWD)
ls $WORKPATH
```
>output
```
INSTALL.md	README.md	benchmark	data-220727.tar
```
>output

Make sure to set the variable `WORKPATH` with the absolute path to the decompressed folder. The content should be the files README.md, and INSTALL.md, the folder benchmark and the raw-data archive 'data-220727.tar'.

> Notice, that we denote the expected outputs from a command with the tag `>output`

## Get Started 

## Reproduce Paper Results


— (old version)

## Basic Usage: fuzzing campaigns

As an example we run the benchmark for the tool _symcc_ and the vulnerability _uip-overflow_ with a timeout of _10_ minutes.

To launch a fuzzing campaign with two trials, run the following commands:
```
cd ${WORKPATH}/benchmark/suites-management \
  && mkdir -p ${WORKPATH}/test \
  && ./run-ground-truth-campaign.sh -b uip-overflow -f symcc -n 2 -t 10m --output ${WORKPATH}/test/uip-overflow
```
>output
```

-Contiki-NG Ground Truth Campaign Configuration-

[+] Get corresponding commit...(before uip-overflow)
  - ... commit found: a1cba5607c44514a9644333b6ca0a9a5e0f3c59e.
[+] Configure for: uip...
[+] Write .env files...
[+] Run: ${WORKPATH}/benchmark/docker/run-fuzzing-campaign.sh with:
    -f symcc
    -s contiki-ground-truth
    -h contiki-ng-fuzzing
    and options: --tag symcc-contiki-ground-truth-uip-overflow-uip -n 2 -o ${WORKPATH}/test/uip-overflow -t 10m

-Campaign Runner: build and run fuzzing experiments-

...

Use 'docker scan' to run Snyk tests against images to find vulnerabilities and learn how to fix them
[+] Docker Image symcc-contiki-ground-truth-uip-overflow-uip built.

[+] Run 2 trial(s):
    - of symcc-contiki-ground-truth-uip-overflow-uip
    - for 10m
    - at 2022-05-04 05:41
    - output folders: ${WORKPATH}/test/uip-overflow

[+] Launch symcc_1 (log in ${WORKPATH}/test/uip-overflow/run1/symcc)
[+] Launch symcc_2 (log in ${WORKPATH}/test/uip-overflow/run2/symcc)
[+] ... Fuzzing In Progress ... [+]
```
>output (building time 529.0s on a MacBook Pro)

The command `docker ps` shows the running containers:
>output
```
CONTAINER ID   IMAGE                                         COMMAND                  CREATED          STATUS          PORTS     NAMES
ae30b58908a6   symcc-contiki-ground-truth-uip-overflow-uip   "bash -c 'source /ho…"   31 seconds ago   Up 31 seconds             practical_edison
232076ab64e9   symcc-contiki-ground-truth-uip-overflow-uip   "bash -c 'source /ho…"   31 seconds ago   Up 31 seconds             determined_visvesvaraya
```
>output

You can also check the output folder:
`ls ${WORKPATH}/test/uip-overflow`
>output
```
run1	run2
```
>output

—

After 10 minutes, running `docker ps`should produce:
>output
```
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```
>output

You can now compute the overview and .csv file with the command:

```
perl ${WORKPATH}/script/print_campaign_overview.pl -csv=uip-overflow.csv -input=${WORKPATH}/test/uip-overflow/
```

>output
```
 -- Campaign Result Printer -- 

  - write raw-data into uip-overflow.csv.
[+] Collect 1 tools and 2 trials

Warning! run2/symcc has undetected files!

            symcc               :
-- run 1  :timeout              :
-- run 2  :341                  :
uip-overflow.csv written.
-----------------
-- symcc                         :       1:341    (00:05:41)
-----------------
```
>output

According to this instance, only one SymCC's trial exposed _uip-overflow_ after 341 seconds (5 minutes and 41 seconds). (Do not mind the undetected file warnings, they are only here for information.)


## Basic Usage: Feeding Corpuses to Sanitizers
(experimental)

Now that you have launched a fuzzing campaign, you can collect the trials' corpus:
```
//create your corpus folder for SymCC trial1
mkdir -p ${WORKPATH}/test/corpuses/symcc/inputs

cp -r ${WORKPATH}/test/uip-overflow/run1/symcc/sync_folder/*/queue/* ${WORKPATH}/test/corpuses/symcc/inputs

cp -r ${WORKPATH}/test/uip-overflow/run1/symcc/sync_folder/*/crashes/* ${WORKPATH}/test/corpuses/symcc/

//Feed the files to AFL-EffectiveSanitizer targets with SymCC configuration
//Unfortunately, the output folder name is constrained according to the vulnerability name, be sure you follow the pattern <fixname>-corpuses-<fixname>
mkdir -p ${WORKPATH}/data/uip-overflow-corpuses-uip-overflow/uip-overflow-corpuses/run1/symcc

fixname=uip-overflow; pushd $WORKPATH/corpuses/docker; ./validate-witnesses.sh --validation --triage -f ${fixname} -i ${WORKPATH}/test/corpuses/symcc -h effectivesan --output ${WORKPATH}/data/uip-overflow-corpuses-uip-overflow/uip-overflow-corpuses/run1/symcc; popd
```
(Notice that SymCC-EffectiveSan is the longest docker image to build and lasted 2266.1s for a MacBook Pro Retina to finish)

>output
```
-Contiki-NG Ground Truth script for witnesses validation-

[+] Check for uip-overflow witnesses with instrumentation effectivesan
  - ... commit found: a1cba5607c44514a9644333b6ca0a9a5e0f3c59e.
[+] Configure for: uip...
[+] Write .env files...
...

[+] Run Docker Image validate-uip-overflow-effectivesan output folder in: ${WORKPATH}/data/uip-overflow-corpuses-uip-overflow/uip-overflow-corpuses/run1/symcc:
Error response from daemon: No such container: 19f8508fb5f9
[+] Container terminated.
    - witnesses found:        0
```
>output

Finally, you can have the result overview using the script:
```
perl ${WORKPATH}/corpuses/docker/collect_campaign_witnesses.pl -input=${WORKPATH}/data/uip-overflow-corpuses-uip-overflow/uip-overflow-corpuses
```

>output
```
 -- Campaign Witnesses Collector -- 

[+] Collect 1 tools and 1 trials
-- run1
                         :timeout :
-----------------
-- run1
                         :       0:0      (00:00:00)
-----------------
I found 0 different stack traces
Unique witness set:
```
output


### Structure of a campaign folder:
`tree -L 5 ${WORKPATH}/test/uip-overflow`
>output
```
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
>output (the output can change if SymCC found a witness or not)

The output folder is composed of one folder per trial (named `run<i>`),
containing one folder per tool (give the same output folder to add another tool in the corresponding run<i>). 

A tool folder contains:
- a _crash-triage_ giving details on the witnesses and bad inputs found,
- a _log_ folder, and
- a tool's instance folder (the AFL root folder in general).

> Notice that we enabled the tools' log to keep track of the fuzzers' status.
> However, you may want to remove those files (especially intriguer.log and afl-master/slave.log) after a campaign to free disk usage.

---

# Get the results


## Reproduce Paper Results

> **CAUTION: Monitor your CPU and disk usages as many containers can be greedy.** 

### To reproduce Section 3
- Run a campaign with 10 tools for all combinations <vulnerability, tool>, using the command:
```
cd ${WORKPATH}/benchmark/suites-management \
  && mkdir -p ${OUTPUT_FOLDER} \ 
  && ./run-ground-truth-campaign.sh -b <vulnerability> -f <tool> -n 10 -t 24h --output ${OUTPUT_FOLDER}
```
- You can find the paper raw data in the .csv in `${WORKPATH}/data/3.1`.

### To reproduce 4.1 
- Run a campaign with 10 tools for all combinations <vulnerability, tool>, using the command:
```
cd ${WORKPATH}/benchmark/suites-management \
  && mkdir -p ${OUTPUT_FOLDER} \ 
  && ./run-ground-truth-campaign.sh --san asan -b <vulnerability> -f <tool> -n 10 -t 24h --output ${OUTPUT_FOLDER}
```
- You can find the paper raw data in the .csv in `${WORKPATH}/data/4.1`.

### To reproduce 4.2
Run a campaign with 10 tools for all combinations <vulnerability, tool>, using the command:
```
cd ${WORKPATH}/benchmark/suites-management \
  && mkdir -p ${OUTPUT_FOLDER} \ 
  && ./run-ground-truth-campaign.sh --san effectivesan -b <vulnerability> -f <tool> -n 10 -t 24h --output ${OUTPUT_FOLDER}
```
- You can find the paper raw data in the .csv in `${WORKPATH}/data/4.2`.

—

Values for <tool> (option -f): `afl-gcc`, `afl-clang-fast`, `mopt`, `honggfuzz`, `angora`, `qsym`, `intriguer`, `symcc`. 

Values for <vulnerability> (option -b): `uip-overflow`, `uip-ext-hdr`, `uip-len`, `6lowpan-frag`, `srh-param`, `nd6-overflow`, `6lowpan-ext-hdr`, `srh-addr-ptr`, `6lowpan-decompr`, `6lowpan-hdr-iphc`, `snmp-oob-varbinds`, `snmp-validate-input`, `uip-rpl-classic-prefix`, `uip-rpl-classic-div`, `6lowpan-udp-hdr`, `6lowpan-payload`, `uip-buf-next-hdr`, `uip-rpl-classic-sllao`. 

### To reproduce 4.3

Due to the large disk-usage the 8x18x3 campaigns take, we provide one corpus in data/corpuses.

The experiment consists in feeding those corpuses to different binaries.
For the example, which is building EffectiveSanitizer, only one Docker image needs to be computed in order to set the good configuration for Contiki-NG and the target binary. However, all the files from those corpuses need to be fed (twice) to the binary, so it lasts a bit of time (one hour for a MacBook Pro Retina).

```
fixname=uip-len; \
inputfolder=${WORKPATH}/data/corpuses/uip-len; \
outputfolder=${WORKPATH}/test/FC-with-EffSan/${fixname}; \
instrumentation=effectivesan; \
mkdir -p ${outputfolder}; \
pushd ${WORKPATH}/corpuses/docker \
&& for tool in ${inputfolder}/*; do \
   base_tool=$(basename ${tool}) \
   && mkdir -p ${outputfolder}/${base_tool} \
   && for trial in ${tool}/corpuses_run*; do \
     nb_run=$(basename ${trial}) \
     && ./validate-witnesses.sh --validation -f ${fixname} -i ${trial} --output ${outputfolder}/${base_tool}/${nb_run} -h ${instrumentation}; \
   done; \
done; popd

```
>output
```

-Contiki-NG Ground Truth script for witnesses validation-

  - file ${WORKPATH}/data/corpuses/uip-len/afl-clang-fast/corpuses_run1/corpus-timestamps-run1 found to associate timestamps.
[+] Check for uip-len witnesses with instrumentation effectivesan
  - ... commit found: b5d997fb5cbe20ac9812558eb71bda746142a253.
[+] Configure for: uip...
[+] Write .env files...
[+] Docker Image validate-uip-len-effectivesan already exist.

[+] Run Docker Image validate-uip-len-effectivesan output folder in: ${WORKPATH}/test/FC-with-EffSan/uip-len/afl-clang-fast/corpuses_run1:
Error response from daemon: No such container: b19b6b2c22f3
[+] Container terminated.
    - witnesses found:        0

-Contiki-NG Ground Truth script for witnesses validation-

  - file ${WORKPATH}/data/corpuses/uip-len/afl-clang-fast/corpuses_run10/corpus-timestamps-run10 found to associate timestamps.
[+] Check for uip-len witnesses with instrumentation effectivesan
  - ... commit found: b5d997fb5cbe20ac9812558eb71bda746142a253.
[+] Configure for: uip...
[+] Write .env files...
[+] Docker Image validate-uip-len-effectivesan already exist.

[+] Run Docker Image validate-uip-len-effectivesan output folder in: ${WORKPATH}/test/FC-with-EffSan/uip-len/afl-clang-fast/corpuses_run10:
Error response from daemon: No such container: f461692489f7
[+] Container terminated.
    - witnesses found:       14


```
>output

While waiting, you can browse the validation outputs (just make sure the trial has been already validated):

```
 cat ${WORKPATH}/test/FC-with-EffSan/uip-len/afl-gcc/corpuses_run10/log/validation.log
```
>output
```

 -- Report bad inputs and witnesses for Contiki-NG Ground Truth benchmark -- 

[+] Working directory:  /home/benchng/validation
 - check witnesses for uip-len
[+] Processing /home/benchng//files-to-validate/inputs with script effectivesan [+]

Cloning into '/home/benchng/validation/put-repository'...
Check fix uip-len <b5d997fb5c:8340735cf5>
 	[+] Build target at b5d997fb5c.
Note: checking out 'b5d997fb5cbe20ac9812558eb71bda746142a253'.

You are in 'detached HEAD' state. You can look around, make experimental
changes and commit them, and you can discard any commits you make in this
state without impacting any branches by performing another checkout.

If you want to create a new branch to retain commits you create, you may
do so (now or later) by using -b with the checkout command again. Example:

  git checkout -b <new-branch-name>

HEAD is now at b5d997f... Merge pull request #867 from nvt/fix-rpl-ext-header-removal
	[+] Compiling with effectivesan at /home/benchng/validation/harness/. --
 	[+] Build target at 8340735cf5.
Previous HEAD position was b5d997f... Merge pull request #867 from nvt/fix-rpl-ext-header-removal
HEAD is now at 8340735... Merge pull request #871 from nvt/check-uip-len
	[+] Compiling with effectivesan at /home/benchng/validation/harness/. --
 - Targets ready.... - Check inputs...
 -- Report inputs exposed by a target -- 

[+] Execute 499 inputs
.xx.xx.xxxx..xx..xx..xx..x............................................................................................................................................................................................................................................................................................................................................................x.....................x.............................x.........x..............................................................
[+] contiki-ground-truth.effectivesan exposed 19 bad inputs in /home/benchng//files-to-validate/inputs [+]

 -- Report inputs exposed by a target -- 

[+] Execute 499 inputs
.xx.xx.xxxx..xx..xx..xx..x............................................................................................................................................................................................................................................................................................................................................................x.....................x......................................................................................................
[+] contiki-ground-truth.effectivesan exposed 17 bad inputs in /home/benchng//files-to-validate/inputs [+]
Done: 2 witnesses detected.
[+] Triage witnesses [+]
Done.
```
>output

Trial report and witnesses are in `${WORKPATH}/test/FC-with-EffSan/uip-len/afl-gcc/corpuses_run10/validation`:

```
cat ${WORKPATH}/test/FC-with-EffSan/uip-len/afl-gcc/corpuses_run10/validation/uip-len-witnesses.txt 
c    contiki-ground-truth.effectivesan id:000207,src:000189,op:havoc,rep:4                                                        2655
c    contiki-ground-truth.effectivesan id:000212,sync:afl-master,src:000207                                                       2657
```

Once the validation ended, run the overview printer:

```
perl ${WORKPATH}/corpuses/docker/collect_campaign_witnesses.pl -input=${WORKPATH}/test/FC-with-EffSan/uip-len
```

>output
```
 
 -- Campaign Witnesses Collector -- 

[+] Collect 8 tools and 10 trials
-- afl-clang-fast                :timeout    :timeout    :1431       :timeout    :timeout    :850        :3478       :timeout    :831        :758        :
-- afl-gcc                       :2945       :timeout    :timeout    :1433       :1335       :timeout    :53615      :1129       :25795      :2655       :
-- angora                        :33233      :timeout    :49609      :1025       :5315       :timeout    :1509       :1707       :1012       :1189       :
-- honggfuzz                     :timeout    :timeout    :timeout    :timeout    :timeout    :timeout    :timeout    :timeout    :timeout    :timeout    :
-- intriguer                     :849        :813        :3599       :timeout    :7654       :1508       :785        :859        :timeout    :731        :
-- mopt                          :timeout    :timeout    :timeout    :timeout    :timeout    :829        :1099       :1163       :timeout    :27058      :
-- qsym                          :2722       :1651       :14091      :952        :6223       :6141       :3331       :1086       :timeout    :timeout    :
-- symcc                         :1190       :1237       :789        :6544       :933        :906        :timeout    :970        :896        :768        :
-----------------
-- afl-clang-fast                :       5:1470   (00:24:30)
-- afl-gcc                       :       7:12701  (03:31:41)
-- angora                        :       8:11825  (03:17:05)
-- honggfuzz                     :       0:0      (00:00:00)
-- intriguer                     :       8:2100   (00:35:00)
-- mopt                          :       4:7537   (02:05:37)
-- qsym                          :       8:4525   (01:15:25)
-- symcc                         :       9:1581   (00:26:21)
-----------------
I found 4 different stack traces
Unique witness set:
In: /Users/poncelet/ase22_contiki-ng-benchmark_artifact/test/FC-with-EffSan/uip-len/afl-clang-fast/corpuses_run7/validation/before_uip-len/triage/3249274650.san-stacktrace
id:000148,sync:afl-slave,src:000151 -- 
In: /Users/poncelet/ase22_contiki-ng-benchmark_artifact/test/FC-with-EffSan/uip-len/afl-clang-fast/corpuses_run10/validation/before_uip-len/triage/3174791183.san-stacktrace
id:000150,src:000144,op:havoc,rep:16 -- 
In: /Users/poncelet/ase22_contiki-ng-benchmark_artifact/test/FC-with-EffSan/uip-len/afl-clang-fast/corpuses_run6/validation/before_uip-len/triage/1546341169.san-stacktrace
id:000175,sync:afl-slave,src:000179,+cov -- 
In: /Users/poncelet/ase22_contiki-ng-benchmark_artifact/test/FC-with-EffSan/uip-len/afl-clang-fast/corpuses_run3/validation/before_uip-len/triage/2444726330.san-stacktrace
id:000142,src:000138+000012,op:splice,rep:16 -- 
```
>output 

You can see the witnesses detected by EffectiveSanitizer from the corpuses of uIP-len of Section 3.

—

# Docker 

* [docker help](https://docs.docker.com/engine/reference/commandline/cli/)
    
* `docker ps`: lists (running) containers – add option `-a` to include stopped containers.
    
* `docker rm`: remove one or more containers.
    
* `docker images`: lists (built) images.
    
* `docker rmi`: remove one or more images.
    
* `docker rm $(docker ps -a -q)`: remove all stopped containers (without stopping the running ones).