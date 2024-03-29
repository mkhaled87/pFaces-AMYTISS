/* the diemnsions of the state space, input spcae, and disturvance state */
#define ssDim @@SSDIM@@
#define isDim @@ISDIM@@
#define wsDim @@WSDIM@@

/* quantizations and bounds for the ss, is and ws*/
#define SS_ETA_LIST {@@SSETA@@}
#define IS_ETA_LIST {@@ISETA@@}
#define WS_ETA_LIST {@@WSETA@@}
#define SS_LB_LIST {@@SSLB@@}
#define IS_LB_LIST {@@ISLB@@}
#define WS_LB_LIST {@@WSLB@@}
#define SS_UB_LIST {@@SSUB@@}
#define IS_UB_LIST {@@ISUB@@}
#define WS_UB_LIST {@@WSUB@@}
#define SS_WIDTHS_LIST {@@SSWIDTHS@@}
#define IS_WIDTHS_LIST {@@ISWIDTHS@@}
#define WS_WIDTHS_LIST {@@WSWIDTHS@@}
#define SS_NUM_SYBOLS @@SSNUMSYM@@
#define IS_NUM_SYBOLS @@ISNUMSYM@@
#define WS_NUM_SYBOLS @@WSNUMSYM@@

/* here will come a define to control wheather we will save the P matricies or compute them on the fly */
@@DEFINE_SAVE_P_MATRIX@@

/* indicatiors for whether this is a reacchability problem of a safety problem */
@@DEFINE_HAS_TARGET@@
@@DEFINE_HAS_SAFE@@
@@DEFINE_HAS_AVOID@@


#ifdef HAS_TARGET
	#ifdef HAS_SAFE
		#error "This kernel works either for safety specification or reachibility specification not both at the same time"
	#endif
#endif

#ifdef HAS_SAFE
	#ifdef HAS_AVOID
		#error "Avoid set is only valid with reachability specifications (i.e., reach-avoid)!"
	#endif
#endif


/* in case this is a reachability problem */
#ifdef HAS_TARGET
#define TARGET_SET_LB {@@TARGET_SET_LB@@}
#define TARGET_SET_UB {@@TARGET_SET_UB@@}
#define TARGET_SET_WIDTHS {@@TARGET_SET_WIDTHS@@}
#define TARGET_SET_NUM_SYMBOLS @@TARGET_SET_SYMBOLS_COUNT@@
char is_target(const concrete_t* x);
char is_target(const concrete_t* x) {
	concrete_t  target[ssDim][2] = { @@TARGET_DATA@@};
	for (unsigned int i = 0; i < ssDim; i++) {
		if (x[i]<target[i][0] || x[i]>target[i][1]) {
			return 0;
		}
	}
	return 1;
}
#endif

/* in case there is a set to be avoided */
#ifdef HAS_AVOID
char is_avoid(const concrete_t * x);
char is_avoid(const concrete_t * x) {
	concrete_t  avoid[ssDim][2] = {@@AVOID_DATA@@};
	for (unsigned int i = 0; i < ssDim; i++) {
		if (x[i]<avoid[i][0] || x[i]>avoid[i][1]) {
			return 0;
		}
	}
	return 1;
}
#endif


/* deffines for states, inputs and disturbances to make life easier (add more if needed) */
#define x0 x[0]
#define x1 x[1]
#define x2 x[2]
#define x3 x[3]
#define x4 x[4]
#define x5 x[5]
#define x6 x[6]
#define x7 x[7]
#define x8 x[8]
#define x9 x[9]
#define x10 x[10]
#define x11 x[11]
#define x12 x[12]
#define x13 x[13]
#define x14 x[14]
#define x15 x[15]
#define x16 x[16]
#define x17 x[17]
#define x18 x[18]
#define x19 x[19]
#define x20 x[20]
#define x21 x[21]


#define u0 u[0]
#define u1 u[1]
#define u2 u[2]
#define u3 u[3]
#define u4 u[4]
#define u5 u[5]

#if isDim > 6
	#error "Please change the defines for the inputs above to accommodate for more input variables."
#endif // isDim > 6

