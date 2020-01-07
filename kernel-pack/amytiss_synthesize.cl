/************************************************************************************************/
/************************************************************************************************/
/* KERNEL-Function: SYNTHESIZE	| runs on XU 													*/
/************************************************************************************************/
/************************************************************************************************/
__kernel void synthesize(__global xu_bag_t* XU_bags, __global concrete_t* V) {

	/* essential vars */
	__private symbolic_t x_flat;
	__private symbolic_t u_flat;
	__private symbolic_t flat_thread_idx;
	__private concrete_t v_int;
	__private concrete_t v_int_min;
	__private concrete_t p_val;

	__private concrete_t ssEta[ssDim] = SS_ETA_LIST;
	__private concrete_t ssLb[ssDim]  = SS_LB_LIST;
	__private concrete_t ssUb[ssDim]  = SS_UB_LIST;
	__private concrete_t isEta[isDim] = IS_ETA_LIST;
	__private concrete_t isLb[isDim]  = IS_LB_LIST;
	__private concrete_t isUb[isDim]  = IS_UB_LIST;	
	__private symbolic_t ssWidths[ssDim] = SS_WIDTHS_LIST;
	__private symbolic_t isWidths[isDim] = IS_WIDTHS_LIST;	
	__private symbolic_t x_symbolic[ssDim];
	__private concrete_t x_concrete[ssDim];			
	__private symbolic_t u_symbolic[isDim];
	__private concrete_t u_concrete[isDim];	
	__private concrete_t containingCuttingRegionLb_org[ssDim] = CUTTING_REGION_LB;
	__private concrete_t containingCuttingRegionUb_org[ssDim] = CUTTING_REGION_UB;
	__private symbolic_t containingCuttingRegionWidths[ssDim] = CUTTING_REGION_WIDTHS;
	__private concrete_t containingCuttingRegionLb[ssDim];
	__private concrete_t containingCuttingRegionUb[ssDim];
	__private concrete_t w_concrete[wsDim];
	__private concrete_t Mu_w0[ssDim];
	__private symbolic_t wSymbolsCount = WS_NUM_SYBOLS;
	__private concrete_t wsEta[wsDim] = WS_ETA_LIST;
	__private concrete_t wsLb[wsDim] = WS_LB_LIST;
	__private concrete_t wsUb[wsDim] = WS_UB_LIST;
	__private symbolic_t wsWidths[wsDim] = WS_WIDTHS_LIST;
	__private symbolic_t w_symbolic[wsDim];	
	__private symbolic_t x_post_symbolic[ssDim];
	__private concrete_t x_post_concrete[ssDim];
	__private concrete_t Mu[ssDim];	
#ifdef HAS_TARGET	
	__private concrete_t targetSetLb[ssDim] = TARGET_SET_LB;
	__private concrete_t targetSetUb[ssDim] = TARGET_SET_UB;
	__private symbolic_t targetSetWidths[ssDim] = TARGET_SET_WIDTHS;
#endif	

	/* flat x and u indicies come directly from the scheduler */
	x_flat = UNIVERSAL_INDEX_X;
	u_flat = UNIVERSAL_INDEX_Y;

	/* what is my memory position (including the case of sub-buffering) */
	flat_thread_idx = (u_flat - GLOBAL_OFFSET_Y) + (x_flat - GLOBAL_OFFSET_X) * PROCESS_WIDTH_Y;

	/* computing the symbolic and concrete values of current (x,u) */
	flat_to_symbolic(x_symbolic, ssDim, x_flat, ssWidths);
	flat_to_symbolic(u_symbolic, isDim, u_flat, isWidths);
	symbolic_to_concrete(x_concrete, ssDim, x_symbolic, ssLb, ssUb, ssEta);
	symbolic_to_concrete(u_concrete, isDim, u_symbolic, isLb, isUb, isEta);

#ifndef SAVE_P_MATRIX
#ifdef HAS_TARGET
	if (is_target(x_concrete)) {
		XU_bags[flat_thread_idx].V_INT_MIN = 0.0;
		return;
	}
#endif
#ifdef HAS_AVOID
	if (is_avoid(x_concrete)) {
		XU_bags[flat_thread_idx].V_INT_MIN = 0.0;
		return;
	}
#endif
#endif

	/* compute Mu when w=0 (possible post state without w effect) from current (x,u,w=0) */
	for (unsigned int  i = 0; i < wsDim; i++) 
		w_concrete[i] = 0.0;
	post_dynamics(Mu_w0, x_concrete, u_concrete, w_concrete);	

#ifdef HAS_AVOID
	if (is_avoid(Mu_w0)) {
		XU_bags[flat_thread_idx].V_INT_MIN = 0.0;
		return;
	}
#endif

	/* compute the containing cutting region based on Mu with w = 0*/
	for (unsigned int i = 0; i < ssDim; i++) {
		containingCuttingRegionLb[i] = containingCuttingRegionLb_org[i] + Mu_w0[i];
		containingCuttingRegionUb[i] = containingCuttingRegionUb_org[i] + Mu_w0[i];
	}	

	/* for all w symbols */
	v_int_min = 1.0;
	for (symbolic_t w = 0; w < wSymbolsCount; w++){

		/* computing the symbolic and concrete values of current (w) */
		flat_to_symbolic(w_symbolic, wsDim, w, wsWidths);
		symbolic_to_concrete(w_concrete, wsDim, w_symbolic, wsLb, wsUb, wsEta); 

		/* Computing V_INT = P*V 
		* P can be stored or conputed in the fly. Anyway, we only use those values P(u, x, i) that are under
		* the PDF within the cutting bounds, since any other value P(u, x, i) is assumed to be zero.
		* Then, we multiply only P values within the cutting region with their corresponding V values and do a sum.
		*/
		v_int = 0.0;
		__private symbolic_t i_transform;
		for (symbolic_t i = 0; i < NUM_REACH_STATES; i++) {

			// get the value of p(x,u,w,i)
	#ifdef SAVE_P_MATRIX
			p_val = XU_bags[flat_thread_idx].Pr[w][i];
	#else
			/* computing the symbolic and concrete values of post-state */
			flat_to_symbolic(x_post_symbolic, ssDim, i, containingCuttingRegionWidths);
			symbolic_to_concrete(x_post_concrete, ssDim, x_post_symbolic, containingCuttingRegionLb, containingCuttingRegionUb, ssEta);

			/* reset x_Concrete */
			flat_to_symbolic(x_symbolic, ssDim, x_flat, ssWidths);
			symbolic_to_concrete(x_concrete, ssDim, x_symbolic, ssLb, ssUb, ssEta);

			/* compute Mu (possible post state) from current (x,u,w) */
			post_dynamics(Mu, x_concrete, u_concrete, w_concrete);

			/* using Mu as a the origin of the PDF(x) and computing the integration (probability) at the current post state */
			p_val = integratePdf(x_post_concrete, Mu);
	#endif

			/*now we find the corresponding index in V fror the current elelment in the cutting region*/

			// get the concrete value of x_i inside th containntg cuttinng region
			flat_to_symbolic(x_symbolic, ssDim, i, containingCuttingRegionWidths);
			symbolic_to_concrete(x_concrete, ssDim, x_symbolic, containingCuttingRegionLb, containingCuttingRegionUb, ssEta);


			/* maybe the cutting region has some parts outside of the domain SS */
			/* those post states are not then considered in the computation */
			bool out_of_range = false;
			for (unsigned int d = 0; d < ssDim; d++)
				if (x_concrete[d] < ssLb[d] || x_concrete[d] > ssUb[d])
					out_of_range = true;

			if(out_of_range)
				continue;

			// get the flat index of x_i inside the X domain
			concrete_to_symbolic(x_symbolic, ssDim, x_concrete, ssLb, ssEta);
			symbolic_to_flat(&i_transform, ssDim, x_symbolic, ssWidths);

			// compute v_int
			if (i_transform >= PROCESS_WIDTH_X){
				printf("synthesize: error: a thread tried to access mem out of range.");
				printf("(x_concrete = %f,%f)!\n", x_concrete[0], x_concrete[1]);
			}
			else
				v_int += V[i_transform] * p_val;
		}

	#ifdef HAS_TARGET
		/* compute P_0 and add it to V_int */
		concrete_t sumP0 = 0.0;
		for (symbolic_t t = 0; t < TARGET_SET_NUM_SYMBOLS; t++) {
			/* computing the symbolic and concrete values of post-state */
			flat_to_symbolic(x_post_symbolic, ssDim, t, targetSetWidths);
			symbolic_to_concrete(x_post_concrete, ssDim, x_post_symbolic, targetSetLb, targetSetUb, ssEta);

			/* sum the probability of this target set with widths=eta and center=x_post_concrete*/
			sumP0 += integratePdf(x_post_concrete, Mu_w0);
		}
		v_int += sumP0;
	#endif

		/* minimize: get minimum value of all v_int (wrt w) */
		if(v_int < v_int_min)
			v_int_min = v_int;
	}

	/* set the computed v_int in the memory*/
	XU_bags[flat_thread_idx].V_INT_MIN = v_int_min;

	return;
}


