# ARCH2020: AMYTISS code for ARCH-COMP20 Category Report: Stochastic Models

We provide the configuration files and unstructions to reproduce the results reported in
"ARCH 2020 Category Report: Stochastic Models". This has been tested on the following 
platforms:

1. AWS server (3 different instances), and 
2. Docker. 

## Quick start

### Requirements

- Local or Cloud-based machine with similar HW as reported in the report.
- OS: Linux (e.g., Ubuntu), Windows 10 or MacOs machine.
- If you will be building AMYTISS fom source code, install the following on the machine:
    - pFaces https://github.com/parallall/pFaces/
- If you will be using the provided Dockerfile:
    - Docker https://docs.docker.com/get-docker/

### How do I reproduce the results?

#### AWS server

1. Navigate to your AWS account and create a new instance. We used the following instances (non-free AWS instances) with Linux Ubuntu 18.04:
    a. m4.2xlarge
    b. c5.18xlarge
    c. p3.2xlarge
2. Install pFaces as described here: https://github.com/parallall/pFaces/wiki/Installation
3. Install AMYTISS as described here: https://github.com/mkhaled87/pFaces-AMYTISS
4. Navigate to AMYTISS's installation directory.
5. Navigate to the ARCH20 artifact direcotry:
    $ cd examples/arch20_artifact/
6. Each case-study has its separate directory. Navigate to any case-study (e.g., BAS):
    $ cd BAS
7. Run the case study using the provided run script (different for each case study but has the form run_amytiss_XXX.sh, where XXX is the name of the case-study):
    $ sh run_amytiss_bas.sh
8. Repeat the steps from 5 for other case studies.

#### Docker
Here, we assume you will be using a Linux machine. Commands will be slightly different on Windows if you use Windows PowerShell.

1. Make sure to configure Docker to use all of the resources available (e.g., all CPU cores). Otherwise, AMYTISS will run slower than expected. Also, in case you are using a GPU, make sure to pass-through the GPU in Docker. See this guide: https://docs.docker.com/config/containers/resource_constraints/.
2. Download the Dockerfile:
    $ mkdir amytiss
    $ cd amytiss
    $ wget https://raw.githubusercontent.com/mkhaled87/pFaces-AMYTISS/master/examples/arch20_artifact/Dockerfile.cfg
3. Build the Docker image:
    $ docker build -t arch20/amytiss .
4. Run/entrer the image
    $ docker run -it arch20/amytiss
5. The last command will take you to the interactive shell. Navigate to the case-studies directory:
    $ cd cd pFaces-AMYTISS/examples/arch20_artifact/
6. Each case-study has its separate directory. Navigate to any case-study (e.g., BAS):
    $ cd BAS
7. Run the case study using the provided run script (different for each case study but has the form run_amytiss_XXX.sh, where XXX is the name of the case-study). Note that we are using oclgrind here to emulate a platform/device inside the Docker image. If you passed-through your device (e.g., a GPU), you need to remove the oclgrind part of the command:
    $ oclgrind sh run_amytiss_bas.sh
8. Repeat the steps from 6 for other case studies.
