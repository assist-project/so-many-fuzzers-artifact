# Artifact of the ASE'2022 Paper "_So Many Fuzzers, So Little Time - Experience from Evaluating Fuzzers on the Contiki-NG Network (Hay)Stack_"

[![DOI](https://zenodo.org/badge/518939596.svg)](https://zenodo.org/badge/latestdoi/518939596)

This repository contains the artifact for the
[ASE'2022 paper](https://doi.org/10.1145/3551349.3556946)
with the title mentioned above.
The paper contains detailed experiments from using eight mutation-based
and hybrid fuzzers on different configurations of Contiki-NG Network Stack.
We remark that most of the experiments take long time to finish (for the
paper's results, we ran fuzzers for several 24-hour experiments) and, due
to the nature of the fuzzers we have used, the results are non-deterministic.

Among the artifact's contents you can find:
- The (tarred) raw `data` that we used to create Tables 3 to 12.
  These are provided as `.csv` files and a corpus folder.
- A folder `src` with the fuzzing framework that we used to launch
  fuzzing campaigns with the paper's configurations.
  This framework contains:
    - Dockerfile configurations;
    - scripts to run fuzzing campaigns for a particular fuzzer
      configuration and a Contiki-NG vulnerability;
    - scripts to validate witnesses and print raw data similar to
      those formatted in the paper.

The instructions on how to install and run the experiments can be
found in the file [INSTALL.md](INSTALL.md).

