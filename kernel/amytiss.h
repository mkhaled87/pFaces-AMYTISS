/*
* pfacesKernel_amytiss.h
*
*  created on: 28.04.2019
*      author: M. Khaled
*/

#ifndef _KERNEL_AMYTISS_H_
#define _KERNEL_AMYTISS_H_

/* pfaces related include files */
#define _PFACES_INCLUDE_SYMBOLIC_LIBRARY
#include <pfaces-sdk.h>
#include "amytissPDFs.h"

namespace amytiss{

	/**********************************************************/
	// some defines needed throughout the kernel source
	/**********************************************************/
	/* identifing name of the kernel */
	#define AMYTISS_KERNEL_NAME "amytiss"

	/* the functions in the kernel and their arguemeents */
	#define AMYTISS_KERNEL_FUNC_ABSTRACT_INDEX 0
	#define AMYTISS_KERNEL_FUNC_ABSTRACT_NAME "abstract"
	#define AMYTISS_KERNEL_FUNC_ABSTRACT_NUM_ARGS 1
	#define AMYTISS_KERNEL_FUNC_ABSTRACT_ARG_XU_BAG_INDEX 0
	#define AMYTISS_KERNEL_FUNC_ABSTRACT_ARG_XU_BAG_NAME "XU_bags"

	#define AMYTISS_KERNEL_FUNC_SYNTHESIZE_INDEX 1
	#define AMYTISS_KERNEL_FUNC_SYNTHESIZE_NAME "synthesize"
	#define AMYTISS_KERNEL_FUNC_SYNTHESIZE_NUM_ARGS 2
	#define AMYTISS_KERNEL_FUNC_SYNTHESIZE_ARG_XU_BAG_INDEX 0
	#define AMYTISS_KERNEL_FUNC_SYNTHESIZE_ARG_XU_BAG_NAME "XU_bags"
	#define AMYTISS_KERNEL_FUNC_SYNTHESIZE_ARG_V_INDEX 1
	#define AMYTISS_KERNEL_FUNC_SYNTHESIZE_ARG_V_NAME "V"

	#define AMYTISS_KERNEL_FUNC_COLLECT_INDEX 2
	#define AMYTISS_KERNEL_FUNC_COLLECT_NAME "collect"
	#define AMYTISS_KERNEL_FUNC_COLLECT_NUM_ARGS 2
	#define AMYTISS_KERNEL_FUNC_COLLECT_ARG_XU_BAG_INDEX 0
	#define AMYTISS_KERNEL_FUNC_COLLECT_ARG_XU_BAG_NAME "XU_bags"
	#define AMYTISS_KERNEL_FUNC_COLLECT_ARG_V_INDEX 1
	#define AMYTISS_KERNEL_FUNC_COLLECT_ARG_V_NAME "V"

