/* those are the used data types to represent flat (flattned deimentional), symbolic (multi dimentional integers) and concrete (real) values */
#define concrete_t @@CONCRETE_DATA_TYPE@@
#define symbolic_t @@SYMBOLIC_DATA_TYPE@@


/* some handy functions */
void flat_to_symbolic(symbolic_t* symbolic_value, symbolic_t dim, const symbolic_t flat_value, const symbolic_t* dim_width);
void flat_to_symbolic(symbolic_t* symbolic_value, symbolic_t dim, const symbolic_t flat_value, const symbolic_t* dim_width) {

	symbolic_t fltCurrent;
	symbolic_t fltIntial;
	symbolic_t fltVolume;
	symbolic_t fltTmp;

	fltIntial = flat_value;
	for (int i = dim - 1; i >= 0; i--) {
		fltCurrent = fltIntial;

		fltVolume = 1;
		for (int k = 0; k < i; k++) {
			fltTmp = dim_width[k];
			fltVolume = fltVolume*fltTmp;
		}

		fltCurrent = fltCurrent/fltVolume;
		fltTmp = dim_width[i];
		fltCurrent = fltCurrent % fltTmp;

		symbolic_value[i] = fltCurrent;

		fltCurrent = fltCurrent*fltVolume;
		fltIntial = fltIntial - fltCurrent;
	}
}

void  symbolic_to_concrete(concrete_t* out_conc_value, symbolic_t dim, const symbolic_t* symbolic_value, const concrete_t* lb, const concrete_t* ub, const concrete_t* eta);
void  symbolic_to_concrete(concrete_t* out_conc_value, symbolic_t dim, const symbolic_t* symbolic_value, const concrete_t* lb, const concrete_t* ub, const concrete_t* eta) {

	// set grid centers as concrete values
	for (unsigned int i = 0; i < dim; i++)
		out_conc_value[i] = lb[i] + (((concrete_t)symbolic_value[i]) * eta[i]);
}

void concrete_to_symbolic( symbolic_t* out_symbolic_value, symbolic_t dim, const concrete_t* concrete_value, const concrete_t* lb, const concrete_t* eta);
void concrete_to_symbolic( symbolic_t* out_symbolic_value, symbolic_t dim, const concrete_t* concrete_value, const concrete_t* lb, const concrete_t* eta) {
	
	for (unsigned int i = 0; i < dim; i++)
		out_symbolic_value[i] = (symbolic_t)floor((concrete_value[i] - lb[i])/eta[i]);
}

void symbolic_to_flat(symbolic_t* out_flat_value, symbolic_t dim, const symbolic_t* symbolic_value, const symbolic_t* dim_width);
void symbolic_to_flat(symbolic_t* out_flat_value, symbolic_t dim, const symbolic_t* symbolic_value, const symbolic_t* dim_width) {

	symbolic_t fltTmpVolume;
	symbolic_t fltTmp;

	*out_flat_value = 0;
	for (unsigned int i = 0; i < dim; i++) {
		fltTmpVolume = 1;
		for (unsigned int j = 0; j < i; j++) {
			fltTmp = dim_width[j];
			fltTmpVolume = fltTmpVolume*fltTmp;
		}
		fltTmp = symbolic_value[i];
		fltTmp = fltTmp*fltTmpVolume;
		*out_flat_value = *out_flat_value + fltTmp;
	}
}