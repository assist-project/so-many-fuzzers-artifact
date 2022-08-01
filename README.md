# So Many Fuzzers, So Little Time - Experience Report from Evaluating Fuzzers on the Contiki-NG Network (Hay)Stack : Artifact

The paper depicts experiments of 8 mutation-based and hybrid fuzzers on different configurations of Contiki-NG Network Stack. For the artifact, we provide both the raw data used to create the Tables[3-12] and the framework (Dockerfiles + scripts) to reproduce and launch fuzzing campaigns with the paper's configurations.


More precisely, the artifact consists of:
- a folder `data`, the raw data in the form of .csv files and a corpus folder,
- a folder `benchmark`, the fuzzing framework containing:
    - Dockerfile configurations,
    - scripts to run fuzzing campaigns for a configuration and a Contiki-NG vulnerability,
    - scripts to validate witnesses and print raw_data as formatted into the paper.

Please, find the instructions in `INSTALL.md` to use the benchmark.
- link to the artifact: 
