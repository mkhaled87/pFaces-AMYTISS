# **AMYTISS**: Prallel Automated Controller Synthesis for Large-scale Stocchastic Systems  

Stochastic control systems are recently used to model and analyze various safety-critical systems such as traffic networks and self-driving cars.
**AMYTISS** is introduced as a software tool, implemented as a kernel on top of the acceleration ecosystem [pFaces](http://www.parallall.com/pfaces), for designing correct-by-construction controllers of stochastic discrete-time systems.

AMYTISS is used to:

- build finite Markov decision processes (MDPs) as finite abstractions of given original stochastic discrete-time systems; and  

- synthesize controllers for the constructed finite MDPs satisfying bounded-time safety specifications and reach-avoid specifications.

In AMYTISS, scalable parallel algorithms are designed to construct finite MDPs and to synthesize their controllers. They are implemented on top of pFaces as a kernel that supports parallel execution within CPUs, GPUs and hardware accelerators (HWAs). 

# **Installation**

## **Prerequisites**

### pFaces

You first need to have have [pFaces](http://www.parallall.com/pfaces) installed and working. Test the installation of pFaces and make sure it recognizes the parallel hardware in your machine by running the following command:

```
pfaces -CGH -l
```

where **pfaces** calls pFaces launcher as installed in your machine. This should list all available HW configurations attached to your machine and means you are ready to work with AMYTISS.

```
pfaces -CGH -l
```

### Build tools

AMYTISS is given as source code that need to be built one time. This requires a modern C/C++ compiler such as:

- For windows: Microsoft Visual Studio (2019 is recommended);
- For Linu/MacOS: GCC/G++.

## **Building AMYTISS**

If you will be using Windows, open the provided project file [amytiss-kernel.sln](amytiss-kernel.sln) from inside Visual Studio and build it using the **Release (x64)** configuration. Building with Debug configuration will result in a slower operation and requires having the debug binaries of pFaces.

If you will be using Linux or MacOS, assuming you have a GIT client, simply run the following command to clone this repo:

```
$ git clone --depth=1 https://github.com/mkhaled87/pFaces-AMYTISS

```

AMYTISS requires to link with pFaces SDK. The environment variable **PFACES_SDK_ROOT** should point to pFaces SDK root directory. Make sure you have the environment variable **PFACES_SDK_ROOT** pointing to the full absolute pFaces SDK forlder. If not, do it as follows:

```
$ export PFACES_SDK_ROOT=/full/path/to/pfaces-sdk

```

Now navigate to the created repo folder and build AMYTISS:

```
$ cd amytiss
$ make
```

## **Getting Started**

Now, you have AMYTISS installed and ready to be used. You might now run a given example or build your own.

### **File structure of AMYTISS**

- [examples](/examples): the folder contains pre-designed examples.
- [interface](/interface): the folder contains the Matlab interface to access the files genrated by AMYTISS.
- [kernel](/kernel): the folder C++ source codes of AMYTISS.
- [kernel-pack](/kernel-pack): the folder contains the OpenCL codes of the AMYTISS and will hold the binaries of the loadable kernel of AMYTISS.

### **Running an example**

Navigate to any of the examples in the directoy [/examples](/examples). Within each example, one or more .cfg files are provided. Config files tells AMYTISS about the system underconsideration and the requirements it should consider when desiging a controller for the system.

Say you navigated to the example in [/examples/ex_toy_safety](/examples/ex_toy_safety) and you want to launch AMYTISS with the config file [toy2d.cfg](/examples/ex_toy_safety/toy2d.cfg), then run the following command from any terminal located in the example foder:

```
pfaces -CGH -d 1 -k amytiss@../../kernel-pack -cfg toy2d.cfg -p
```

where **pfaces** calls pFaces launcher, "-CGH -d 1" asks pFaces to run AMYTISS in the first device of all avaialble deveices, "-k amytiss@../../kernel-pack" tells pFaces about AMYTISS and where it is located, "-cfg toy2d.cfg" asks pFaces to hand the configuration file to AMYTISS, and "-p" asks pFaces to collect profiling information. Make sure to replace each / with \ in case you are using Windows command line.

### **Building your own example**

We recommend copying and modifing one of the provided examples to avoid syntactical mistakes.

## **The configuration files**

Each configuration file corresponds to a case describing a stochastic system and the requirements to be used to synthesize a controller for it. Config files are text files with scopes 'scope_name { contents }', where the contents is a list of ;-demilited key="value" pairs. Take a look to this [config](/examples/ex_toy_safety/toy2d.cfg) file for an example. The following are the keys that can be used in AMYTISS. Note that values need to be enclosed woith double quotes.


- **project_name**: a to describe the name of the project (the case) and will be used as name for output files.
- **data**: describes the used data model and should be currently set to "raw".
- **save_transitions**: a "true" or "false" value that instructs AMYTISS to construct and save the MDP or ignro it and do the computation on the fly.
- **save_controller**: a "true" or "false" value that instructs AMYTISS to save the controller or not.
- For the scopes **states**, **inputs**, or **disturbances**:
    - **dim**: an integer decclaring the dimension.
    - **lb**: a comma-separated list giving the top-right corner vector.
    - **ub**: a comma-separated list giving the bottom-left corner vector.
- For the scope **post_dynamics**, which describes the system:
    - **xx0** to **xx21**: the left-hand-side of each component of the difference equation of the system.
    - **constant_values**: a single line C code declaring constant values. The code line, or any internal lines, should end with ;.
    - **code_before** and **code_after**: single lines of C code that will preceed or succeed the dynamics **xx0** to **xx21**.
- For the scope **noise**, which describes the noise:
    - **inv_covariance_matrix**: the inverse of the covariance matrix $\Sigma$ as list of values. You can provide states.dim^2 values which refers to the complete matrix or provide states.dim values which refers to the diagonal of a diagonal covarianca matrix.
    - **det_covariance_matrix**: the determinent of the covariance matrix. This should be consisiten with the covariance matrix and follows (det_covariance_matrix = det(inv(inv_covariance_matrix))). We were lazy to compute this and we ask the users to provide. Sorry !
    - **cutting_probability**: provide a value for cuttting the PDF at some probability level to reduce the memory needed to store the post states in the MDP. Setting it to "0" means no cutting bound and asks AMYTISS to store all transitions. Provide this value or provide **cutting_region** not both at the same time.
    - **cutting_region**: a comma-separated list of lower/upper values for each component of the states.dim components. This sets explitly the cutting region of the PDF. Provide this value or provide **cutting_probability** not both at the same time.
- For the scope **specs**, which describes the specifications:
    - **type**: the targeted speccifications and can be "safe" for safety or "reach" for reachability.
    - **hyperrect**: a comma-separated list of lower/upper values for each component of the states.dim components describing the safe region or the target region, for safety or reacchability specifications, respectively.
    - **avoid_hyperrect** in case type="raech", this comma-separated list of lower/upper values for each component of the states.dim components describes the avoid set.
    - **time_steps**: the time bound $T_d$ to satisfy the specifictions


## **Authors**

- [**Mahmoud Khaled**](http://www.mahmoud-khaled.com)*.
- [**Abolfazl Lavaei**](http://www.hyconsys.com/members/lavaei)*.
- [**Majid Zamani**](http://www.hyconsys.com/members/mzamani).

*: Both authors have the same contribution.

## **License**

See the [LICENSE](LICENSE) file for details