#define w0 w[0]
#define w1 w[1]
#define w2 w[2]
#define w3 w[3]
#define w4 w[4]
#define w5 w[5]

#if wsDim > 6
	#error "Please change the defines for the disturbances above to accommodate for more disturbance variables."
#endif // wsDim > 6


/* the dynamics post function without any noise : noise is assumed to be additive */
void post_dynamics(concrete_t* xx, const concrete_t* x, const concrete_t* u, const concrete_t* w);
void post_dynamics(concrete_t* xx, const concrete_t* x, const concrete_t* u, const concrete_t* w) {
	@@POST_DYNAMICS_CONSTANTS@@
	@@POST_DYNAMICS_CODE_BEFORE@@
	@@POST_DYNAMICS_BODY@@
	@@POST_DYNAMICS_CODE_AFTER@@
}

/* Defines for the PDF: the bounds of cutting region +  */
@@PDF_DEFINES@@

/* numer of time steps to solve the synthesis */
#define TIME_STEPS @@TIME_STEPS@@

/* number of control bytes */
@@HAS_CONTROL_BYTES@@
#define NUM_CONTROL_BYTES @@CONTROL_BYTES@@

/* a memory bag used for global memory (RW: Read/Write) : will be duplicated along XU 2D domain */
typedef struct __attribute__((packed)) xu_bag {
#ifdef SAVE_P_MATRIX
	concrete_t Pr[WS_NUM_SYBOLS][NUM_REACH_STATES];		/* the Probability (for-each w in W) (for-each post_state in the cutting-region) */
#endif
	concrete_t V_INT_MIN;								/* the min value (wrt w) of current (x,u) in the V_INT_MIN*/
#ifdef HAS_CONTROL_BYTES	
	char IS_CONTROL[NUM_CONTROL_BYTES];					/* flags, for each time step, if u is control action in x */
#endif
} xu_bag_t;


/* the probability density function of the noise at specific point x in the error space */
concrete_t pdf(const concrete_t* x);
concrete_t pdf(const concrete_t* x) {
	@@PDF_FUNCTION_BODY@@
}

/* the integration of the pdf based on an error region [err_lb, err_ub] */
concrete_t integratePdf(const concrete_t* err_lb, const concrete_t* err_ub);
concrete_t integratePdf(const concrete_t* err_lb, const concrete_t* err_ub) {

	__private concrete_t int_pdf;
	__private concrete_t e_base_diff;
	__private concrete_t e_base_volume;
	__private concrete_t e_base_center[ssDim];

	/* compute the volume/center of the base */
	e_base_volume = 1.0;
	for (unsigned int i = 0; i < ssDim; i++) {
		e_base_diff = err_ub[i] - err_lb[i];
		e_base_volume *= e_base_diff;
		e_base_center[i] = err_lb[i] + e_base_diff/2.0f;
	}

	/* using Mu as a the origin of the PDF(x) and computing the integration (probability)
	   at each state within the cutting region
	   here the intergration is approximated by a hyper rectangle from the ground level to the
	   PDF(x_post) value, where x_post is the center of the hyper rectangle */
	
	int_pdf = pdf(e_base_center) * e_base_volume;

	return int_pdf;
}

#ifdef SAVE_P_MATRIX
/* this function computes the min/max provavilities for the elements in the containing cutting region 
 * the idea is to consider all possible disturbances w in W and for each value we compute the Mu
 * then we construct the PDF around this Mu and compute the probabilites and we ccompare them against
 * a min/max values (i.e., compared to other w values). at the end, we have arrays of min/max prob 
 * values over all possible disturbances.
 */
