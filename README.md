# Artifact of the ASE'2022 Paper "_So Many Fuzzers, So Little Time - Experience from Evaluating Fuzzers on the Contiki-NG Network (Hay)Stack_"

This repository contains the artifact for the ASE'2022 paper with the
title mentioned above.
The paper contains detailed experiments from using eight mutation-based
and hybrid fuzzers on different configurations of Contiki-NG Network Stack.
We remark that most of the experiments take long time to finish (for the
paper's results, we ran fuzzers for several 24-hour experiments) and, due
to the nature of the fuzzers we have used, the results are non-deterministic.

For the artifact's evaluation, we provide:
 1. The raw data that we used to create Tables 3 to 12.
 2. The framework (Dockerfiles and scripts) to reproduce and launch fuzzing campaigns with the paper's configurations.
 3. A copy of the paper, as it was submitted to ASE'2022.
    (Note that this paper will be removed from the repo once the final revision of the paper is ready.)

The artifact itself consists of:
- The (tarred) raw `data` in the form of `.csv` files and a corpus folder.
- A folder `src` with the fuzzing framework that contains:
    - Dockerfile configurations;
    - scripts to run fuzzing campaigns for a particular fuzzer
      configuration and a Contiki-NG vulnerability;
    - scripts to validate witnesses and print raw data similar to
      those formatted in the paper.

The instructions on how to install and run the experiments can be
found in the file [INSTALL.md](INSTALL.md).