	/* The kernel variable patameters to be updated before compilation */
	#define AMYTISS_KERNEL_PARAM_EXTRA_INC_FILES "@@EXTRA_INC_FILES@@"
	#define AMYTISS_KERNEL_PARAM_CONCRETE_DATA_TYPE "@@CONCRETE_DATA_TYPE@@"
	#define AMYTISS_KERNEL_PARAM_SYMBOLIC_DATA_TYPE "@@SYMBOLIC_DATA_TYPE@@"
	#define AMYTISS_KERNEL_PARAM_SSDIM "@@SSDIM@@"
	#define AMYTISS_KERNEL_PARAM_ISDIM "@@ISDIM@@"
	#define AMYTISS_KERNEL_PARAM_WSDIM "@@WSDIM@@"
	#define AMYTISS_KERNEL_PARAM_SSETA "@@SSETA@@"
	#define AMYTISS_KERNEL_PARAM_ISETA "@@ISETA@@"
	#define AMYTISS_KERNEL_PARAM_WSETA "@@WSETA@@"
	#define AMYTISS_KERNEL_PARAM_SSLB "@@SSLB@@"
	#define AMYTISS_KERNEL_PARAM_ISLB "@@ISLB@@"
	#define AMYTISS_KERNEL_PARAM_WSLB "@@WSLB@@"
	#define AMYTISS_KERNEL_PARAM_SSUB "@@SSUB@@"
	#define AMYTISS_KERNEL_PARAM_ISUB "@@ISUB@@"
	#define AMYTISS_KERNEL_PARAM_WSUB "@@WSUB@@"
	#define AMYTISS_KERNEL_PARAM_SS_WIDTHS "@@SSWIDTHS@@"
	#define AMYTISS_KERNEL_PARAM_IS_WIDTHS "@@ISWIDTHS@@"
	#define AMYTISS_KERNEL_PARAM_WS_WIDTHS "@@WSWIDTHS@@"
	#define AMYTISS_KERNEL_PARAM_SS_NUMSYM "@@SSNUMSYM@@"
	#define AMYTISS_KERNEL_PARAM_IS_NUMSYM "@@ISNUMSYM@@"
	#define AMYTISS_KERNEL_PARAM_WS_NUMSYM "@@WSNUMSYM@@"
	#define AMYTISS_KERNEL_PARAM_DEFINE_SAVE_P_MATRIX "@@DEFINE_SAVE_P_MATRIX@@"
	#define AMYTISS_KERNEL_PARAM_DEFINE_HAS_TARGET "@@DEFINE_HAS_TARGET@@"
	#define AMYTISS_KERNEL_PARAM_TARGET_DATA "@@TARGET_DATA@@"
	#define AMYTISS_KERNEL_PARAM_DEFINE_HAS_SAFE "@@DEFINE_HAS_SAFE@@"
	#define AMYTISS_KERNEL_PARAM_POST_DYNAMICS_CONSTANTS "@@POST_DYNAMICS_CONSTANTS@@"
	#define AMYTISS_KERNEL_PARAM_POST_DYNAMICS_BEFORE "@@POST_DYNAMICS_CODE_BEFORE@@"
	#define AMYTISS_KERNEL_PARAM_POST_DYNAMICS_BODY "@@POST_DYNAMICS_BODY@@"
	#define AMYTISS_KERNEL_PARAM_POST_DYNAMICS_AFTER "@@POST_DYNAMICS_CODE_AFTER@@"
	
	#define AMYTISS_KERNEL_PARAM_PDF_DEFINES "@@PDF_DEFINES@@"
	#define AMYTISS_KERNEL_PARAM_PDF_FUNCTION_BODY "@@PDF_FUNCTION_BODY@@"

	#define AMYTISS_KERNEL_PARAM_TIME_STEPS "@@TIME_STEPS@@"
	#define AMYTISS_KERNEL_PARAM_HAS_CONTROL_BYTES "@@HAS_CONTROL_BYTES@@"
	#define AMYTISS_KERNEL_PARAM_CONTROL_BYTES "@@CONTROL_BYTES@@"
	#define AMYTISS_KERNEL_PARAM_PDF_BASE_VOLUME "@@PDF_BASE_VOLUME@@"
	#define AMYTISS_KERNEL_PARAM_TARGET_SET_LB "@@TARGET_SET_LB@@"
	#define AMYTISS_KERNEL_PARAM_TARGET_SET_UB "@@TARGET_SET_UB@@"
	#define AMYTISS_KERNEL_PARAM_TARGET_SET_WIDTHS "@@TARGET_SET_WIDTHS@@"
	#define AMYTISS_KERNEL_PARAM_TARGET_SET_NUM_SYMBOLS "@@TARGET_SET_SYMBOLS_COUNT@@"
	#define AMYTISS_KERNEL_PARAM_DEFINE_HAS_AVOID "@@DEFINE_HAS_AVOID@@"
	#define AMYTISS_KERNEL_PARAM_AVOID_DATA "@@AVOID_DATA@@"