void compute_probabilities(__global xu_bag_t* XU_bag, const concrete_t* x, const concrete_t* u);
void compute_probabilities(__global xu_bag_t* XU_bag, const concrete_t* x, const concrete_t* u){

	__private concrete_t ssEta[ssDim] = SS_ETA_LIST;
	__private concrete_t wsEta[wsDim] = WS_ETA_LIST;
	__private concrete_t wsLb[wsDim]  = WS_LB_LIST;
	__private concrete_t wsUb[wsDim]  = WS_UB_LIST;
	__private symbolic_t wsWidths[wsDim] = WS_WIDTHS_LIST;
	__private symbolic_t wSymbolsCount = WS_NUM_SYBOLS;
	__private symbolic_t w_symbolic[wsDim];
	__private concrete_t w_concrete[wsDim];
	__private concrete_t Mu[ssDim];
	__private concrete_t Mu_w0[ssDim];
	__private concrete_t containingCuttingRegionLb[ssDim] = CUTTING_REGION_LB;
	__private concrete_t containingCuttingRegionUb[ssDim] = CUTTING_REGION_UB;
	__private symbolic_t containingCuttingRegionWidths[ssDim] = CUTTING_REGION_WIDTHS;
	__private symbolic_t x_post_symbolic[ssDim];
	__private concrete_t x_post_concrete[ssDim];
	__private concrete_t x_post_concrete_lb[ssDim];
	__private concrete_t x_post_concrete_ub[ssDim];
	__private concrete_t pdf_error_lb[ssDim];
	__private concrete_t pdf_error_ub[ssDim];

#ifdef HAS_TARGET
	if (is_target(x)) {
		for (symbolic_t w = 0; w < wSymbolsCount; w++) {
			for (unsigned int i = 0; i < NUM_REACH_STATES; i++) {
				XU_bag->Pr[w][i] = 0.0;
			}
		}
		return;
	}
#endif
#ifdef HAS_AVOID
	if (is_avoid(x)) {
		for (symbolic_t w = 0; w < wSymbolsCount; w++) {
			for (unsigned int i = 0; i < NUM_REACH_STATES; i++) {
				XU_bag->Pr[w][i] = 0.0;
			}
		}
		return;
	}
#endif

	/* compute Mu when w=0 (possible post state without w effect) from current (x,u,w=0) */
	for (unsigned int  i = 0; i < wsDim; i++)
		w_concrete[i] = 0.0;
	post_dynamics(Mu_w0, x, u, w_concrete);

#ifndef PDF_NO_TRUNCATION
	/* shift the containing cutting region based on Mu with w = 0*/
	for (unsigned int i = 0; i < ssDim; i++) {
		containingCuttingRegionLb[i] += Mu_w0[i];
		containingCuttingRegionUb[i] += Mu_w0[i];
	}
#endif

	/* iterate over all disturbance posibilities */
	for (symbolic_t w = 0; w < wSymbolsCount; w++) {

		/* computing the symbolic and concrete values of current (w) */
		flat_to_symbolic(w_symbolic, wsDim, w, wsWidths);
		symbolic_to_concrete(w_concrete, wsDim, w_symbolic, wsLb, wsUb, wsEta);

		/* compute Mu (possible post state) from current (x,u,w) */
		post_dynamics(Mu, x, u, w_concrete);	

		// iterate over all reachable states in the cutting bound
		for (symbolic_t k = 0; k < NUM_REACH_STATES; k++) {

			/* computing the symbolic and concrete values of post-state */
			flat_to_symbolic(x_post_symbolic, ssDim, k, containingCuttingRegionWidths);
			symbolic_to_concrete(x_post_concrete, ssDim, x_post_symbolic, containingCuttingRegionLb, containingCuttingRegionUb, ssEta);

			/* compute the error wrt Mu: (x-Mu) in case of additive noise */
			for (unsigned int i = 0; i < ssDim; i++) {
				x_post_concrete_lb[i] = x_post_concrete[i] - ssEta[i]/2.0f;
				x_post_concrete_ub[i] = x_post_concrete[i] + ssEta[i]/2.0f;

			#ifndef PDF_MULTIPLICATIVE_NOISE
				pdf_error_lb[i] = x_post_concrete_lb[i]-Mu[i];
				pdf_error_ub[i] = x_post_concrete_ub[i]-Mu[i];
			#else
				pdf_error_lb[i] = (x_post_concrete_lb[i]-Mu[i])/x[i];
				pdf_error_ub[i] = (x_post_concrete_ub[i]-Mu[i])/x[i];
			#endif
			}

			/* using Mu as a the origin of the PDF(x) and computing the integration (probability) at each state within the cutting region */
			XU_bag->Pr[w][k] = integratePdf(pdf_error_lb, pdf_error_ub);
		}
	}

	return;
}
#endif