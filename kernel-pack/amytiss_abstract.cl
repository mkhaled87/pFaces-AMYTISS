/************************************************************************************************/
/************************************************************************************************/
/* KERNEL-Function: ABSTRACT														            */
/************************************************************************************************/
/************************************************************************************************/

__kernel void abstract(__global xu_bag_t* XU_bags) {

	/* essential vars */
	__private symbolic_t x_flat;
	__private symbolic_t u_flat;
	__private symbolic_t flat_thread_idx;

#ifdef SAVE_P_MATRIX
	/* some variables needed if we will save P */
	__private concrete_t ssEta[ssDim] = SS_ETA_LIST;
	__private concrete_t ssLb[ssDim]  = SS_LB_LIST;
	__private concrete_t ssUb[ssDim]  = SS_UB_LIST;
	__private concrete_t isEta[isDim] = IS_ETA_LIST;
	__private concrete_t isLb[isDim]  = IS_LB_LIST;
	__private concrete_t isUb[isDim]  = IS_UB_LIST;

	__private symbolic_t ssWidths[ssDim] = SS_WIDTHS_LIST;
	__private symbolic_t isWidths[isDim] = IS_WIDTHS_LIST;

	__private symbolic_t x_symbolic[ssDim];
	__private symbolic_t u_symbolic[isDim];	
	__private concrete_t x_concrete[ssDim];
	__private concrete_t u_concrete[isDim];
#endif


	/* flat x and u indicies come directly from the scheduler */
	x_flat = UNIVERSAL_INDEX_X;
	u_flat = UNIVERSAL_INDEX_Y;

	/* what is my memory position (including the case of sub-buffering) */
	flat_thread_idx = (u_flat - GLOBAL_OFFSET_Y) + (x_flat - GLOBAL_OFFSET_X) * PROCESS_WIDTH_Y;

	/* resetting the control values */
#ifdef HAS_CONTROL_BYTES	
	for (unsigned int i = 0; i < NUM_CONTROL_BYTES; i++)
		XU_bags[flat_thread_idx].IS_CONTROL[i] = 0;
#endif


#ifdef SAVE_P_MATRIX
	/* computing the symbolic and concrete values of current (x,u) */
	flat_to_symbolic(x_symbolic, ssDim, x_flat, ssWidths);
	flat_to_symbolic(u_symbolic, isDim, u_flat, isWidths);
	symbolic_to_concrete(x_concrete, ssDim, x_symbolic, ssLb, ssUb, ssEta);
	symbolic_to_concrete(u_concrete, isDim, u_symbolic, isLb, isUb, isEta);
	
	/* computing the probabilities */
	compute_probabilities(&XU_bags[flat_thread_idx], x_concrete, u_concrete);
#endif

	return;
}