	/* the keys of the configuration parameters in the configuation file */
	#define AMYTISS_CONFIG_PARAM_project_name	"project_name"	
	#define AMYTISS_CONFIG_PARAM_include_files	"include_files"
	#define AMYTISS_CONFIG_PARAM_data	"data"
	#define AMYTISS_CONFIG_PARAM_save_transitions	"save_transitions"
	#define AMYTISS_CONFIG_PARAM_save_controller	"save_controller"
	#define AMYTISS_CONFIG_PARAM_states_dim	"states.dim"
	#define AMYTISS_CONFIG_PARAM_states_eta	"states.eta"
	#define AMYTISS_CONFIG_PARAM_states_lb	"states.lb"
	#define AMYTISS_CONFIG_PARAM_states_ub	"states.ub"
	#define AMYTISS_CONFIG_PARAM_inputs_dim	"inputs.dim"
	#define AMYTISS_CONFIG_PARAM_inputs_eta	"inputs.eta"
	#define AMYTISS_CONFIG_PARAM_inputs_lb	"inputs.lb"
	#define AMYTISS_CONFIG_PARAM_inputs_ub	"inputs.ub"
	#define AMYTISS_CONFIG_PARAM_disturbances_dim	"disturbances.dim"
	#define AMYTISS_CONFIG_PARAM_disturbances_eta	"disturbances.eta"
	#define AMYTISS_CONFIG_PARAM_disturbances_lb	"disturbances.lb"
	#define AMYTISS_CONFIG_PARAM_disturbances_ub	"disturbances.ub"
	#define AMYTISS_CONFIG_PARAM_post_dynamics_constant_values	"post_dynamics.constant_values"
	#define AMYTISS_CONFIG_PARAM_post_dynamics_code_before	"post_dynamics.code_before"
	#define AMYTISS_CONFIG_PARAM_post_dynamics_xx	"post_dynamics.xx"
	#define AMYTISS_CONFIG_PARAM_post_dynamics_code_after	"post_dynamics.code_after"
	#define AMYTISS_CONFIG_PARAM_specs_type	"specs.type"
	#define AMYTISS_CONFIG_PARAM_specs_hyperrect "specs.hyperrect"
	#define AMYTISS_CONFIG_PARAM_specs_time_steps "specs.time_steps"
	#define AMYTISS_CONFIG_PARAM_specs_type_value_safe	"safe"
	#define AMYTISS_CONFIG_PARAM_specs_type_value_reach	"reach"
	#define AMYTISS_CONFIG_PARAM_specs_avoid_hyperrect "specs.avoid_hyperrect"


	// the key names of the metadata in the output fiiles
	#define OUT_FILE_PARAM_SS_DIMENSION "ss-dimension"
	#define OUT_FILE_PARAM_IS_DIMENSION "is-dimension"
	#define OUT_FILE_PARAM_WS_DIMENSION "ws-dimension"
	#define OUT_FILE_PARAM_SS_ETA "ss-eta"
	#define OUT_FILE_PARAM_SS_STEPS "ss-steps"
	#define OUT_FILE_PARAM_IS_ETA "is-eta"
	#define OUT_FILE_PARAM_IS_STEPS "is-steps"
	#define OUT_FILE_PARAM_WS_ETA "ws-eta"
	#define OUT_FILE_PARAM_WS_STEPS "ws-steps"
	#define OUT_FILE_PARAM_SS_LB "ss-lower-point"
	#define OUT_FILE_PARAM_SS_UB "ss-upper-point"
	#define OUT_FILE_PARAM_IS_LB "is-lower-point"
	#define OUT_FILE_PARAM_IS_UB "is-upper-point"
	#define OUT_FILE_PARAM_WS_LB "ws-lower-point"
	#define OUT_FILE_PARAM_WS_UB "ws-upper-point"
	#define OUT_FILE_PARAM_X_WIDTH "x-width"
	#define OUT_FILE_PARAM_U_WIDTH "u-width"
	#define OUT_FILE_PARAM_W_WIDTH "w-width"
	#define OUT_FILE_PARAM_XU_BAG_SIZE "xu-bag-size"
	#define OUT_FILE_PARAM_IS_P_SAVED "is-p-saved"
	#define OUT_FILE_PARAM_NUM_REACH_STATES "num-reach-states"
	#define OUT_FILE_PARAM_TIME_STEPS "time-steps"
	#define OUT_FILE_PARAM_CONCRETE_NAME "concrete-data-name"
	#define OUT_FILE_PARAM_CONCRETE_SIZE "concrete-data-size"
	#define OUT_FILE_PARAM_SYMBOLIC_NAME "symbolic-data-name"
	#define OUT_FILE_PARAM_SYMBOLIC_SIZE "symbolic-data-size"
	#define OUT_FILE_PARAM_SS_STATE_VAR_POST "xx%NUM%-post"
	#define OUT_FILE_PARAM_SS_STATE_VAR_NUMBER_TOKEN "%NUM%"
	#define OUT_FILE_PARAM_USED_KERNEL_NAME "used-kernel-name"
	#define OUT_FILE_PARAM_SPECS_TYPE "specs-type"
	#define OUT_FILE_PARAM_SPECS_TARGET_SET "specs-target-set"
	#define OUT_FILE_PARAM_SPECS_SAFE_SET "specs-safe-set"
	#define OUT_FILE_PARAM_ORG_CUTTING_REGION_LB "org-cutting-region-lb"
	#define OUT_FILE_PARAM_ORG_CUTTING_REGION_UB "org-cutting-region-ub"
	#define OUT_FILE_PARAM_SPECS_TYPE "specs-type"
	#define OUT_FILE_PARAM_SPECS_TARGET_HYPERRECT "target-hyperrect"
	#define OUT_FILE_PARAM_SPECS_AVOID_HYPERRECT "avoid-hyperrect"