/************************************************************************************************/
/************************************************************************************************/
/* KERNEL-Function: COLLECT	| runs on X															*/
/************************************************************************************************/
/************************************************************************************************/
__kernel void collect(__global xu_bag_t* XU_bags, __global concrete_t* V) {

	/* essential vars */
	__private symbolic_t x_flat;
	__private symbolic_t flat_thread_idx;
	__private symbolic_t xu_idx;
	__private concrete_t vIntMin;
	__private concrete_t maxVint = 0.0;
	

	/* flat x and u indicies come directly from the scheduler */
	x_flat = UNIVERSAL_INDEX_X;

	/* what is my memory position (including the case of sub-buffering) */
	flat_thread_idx = x_flat - GLOBAL_OFFSET_X;

	/* iterate over all u in U and maximize the value of V_INT_MIN */
	__private symbolic_t u_control = 0;
	for (symbolic_t u = 0; u < UNIVERSAL_WIDTH_Y; u++) {
		xu_idx = (u - GLOBAL_OFFSET_Y) + (x_flat - GLOBAL_OFFSET_X) * PROCESS_WIDTH_Y;
		vIntMin = XU_bags[xu_idx].V_INT_MIN;

		if (vIntMin > maxVint) {
			maxVint = vIntMin;
			u_control = u;
		}
	}

#ifdef HAS_CONTROL_BYTES
	// by the way, we shif the control actions here
	// note that shifting the control actions is made to emulate the effect ok knowing the time steps
	for (symbolic_t u = 0; u < UNIVERSAL_WIDTH_Y; u++) {
		xu_idx = (u - GLOBAL_OFFSET_Y) + (x_flat - GLOBAL_OFFSET_X) * PROCESS_WIDTH_Y;
		for (int c = NUM_CONTROL_BYTES-1; c >= 0; c--){
			// shift current byte
			char to_set = XU_bags[xu_idx].IS_CONTROL[c];
			to_set = to_set << 1;

			// if previous has one at end, get it
			if (c != 0) {
				char b_previous = XU_bags[xu_idx].IS_CONTROL[c-1];
				if (b_previous & 0x80)
					to_set = to_set | 0x01;
			}

			// set
			XU_bags[xu_idx].IS_CONTROL[c] = to_set;
		}
	}
#endif

	/* setting the max-min value to the V array for the next synthesis iteration */
	V[flat_thread_idx] = maxVint;

#ifdef HAS_CONTROL_BYTES
	/* setting the selected control */
	xu_idx = (u_control - GLOBAL_OFFSET_Y) + (x_flat - GLOBAL_OFFSET_X) * PROCESS_WIDTH_Y;
	XU_bags[xu_idx].IS_CONTROL[0] = XU_bags[xu_idx].IS_CONTROL[0] | 0x01;
#endif	
	return;
}