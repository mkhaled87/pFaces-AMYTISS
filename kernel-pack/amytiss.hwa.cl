/*
* amytiss.cpu.cl
*
*  date    : 28.04.2019
*  author  : M. Khaled | Hybrid control systems @ Technical University of Munich, Germany
*  about   : an OpenCL kernel (optimized for HWAs) used to of the tool AMYTISS.
*            AMYTISS is a tool for an abstractuin based synthesis of stochastic systems.
* ***********************************************************************
*  The kernel manager will replace parameters enclosed by "@@" before compiling !
*/

#define HWA_VERSION
#include "pfaces.cl"

@@EXTRA_INC_FILES@@

// pfaces-Including some functions for quantization
@pfaces-include:"amytiss_quantizer.cl"

// pfaces-Including a parameters and some funcs
@pfaces-include:"amytiss_utils.cl"

// pFaces-Including a KERNEL-Function: ABSTRACT
@pfaces-include:"amytiss_abstract.cl"

// pFaces-Including a KERNEL-Function: SYNTHESIZE
@pfaces-include:"amytiss_synthesize.cl"