	/**********************************************************/
	// structs for representing the low-level data bags
	/**********************************************************/
	// the XU_bag : a bag for each (x,u) element in the 2D XU space.
	struct 
	XU_bag {
		public:
		static inline size_t getNumControlBytes(size_t time_steps) {
			if(time_steps == 0) return 0;
			return (size_t)(std::ceil((double)time_steps / 8.0l));
		}
		static inline size_t getSize(bool saveP, size_t maxPostStates, size_t time_steps, bool saveController, size_t numWsymbols){
			size_t mem = 0;

			/* for each (x,u) a list of min/max probabilities to reach all cutting_bound states */
			if (saveP) {
				mem += numWsymbols * maxPostStates * sizeof(concrete_t);
			}
				

			/* for each (x,u) a value for V_int */
			mem += sizeof(concrete_t);

			/* for each (x,u) a string og bits each represeting the applicability of u in x in the time step */
			if(saveController)
				mem += getNumControlBytes(time_steps);

			return mem;
		}
	};


	/**********************************************************/
	// pfacesKernel_amytiss
	/**********************************************************/
	class amytissKernel : public pfaces2DKernel {
	private:

		// the configuration reader
		const std::shared_ptr<pfacesConfigurationReader> m_spCfg;

		// management stuff
		bool singletonInput = false;
		bool singletonDisturbance = false;
		bool ssWasMisAlignedFlag = false;
		bool isWasMisAlignedFlag = false;
		bool wsWasMisAlignedFlag = false;

		// noise stuff
		size_t time_steps;
		bool saveP;	
		bool saveC;

		// extra include files for the CL code
		std::string extra_inc_dir;

		// per-job per-task sub-buffer for func-0/arg-0
		std::vector<std::pair<size_t, size_t>> subBuffersAbstractRWBag;
		std::vector<std::pair<size_t, size_t>> subBuffersSznthesizeRWBag;
		std::vector<std::pair<size_t, size_t>> subBuffersCollectV;

		// some private functions
		std::string amytissGetPdfAsCFunctionBody();
		std::string amytissGetPdfDefines();

	public:
		/* some vars for local storage */
		bool SafetyOrReachability;
		size_t ssDim, isDim, wsDim;
		std::vector<concrete_t> ssEta, ssLb, ssUb, isEta, isLb, isUb, wsEta, wsLb, wsUb;
		size_t num_reach_states;
		flat_t xSpaceFlatWidth, uSpaceFlatWidth, wSpaceFlatWidth;
		std::vector<symbolic_t> xSpacePerDimWidth, uSpacePerDimWidth, wSpacePerDimWidth;

		/* the cutting bould including the effect of W */
		std::vector<concrete_t> orgCuttingBoundsLb, orgCuttingBoundsUb;

		// the PDF object
		std::shared_ptr<amytissPDF> spPdfObj;

		/* the kernel functions */
		amytissKernel(const std::shared_ptr<pfacesKernelLaunchState>& spLaunchState, 
			const std::shared_ptr<pfacesConfigurationReader>& spCfg);
		~amytissKernel() = default;
	
		void configureParallelProgram(pfacesParallelProgram& parallelProgram);
		void configureTuneParallelProgram(pfacesParallelProgram& tuneParallelProgram, size_t targetFunctionIdx);
	};

}

#endif
