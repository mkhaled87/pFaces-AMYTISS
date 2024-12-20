/*
* amytiss.cpp
*
*  created on: 28.04.2019
*      author: M. Khaled
*/
#include "amytiss.h"
#include <symbolicc++.h>

namespace amytiss{

	/*********************************************************/
	// A pre/post-execcute to save the data
	/*********************************************************/
	/* this function initializes the values in the V vector to be ones or zeros based on the specs */
	size_t initializeV(
		const pfaces2DKernel& thisKernel,
		const pfacesParallelProgram& thisParallelProgram,
		std::vector<std::shared_ptr<void>>& postExecuteParamsList) {

		(void)postExecuteParamsList;

		// this kernel
		amytissKernel* pAmytissKernel = ((amytissKernel*)(&thisKernel));

		// setting the inital value of V
		concrete_t* pV = (concrete_t*)thisParallelProgram.m_dataPool[1].first;
		if (thisParallelProgram.m_dataPool[1].second < sizeof(concrete_t) * thisParallelProgram.m_Process_globalNDRange[0])
			throw std::runtime_error("Something is not correct here !");
	
		// threaded execution to set V values
		size_t num_vals = thisParallelProgram.m_dataPool[1].second / sizeof(concrete_t);
		concrete_t set_val = (concrete_t)(pAmytissKernel->SafetyOrReachability ? 1.0 : 0.0);
		pfacesUtils::threaded_for(num_vals, [&pV, &set_val](int start, int end) {
			for (int i = start; i < end; ++i)
				pV[i] = set_val;
		});

		return 0;
	}

	/* this function saves the memory bags and V after fininshing the computation */
	size_t saveData(
		const pfaces2DKernel& thisKernel, 
		const pfacesParallelProgram& thisParallelProgram, 
		std::vector<std::shared_ptr<void>>& postExecuteParamsList) {

		(void)postExecuteParamsList;

		amytissKernel* thisAmytissKernel = ((amytissKernel*)(&thisKernel));

		char* pData_Bags = thisParallelProgram.m_dataPool[0].first;
		char* pData_V = thisParallelProgram.m_dataPool[1].first;
		size_t num_reach_states = thisAmytissKernel->num_reach_states;
		std::string specs_type = thisParallelProgram.m_spCfgReader->readConfigValueString(AMYTISS_CONFIG_PARAM_specs_type);
		bool isSaveTransitions = thisParallelProgram.m_spCfgReader->readConfigValueBool(AMYTISS_CONFIG_PARAM_save_transitions);
		bool isSaveController = thisParallelProgram.m_spCfgReader->readConfigValueBool(AMYTISS_CONFIG_PARAM_save_controller);
		size_t time_steps = thisParallelProgram.m_spCfgReader->readConfigValueInt(AMYTISS_CONFIG_PARAM_specs_time_steps);
		size_t bagSize = XU_bag::getSize(isSaveTransitions, num_reach_states, time_steps, 
			isSaveController, pfacesBigInt::getPrimitiveValue(thisAmytissKernel->wSpaceFlatWidth));

		size_t beVerboseLevel = thisParallelProgram.m_beVerboseLevel;
		std::string	strDataImplementation	= thisParallelProgram.m_spCfgReader->readConfigValueString(AMYTISS_CONFIG_PARAM_data);
	
		std::string	outPath_bags	= 
			pfacesFileIO::getFileDirectoryPath(thisParallelProgram.m_spCfgReader->getConfigFilePath()) + 
			std::string(thisParallelProgram.m_spCfgReader->readConfigValueString(AMYTISS_CONFIG_PARAM_project_name));

		std::string	outPath_V =
			pfacesFileIO::getFileDirectoryPath(thisParallelProgram.m_spCfgReader->getConfigFilePath()) +
			std::string(thisParallelProgram.m_spCfgReader->readConfigValueString(AMYTISS_CONFIG_PARAM_project_name)) +
			std::string("_V");

		// nothing required ?
		if (!isSaveTransitions && !isSaveController)
			return 0;

		// encapsulate the data
		size_t xu_domain_size = pfacesBigInt::getPrimitiveValue(thisAmytissKernel->xSpaceFlatWidth)*pfacesBigInt::getPrimitiveValue(thisAmytissKernel->uSpaceFlatWidth);
		size_t x_domain_size = pfacesBigInt::getPrimitiveValue(thisAmytissKernel->xSpaceFlatWidth);
		pfacesRawData rawData_Bags(pData_Bags, xu_domain_size*bagSize);
		pfacesRawData rawData_V(pData_V, x_domain_size*sizeof(concrete_t));

		// prepare the metadata
		StringDataDictionary metadata;
		metadata.push_back(std::make_pair(OUT_FILE_PARAM_SS_DIMENSION, std::to_string(thisAmytissKernel->ssDim)));
		metadata.push_back(std::make_pair(OUT_FILE_PARAM_IS_DIMENSION, std::to_string(thisAmytissKernel->isDim)));
		metadata.push_back(std::make_pair(OUT_FILE_PARAM_WS_DIMENSION, std::to_string(thisAmytissKernel->wsDim)));
		metadata.push_back(std::make_pair(OUT_FILE_PARAM_SS_ETA, pfacesUtils::vector2string<concrete_t>(thisAmytissKernel->ssEta)));
		metadata.push_back(std::make_pair(OUT_FILE_PARAM_IS_ETA, pfacesUtils::vector2string<concrete_t>(thisAmytissKernel->isEta)));
		metadata.push_back(std::make_pair(OUT_FILE_PARAM_WS_ETA, pfacesUtils::vector2string<concrete_t>(thisAmytissKernel->wsEta)));
		metadata.push_back(std::make_pair(OUT_FILE_PARAM_SS_LB, pfacesUtils::vector2string<concrete_t>(thisAmytissKernel->ssLb)));
		metadata.push_back(std::make_pair(OUT_FILE_PARAM_SS_UB, pfacesUtils::vector2string<concrete_t>(thisAmytissKernel->ssUb)));
		metadata.push_back(std::make_pair(OUT_FILE_PARAM_IS_LB, pfacesUtils::vector2string<concrete_t>(thisAmytissKernel->isLb)));
		metadata.push_back(std::make_pair(OUT_FILE_PARAM_IS_UB, pfacesUtils::vector2string<concrete_t>(thisAmytissKernel->isUb)));
		metadata.push_back(std::make_pair(OUT_FILE_PARAM_WS_LB, pfacesUtils::vector2string<concrete_t>(thisAmytissKernel->wsLb)));
		metadata.push_back(std::make_pair(OUT_FILE_PARAM_WS_UB, pfacesUtils::vector2string<concrete_t>(thisAmytissKernel->wsUb)));
		metadata.push_back(std::make_pair(OUT_FILE_PARAM_SS_STEPS, pfacesUtils::vector2string<symbolic_t>(thisAmytissKernel->xSpacePerDimWidth)));
		metadata.push_back(std::make_pair(OUT_FILE_PARAM_IS_STEPS, pfacesUtils::vector2string<symbolic_t>(thisAmytissKernel->uSpacePerDimWidth)));
		metadata.push_back(std::make_pair(OUT_FILE_PARAM_WS_STEPS, pfacesUtils::vector2string<symbolic_t>(thisAmytissKernel->wSpacePerDimWidth)));
		for (size_t i = 0; i < thisAmytissKernel->ssDim; i++){
			metadata.push_back(
				std::make_pair(
					pfacesUtils::strReplaceAll(
						std::string(OUT_FILE_PARAM_SS_STATE_VAR_POST), 
						std::string(OUT_FILE_PARAM_SS_STATE_VAR_NUMBER_TOKEN)
						, std::to_string(i)),
					thisParallelProgram.m_spCfgReader->readConfigValueString(std::string(AMYTISS_CONFIG_PARAM_post_dynamics_xx) +  std::to_string(i))
				)
			);
		}
		metadata.push_back(std::make_pair(OUT_FILE_PARAM_X_WIDTH, std::to_string(pfacesBigInt::getPrimitiveValue(thisAmytissKernel->xSpaceFlatWidth))));
		metadata.push_back(std::make_pair(OUT_FILE_PARAM_U_WIDTH, std::to_string(pfacesBigInt::getPrimitiveValue(thisAmytissKernel->uSpaceFlatWidth))));
		metadata.push_back(std::make_pair(OUT_FILE_PARAM_W_WIDTH, std::to_string(pfacesBigInt::getPrimitiveValue(thisAmytissKernel->wSpaceFlatWidth))));
		metadata.push_back(std::make_pair(OUT_FILE_PARAM_XU_BAG_SIZE, std::to_string(bagSize)));
		metadata.push_back(std::make_pair(OUT_FILE_PARAM_IS_P_SAVED, (isSaveTransitions?std::string("true"): std::string("false"))));
		metadata.push_back(std::make_pair(OUT_FILE_PARAM_NUM_REACH_STATES, std::to_string(num_reach_states)));
		metadata.push_back(std::make_pair(OUT_FILE_PARAM_TIME_STEPS, std::to_string(time_steps)));
		metadata.push_back(std::make_pair(OUT_FILE_PARAM_CONCRETE_NAME, std::string(concrete_t_cl_string)));
		metadata.push_back(std::make_pair(OUT_FILE_PARAM_CONCRETE_SIZE, std::to_string(sizeof(concrete_t))));
		metadata.push_back(std::make_pair(OUT_FILE_PARAM_SYMBOLIC_NAME, std::string(symbolic_t_cl_string)));
		metadata.push_back(std::make_pair(OUT_FILE_PARAM_SYMBOLIC_SIZE, std::to_string(sizeof(symbolic_t))));
		metadata.push_back(std::make_pair(OUT_FILE_PARAM_USED_KERNEL_NAME, thisKernel.getKernelName()));	

		metadata.push_back(std::make_pair(OUT_FILE_PARAM_ORG_CUTTING_REGION_LB,
			pfacesUtils::vector2string<concrete_t>(thisAmytissKernel->orgCuttingBoundsLb)));
		metadata.push_back(std::make_pair(OUT_FILE_PARAM_ORG_CUTTING_REGION_UB,
			pfacesUtils::vector2string<concrete_t>(thisAmytissKernel->orgCuttingBoundsUb)));

		// add additional stuff from the pdf object
		thisAmytissKernel->spPdfObj->addToOutputFileMetadata(metadata);
		
		metadata.push_back(std::make_pair(OUT_FILE_PARAM_SPECS_TYPE, specs_type));

		if (specs_type == std::string(AMYTISS_CONFIG_PARAM_specs_type_value_reach)) {
			std::string target_hrect = thisParallelProgram.m_spCfgReader->readConfigValueString(AMYTISS_CONFIG_PARAM_specs_hyperrect);
			target_hrect = pfacesUtils::strReplaceAll(target_hrect, "{", "");
			target_hrect = pfacesUtils::strReplaceAll(target_hrect, "}", "");
			metadata.push_back(std::make_pair(OUT_FILE_PARAM_SPECS_TARGET_HYPERRECT, target_hrect));

			std::string avoid_hrect = thisParallelProgram.m_spCfgReader->readConfigValueString(AMYTISS_CONFIG_PARAM_specs_avoid_hyperrect);
			if(avoid_hrect == std::string(""))
				metadata.push_back(std::make_pair(OUT_FILE_PARAM_SPECS_AVOID_HYPERRECT, "N/A"));
			else {
				avoid_hrect = pfacesUtils::strReplaceAll(avoid_hrect, "{", "");
				avoid_hrect = pfacesUtils::strReplaceAll(avoid_hrect, "}", "");
				metadata.push_back(std::make_pair(OUT_FILE_PARAM_SPECS_AVOID_HYPERRECT, avoid_hrect));
			}

		}
		else {
			metadata.push_back(std::make_pair(OUT_FILE_PARAM_SPECS_TARGET_HYPERRECT, "N/A"));
			metadata.push_back(std::make_pair(OUT_FILE_PARAM_SPECS_AVOID_HYPERRECT, "N/A"));
		}

		// Informing the user we are saving
		if (beVerboseLevel >= 2) {
			pfacesTerminal::showMessage(std::string("Saving output files ... ") , false);
		}

		// actual writing
		bool writeFileStatus = true;
		double total_size_in_mb = (((double)rawData_Bags.getSize()) / ((double)(1024 * 1024))) + (((double)rawData_V.getSize()) / ((double)(1024 * 1024)));
		DataFileType file_type = pfacesDataFile::getTypeFromString(strDataImplementation);
		outPath_bags += pfacesDataFile::getTypeDefaultExtension(file_type);
		outPath_V += pfacesDataFile::getTypeDefaultExtension(file_type);
		if (file_type == DataFileType::DATA_FILE_RAW) {
			writeFileStatus &= pfacesDataFile::writeData(outPath_bags, file_type, rawData_Bags, metadata, beVerboseLevel >= 2);
			writeFileStatus &= pfacesDataFile::writeData(outPath_V, file_type, rawData_V, metadata, beVerboseLevel >= 2);
		}else{
			throw std::runtime_error("TODO: Soon, I'll implememnt other data types for saving abs/contr!");
		}

		// Informing the user we are done
		if (!writeFileStatus)
			pfacesTerminal::showWarnMessage("Failed to write one or more output files !");
		else
			pfacesTerminal::showMessage(std::string(" [2 Files, Raw-size: ") + std::to_string(total_size_in_mb) + std::string(" M.B.]"));

		return 0;
	}


	/*********************************************************/
	// class amytissKernel
	/*********************************************************/
	/* this computes the cardinality of the concrete space after quantized with some eta */
	flat_t amytissGetFlatWidthFromConcreteSpace(size_t Dim,
		const std::vector<concrete_t>& Eta,
		const std::vector<concrete_t>& Lb, const std::vector<concrete_t>& Ub,
		const std::vector<concrete_t>& Err,
		std::vector<symbolic_t>& outWidthPerDimension) {

		// a zero-dim space is a singleton set !
		if (Dim == 0) {
			outWidthPerDimension.push_back(1);
			flat_t ret = 1;
			return ret;
		}

		if (Dim != Eta.size() || Dim != Lb.size() || Dim != Ub.size())
			throw std::runtime_error("Invalid sizes/dimensions for Concrete space !");

		if (Err.size() != 0 && Dim != Err.size())
			throw std::runtime_error("Invalid dimension for the error parameters of the space !");

		flat_t biMaxIdx = 1;
		for (size_t i = 0; i < Dim; i++) {
			symbolic_t width = ((symbolic_t)std::round((Ub[i]-Lb[i])/Eta[i])) + 1;
			outWidthPerDimension.push_back(width);

			flat_t tmp((unsigned long int)width);
			biMaxIdx = biMaxIdx * tmp;
		}

		return biMaxIdx;
	}

	/* this functin reutens the pdf as string by doing some symbolic operations */
	std::string amytissKernel::amytissGetPdfAsCFunctionBody() {

		// the pdf as a strings	
		std::stringstream ssE;
		ssE << spPdfObj->getPDFBody();
		std::string strRet = ssE.str();
		return strRet;
	}

	// this gets some defines to be used by the pdf
	std::string amytissKernel::amytissGetPdfDefines() {

		// no defines are rquired if the PDF is custom since the user will provde all of this
		if (spPdfObj->getClass() == PDF_CLASS::CUSTOM)
			return "";

		std::stringstream ssE;

		// collect and check
		auto pair = spPdfObj->getOriginatedCuttingBound();
		orgCuttingBoundsLb = pair.first;
		orgCuttingBoundsUb = pair.second;

		// add no_truncation flag + enforce all-ss 
		if(spPdfObj->getTruncationMode() == PDF_TRUNCATION::NO_TRUNCATION){
			
			// is the pdf class aware of this an already set lb/ub to all-ss ?
			bool all_ss_already_set = true;
			for(size_t i=0; i<ssDim; i++)
				if(orgCuttingBoundsLb[i] != ssLb[i] || orgCuttingBoundsUb[i] != ssUb[i])
					all_ss_already_set = false;
			
			if(!all_ss_already_set){
				orgCuttingBoundsLb = ssLb;
				orgCuttingBoundsUb = ssUb;

				pfacesTerminal::showWarnMessage(
					"The pdf truncation is set to NO_TRUNCATION but the pdf object did not set the cutting bound correctly to all-state-set. "
					"AMYTISS enforced the cutting region to all-state-set."	
				);
			}

			ssE << "#define PDF_NO_TRUNCATION" << std::endl;
		}

		if (orgCuttingBoundsLb.size() != ssDim || orgCuttingBoundsUb.size() != ssDim)
			throw std::runtime_error("amytissKernel::amytissGetPdfDefines: the LB/UB of the cutting region has invalid size.");

		for(size_t i=0; i<ssDim; i++)
			if(orgCuttingBoundsLb[i] > orgCuttingBoundsUb[i])
				throw std::runtime_error("amytissKernel::amytissGetPdfDefines: the LB/UB of the cutting region is invalid: the LB should be smaller than or equal to the UB.");

		// the noise type
		if (spPdfObj->getNoiseType() == NOISE_TYPE::MULTIPLICATIVE) {
			if(spPdfObj->getTruncationMode() != PDF_TRUNCATION::NO_TRUNCATION)
				throw std::runtime_error("amytissKernel::amytissGetPdfDefines: For multiplicative noise, no truncation is supported as the pdf is possibily scalled differently for each state symbol and the scaling may cover the whole state set.");

			ssE << "#define PDF_MULTIPLICATIVE_NOISE" << std::endl;
		}

		// the PDF truncation
		ssE << "/* the cutting bounds of the PDF */"  << std::endl;
		ssE << "#define CUTTING_REGION_LB {";
		ssE << pfacesUtils::vector2string(orgCuttingBoundsLb);
		ssE << "}" << std::endl;
		ssE << "#define CUTTING_REGION_UB {";
		ssE << pfacesUtils::vector2string(orgCuttingBoundsUb);
		ssE << "}" << std::endl;

		// number of elements + widths of the region
		std::vector<symbolic_t> contaningCuttingRegionWidths;
		num_reach_states =
			pfacesBigInt::getPrimitiveValue(amytissGetFlatWidthFromConcreteSpace(ssDim, ssEta,
				orgCuttingBoundsLb, orgCuttingBoundsUb, {}, contaningCuttingRegionWidths));
		ssE << "/* number of symbols in the cutting region */"  << std::endl;
		ssE << "#define NUM_REACH_STATES " << num_reach_states << std::endl;
		ssE << "#define CUTTING_REGION_WIDTHS {" << pfacesUtils::vector2string(contaningCuttingRegionWidths) << "}" << std::endl;

		// extra deffines
		ssE << "/* extra defines requested by the PDF */"  << std::endl;
		ssE << spPdfObj->getAdditionalDefines();


		// some statistics
		std::vector<symbolic_t> dummy;
		size_t num_ss_states = pfacesBigInt::getPrimitiveValue(
			amytissGetFlatWidthFromConcreteSpace(ssDim, ssEta, ssLb, ssUb, {}, dummy)
		);

		pfacesTerminal::showMessage(std::string("Noise type: ") + amytiss::to_string(spPdfObj->getNoiseType()));
		pfacesTerminal::showMessage(std::string("PDF class: ") + amytiss::to_string(spPdfObj->getClass()));
		pfacesTerminal::showMessage(std::string("PDF truncation: ") + amytiss::to_string(spPdfObj->getTruncationMode()));

		if (spPdfObj->getTruncationMode() != PDF_TRUNCATION::NO_TRUNCATION) {
			double reduction = 100.0 * (1.0 - (double)num_reach_states / (double)num_ss_states);
			pfacesTerminal::showMessage(std::string("The org. cutting region (Lb):") + pfacesUtils::vector2string(orgCuttingBoundsLb));
			pfacesTerminal::showMessage(std::string("The org. cutting region (Ub):") + pfacesUtils::vector2string(orgCuttingBoundsUb));
			pfacesTerminal::showMessage(
				std::string("Number of reach-states after cutting the probability: ") +
				std::to_string(num_reach_states) + std::string(" - ") + std::to_string(std::round(reduction)) + std::string("% reduction.")
			);
		}
		else {
			pfacesTerminal::showMessage(std::string("Number of reach-states: ") + std::to_string(num_reach_states));
		}

		if (saveP && num_reach_states > 256)
			pfacesTerminal::showWarnMessage(
				"Number of expected reach states for each (x,u) exeecds 256."
				" Please consider not saving the abstraction as the size will probably be large.");		

		std::string strRet = ssE.str();
		return strRet;
	}

	/* the constructor: initiate data and prepapre memory maps*/
	amytissKernel::amytissKernel(const std::shared_ptr<pfacesKernelLaunchState>& spLaunchState, const std::shared_ptr<pfacesConfigurationReader>& spCfg)
		: pfaces2DKernel(
			spLaunchState->getDefaultSourceFilePath(AMYTISS_KERNEL_NAME),
			(size_t)spCfg->readConfigValueInt(AMYTISS_CONFIG_PARAM_states_dim),
			(size_t)spCfg->readConfigValueInt(AMYTISS_CONFIG_PARAM_inputs_dim)
		), m_spCfg(spCfg) {


		// TASK0: setting the local vars
		// -----------------------------
		// reading the bounds and quantizations of all spaces
		ssDim = (size_t)m_spCfg->readConfigValueInt(AMYTISS_CONFIG_PARAM_states_dim);
		ssEta = pfacesUtils::sStr2Vector<concrete_t>(m_spCfg->readConfigValueString(AMYTISS_CONFIG_PARAM_states_eta));
		ssLb = pfacesUtils::sStr2Vector<concrete_t>(m_spCfg->readConfigValueString(AMYTISS_CONFIG_PARAM_states_lb));
		ssUb = pfacesUtils::sStr2Vector<concrete_t>(m_spCfg->readConfigValueString(AMYTISS_CONFIG_PARAM_states_ub));

		if (ssDim == 0 || ssEta.size() != ssDim || ssLb.size() != ssDim || ssUb.size() != ssDim)
			throw std::runtime_error("amytissKernel::amytissKernel: Invalid parameters for the states !");

		isDim = (size_t)m_spCfg->readConfigValueInt(AMYTISS_CONFIG_PARAM_inputs_dim);
		if(isDim != 0){
			isEta = pfacesUtils::sStr2Vector<concrete_t>(m_spCfg->readConfigValueString(AMYTISS_CONFIG_PARAM_inputs_eta));
			isLb = pfacesUtils::sStr2Vector<concrete_t>(m_spCfg->readConfigValueString(AMYTISS_CONFIG_PARAM_inputs_lb));
			isUb = pfacesUtils::sStr2Vector<concrete_t>(m_spCfg->readConfigValueString(AMYTISS_CONFIG_PARAM_inputs_ub));

			if (isEta.size() != isDim || isLb.size() != isDim || isUb.size() != isDim)
				throw std::runtime_error("amytissKernel::amytissKernel: Invalid parameters for the inputs !");
		}
		else{
			singletonInput = true;
			isEta = { 1.0 };
			isLb = { 0.0 };
			isUb = { 0.0 };
		}

		wsDim = (size_t)m_spCfg->readConfigValueInt(AMYTISS_CONFIG_PARAM_disturbances_dim);
		if (wsDim != 0) {
			wsEta = pfacesUtils::sStr2Vector<concrete_t>(m_spCfg->readConfigValueString(AMYTISS_CONFIG_PARAM_disturbances_eta));
			wsLb = pfacesUtils::sStr2Vector<concrete_t>(m_spCfg->readConfigValueString(AMYTISS_CONFIG_PARAM_disturbances_lb));
			wsUb = pfacesUtils::sStr2Vector<concrete_t>(m_spCfg->readConfigValueString(AMYTISS_CONFIG_PARAM_disturbances_ub));

			if (isDim == 0 || isEta.size() != isDim || isLb.size() != isDim || isUb.size() != isDim)
				throw std::runtime_error("amytissKernel::amytissKernel: Invalid parameters for the disturbances !");
		}
		else {
			singletonDisturbance = true;
			wsEta = { 1.0 };
			wsLb = { 0.0 };
			wsUb = { 0.0 };
		}

		// realigning the LB/UB values of all spaces
		for (size_t i = 0; i < ssDim; i++){
			concrete_t new_lb = amytissPDF::alignValueToQuantizationGrid(ssLb[i], ssEta[i], ssLb[i], ssUb[i]);
			if (new_lb != ssLb[i]) ssWasMisAlignedFlag = true;
			ssLb[i] = new_lb;

			concrete_t new_ub = amytissPDF::alignValueToQuantizationGrid(ssUb[i], ssEta[i], ssLb[i], ssUb[i]);
			if (new_ub != ssUb[i]) ssWasMisAlignedFlag = true;
			ssUb[i] = new_ub;
		}
	
		if(!singletonInput){
			for (size_t i = 0; i < isDim; i++) {
				concrete_t new_lb = amytissPDF::alignValueToQuantizationGrid(isLb[i], isEta[i], isLb[i], isUb[i]);
				if (new_lb != isLb[i]) isWasMisAlignedFlag = true;
				isLb[i] = new_lb;

				concrete_t new_ub = amytissPDF::alignValueToQuantizationGrid(isUb[i], isEta[i], isLb[i], isUb[i]);
				if (new_ub != isUb[i]) isWasMisAlignedFlag = true;
				isUb[i] = new_ub;
			}
		}
		if(!singletonDisturbance){
			for (size_t i = 0; i < wsDim; i++) {
				concrete_t new_lb = amytissPDF::alignValueToQuantizationGrid(wsLb[i], wsEta[i], wsLb[i], wsUb[i]);
				if (new_lb != wsLb[i]) wsWasMisAlignedFlag = true;
				wsLb[i] = new_lb;

				concrete_t new_ub = amytissPDF::alignValueToQuantizationGrid(wsUb[i], wsEta[i], wsLb[i], wsUb[i]);
				if (new_ub != wsUb[i]) wsWasMisAlignedFlag = true;
				wsUb[i] = new_ub;
			}

			// some checks over the disturbance set (Q)
			for (size_t i = 0; i < wsDim; i++) {
				if (wsLb[i] != -1.0 * wsUb[i])
					throw std::runtime_error("amytissKernel::amytissKernel: The disturbance set (W) need to by symmetrica around the origin. This is an implementation restriction and does not come from the theory !");

				if (i > 0)
					if (wsLb[i] != wsLb[i - 1] || wsUb[i] != wsUb[i - 1])
						throw std::runtime_error("amytissKernel::amytissKernel: The disturbance set (W) need to by a hyper cube. This is an implementation restriction and does not come from the theory !");
			}
		}

		// configuration of computation
		saveP = spCfg->readConfigValueBool(AMYTISS_CONFIG_PARAM_save_transitions);
		saveC = spCfg->readConfigValueBool(AMYTISS_CONFIG_PARAM_save_controller);
		time_steps = (size_t)m_spCfg->readConfigValueInt(AMYTISS_CONFIG_PARAM_specs_time_steps);


		// based on the config from the user, get a PDF
		spPdfObj = amytissPDF::constructPDF(m_spCfg, ssDim, ssEta, ssLb, ssUb);


		// TASK1: Updating the params
		//------------------------------------------------------------
		std::vector<std::string> params;
		std::vector<std::string> paramvals;

		/* concrete data type*/
		params.push_back(AMYTISS_KERNEL_PARAM_CONCRETE_DATA_TYPE);
		paramvals.push_back(concrete_t_cl_string);

		/* symbolic data type */
		params.push_back(AMYTISS_KERNEL_PARAM_SYMBOLIC_DATA_TYPE);
		paramvals.push_back(symbolic_t_cl_string);

		/* ss, is, and ws dimensions */
		params.push_back(AMYTISS_KERNEL_PARAM_SSDIM);
		paramvals.push_back(std::to_string(ssDim));
		params.push_back(AMYTISS_KERNEL_PARAM_ISDIM);
		paramvals.push_back(std::to_string(singletonInput?1:isDim));
		params.push_back(AMYTISS_KERNEL_PARAM_WSDIM);
		paramvals.push_back(std::to_string(singletonDisturbance?1:wsDim));

		/* ss, is, and ws bounds/quantizations */
		params.push_back(AMYTISS_KERNEL_PARAM_SSETA);
		paramvals.push_back(pfacesUtils::vector2string(ssEta));
		params.push_back(AMYTISS_KERNEL_PARAM_SSLB);
		paramvals.push_back(pfacesUtils::vector2string(ssLb));
		params.push_back(AMYTISS_KERNEL_PARAM_SSUB);
		paramvals.push_back(pfacesUtils::vector2string(ssUb));
		params.push_back(AMYTISS_KERNEL_PARAM_ISETA);
		paramvals.push_back(pfacesUtils::vector2string(isEta));
		params.push_back(AMYTISS_KERNEL_PARAM_ISLB);
		paramvals.push_back(pfacesUtils::vector2string(isLb));
		params.push_back(AMYTISS_KERNEL_PARAM_ISUB);
		paramvals.push_back(pfacesUtils::vector2string(isUb));
		params.push_back(AMYTISS_KERNEL_PARAM_WSETA);
		paramvals.push_back(pfacesUtils::vector2string(wsEta));
		params.push_back(AMYTISS_KERNEL_PARAM_WSLB);
		paramvals.push_back(pfacesUtils::vector2string(wsLb));
		params.push_back(AMYTISS_KERNEL_PARAM_WSUB);
		paramvals.push_back(pfacesUtils::vector2string(wsUb));

		/* save P ? */
		params.push_back(AMYTISS_KERNEL_PARAM_DEFINE_SAVE_P_MATRIX);
		if(saveP)
			paramvals.push_back("#define SAVE_P_MATRIX");
		else
			paramvals.push_back("");

		/* Specifications */
		std::string specs_type = spCfg->readConfigValueString(AMYTISS_CONFIG_PARAM_specs_type);
		if(time_steps == 0){
			params.push_back(AMYTISS_KERNEL_PARAM_DEFINE_HAS_SAFE);
			paramvals.push_back("");

			params.push_back(AMYTISS_KERNEL_PARAM_DEFINE_HAS_TARGET);
			paramvals.push_back("");

			params.push_back(AMYTISS_KERNEL_PARAM_TARGET_DATA);
			paramvals.push_back("");

			params.push_back(AMYTISS_KERNEL_PARAM_DEFINE_HAS_AVOID);
			paramvals.push_back("");

			params.push_back(AMYTISS_KERNEL_PARAM_AVOID_DATA);
			paramvals.push_back("");
		}
		else{
			if(specs_type == std::string(AMYTISS_CONFIG_PARAM_specs_type_value_reach)){

				std::string ste_rect = spCfg->readConfigValueString(AMYTISS_CONFIG_PARAM_specs_hyperrect);
				ste_rect = pfacesUtils::strReplaceAll(ste_rect, "{", "");
				ste_rect = pfacesUtils::strReplaceAll(ste_rect, "}", "");
				std::vector<concrete_t> target_hyperrect = pfacesUtils::sStr2Vector<concrete_t>(ste_rect);
				if (target_hyperrect.size() != ssDim * 2)
					throw std::runtime_error("amytissKernel::amytissKernel: invalid number of elements in the given target set !");

				std::vector<concrete_t> targetSetLb(ssDim);
				std::vector<concrete_t> targetSetUb(ssDim);
				std::string target_data = "";
				for (size_t i = 0; i < ssDim; i++){
					target_hyperrect[2*i + 0] = amytissPDF::alignValueToQuantizationGrid(target_hyperrect[2*i + 0], ssEta[i], ssLb[i], ssUb[i]);
					target_hyperrect[2*i + 1] = amytissPDF::alignValueToQuantizationGrid(target_hyperrect[2*i + 1], ssEta[i], ssLb[i], ssUb[i]);
					targetSetLb[i] = target_hyperrect[2 * i + 0];
					targetSetUb[i] = target_hyperrect[2 * i + 1];

					if(targetSetLb[i] >= targetSetUb[i])
						throw std::runtime_error("amytissKernel::amytissKernel: invalid UB/LB values for the target set in index: " + std::to_string(i));


					/* target data is only used in the low-level code to check if a point is target */
					/* we inflate it with quarter-eta to avoid any precision errors in float comparison */
					target_hyperrect[2 * i + 0] -= (concrete_t)(ssEta[i]/4.0);
					target_hyperrect[2 * i + 1] += (concrete_t)(ssEta[i]/4.0);

					target_data += 
						std::string("{") + std::to_string(target_hyperrect[2 * i + 0]) + 
						", " + std::to_string(target_hyperrect[2 * i + 1]) + std::string("}");

					if (i != (ssDim - 1))
						target_data += std::string(", ");
				}


				params.push_back(AMYTISS_KERNEL_PARAM_DEFINE_HAS_TARGET);
				paramvals.push_back("#define HAS_TARGET");


				params.push_back(AMYTISS_KERNEL_PARAM_TARGET_DATA);
				paramvals.push_back(target_data);

				params.push_back(AMYTISS_KERNEL_PARAM_TARGET_SET_LB);
				paramvals.push_back(pfacesUtils::vector2string(targetSetLb));
				
				params.push_back(AMYTISS_KERNEL_PARAM_TARGET_SET_UB);
				paramvals.push_back(pfacesUtils::vector2string(targetSetUb));

				std::vector<symbolic_t> targetSetWidths;
				flat_t targetSetFlatWidth = amytissGetFlatWidthFromConcreteSpace(ssDim, ssEta, targetSetLb, targetSetUb, {}, targetSetWidths);
					
				params.push_back(AMYTISS_KERNEL_PARAM_TARGET_SET_WIDTHS);
				paramvals.push_back(pfacesUtils::vector2string(targetSetWidths));

				symbolic_t numTargetSetSymbols = pfacesBigInt::getPrimitiveValue(targetSetFlatWidth);
				if (numTargetSetSymbols <= 0)
					throw std::runtime_error("amytissKernel::amytissKernel: target set has no symbols !");

				params.push_back(AMYTISS_KERNEL_PARAM_TARGET_SET_NUM_SYMBOLS);
				paramvals.push_back(std::to_string(numTargetSetSymbols));

				params.push_back(AMYTISS_KERNEL_PARAM_DEFINE_HAS_SAFE);
				paramvals.push_back("");

				SafetyOrReachability = false;

				std::string str_avoid_rect = spCfg->readConfigValueString(AMYTISS_CONFIG_PARAM_specs_avoid_hyperrect);
				if (str_avoid_rect != std::string("")) {
					str_avoid_rect = pfacesUtils::strReplaceAll(str_avoid_rect, "{", "");
					str_avoid_rect = pfacesUtils::strReplaceAll(str_avoid_rect, "}", "");
					std::vector<concrete_t> avoid_hyperrect = pfacesUtils::sStr2Vector<concrete_t>(str_avoid_rect);
					if (avoid_hyperrect.size() != ssDim * 2)
						throw std::runtime_error("amytissKernel::amytissKernel: invalid number of elements in the given avoid set !");


					std::string avoid_data = "";
					for (size_t i = 0; i < ssDim; i++) {
						avoid_hyperrect[2 * i + 0] = amytissPDF::alignValueToQuantizationGrid(avoid_hyperrect[2 * i + 0], ssEta[i], ssLb[i], ssUb[i]);
						avoid_hyperrect[2 * i + 1] = amytissPDF::alignValueToQuantizationGrid(avoid_hyperrect[2 * i + 1], ssEta[i], ssLb[i], ssUb[i]);

						/* avoid data is only used in the low-level code to check if a point is avoid */
						/* we inflate it with quarter-eta to avoid any precision errors in float comparison */
						avoid_hyperrect[2 * i + 0] -= (concrete_t)(ssEta[i] / 4.0);
						avoid_hyperrect[2 * i + 1] += (concrete_t)(ssEta[i] / 4.0);

						avoid_data +=
							std::string("{") + std::to_string(avoid_hyperrect[2 * i + 0]) +
							", " + std::to_string(avoid_hyperrect[2 * i + 1]) + std::string("}");

						if (i != (ssDim - 1))
							avoid_data += std::string(", ");
					}

					params.push_back(AMYTISS_KERNEL_PARAM_DEFINE_HAS_AVOID);
					paramvals.push_back("#define HAS_AVOID");


					params.push_back(AMYTISS_KERNEL_PARAM_AVOID_DATA);
					paramvals.push_back(avoid_data);
				}
				else{
					params.push_back(AMYTISS_KERNEL_PARAM_DEFINE_HAS_AVOID);
					paramvals.push_back("");

					params.push_back(AMYTISS_KERNEL_PARAM_AVOID_DATA);
					paramvals.push_back("");
				}


				
			}else if (specs_type == std::string(AMYTISS_CONFIG_PARAM_specs_type_value_safe)){
				params.push_back(AMYTISS_KERNEL_PARAM_DEFINE_HAS_SAFE);
				paramvals.push_back("#define HAS_SAFE");

				params.push_back(AMYTISS_KERNEL_PARAM_DEFINE_HAS_TARGET);
				paramvals.push_back("");

				params.push_back(AMYTISS_KERNEL_PARAM_TARGET_DATA);
				paramvals.push_back("");

				params.push_back(AMYTISS_KERNEL_PARAM_TARGET_SET_LB);
				paramvals.push_back("");

				params.push_back(AMYTISS_KERNEL_PARAM_TARGET_SET_UB);
				paramvals.push_back("");

				params.push_back(AMYTISS_KERNEL_PARAM_TARGET_SET_WIDTHS);
				paramvals.push_back("");

				params.push_back(AMYTISS_KERNEL_PARAM_TARGET_SET_NUM_SYMBOLS);
				paramvals.push_back("");

				params.push_back(AMYTISS_KERNEL_PARAM_DEFINE_HAS_AVOID);
				paramvals.push_back("");

				params.push_back(AMYTISS_KERNEL_PARAM_AVOID_DATA);
				paramvals.push_back("");

				SafetyOrReachability = true;
			}else{
				throw std::runtime_error("amytissKernel::amytissKernel: invalid specifacation type specified in the config file.");
			}
		}	

		/* post dynamics */
		params.push_back(AMYTISS_KERNEL_PARAM_POST_DYNAMICS_CONSTANTS);
		paramvals.push_back(spCfg->readConfigValueString(AMYTISS_CONFIG_PARAM_post_dynamics_constant_values));
		params.push_back(AMYTISS_KERNEL_PARAM_POST_DYNAMICS_BEFORE);
		paramvals.push_back(spCfg->readConfigValueString(AMYTISS_CONFIG_PARAM_post_dynamics_code_before));
		params.push_back(AMYTISS_KERNEL_PARAM_POST_DYNAMICS_BODY);
		std::stringstream ssDynamics;
		for (size_t i = 0; i < ssDim; i++){
			std::string xxidx = std::string(AMYTISS_CONFIG_PARAM_post_dynamics_xx) + std::to_string(i);
			ssDynamics << "xx[" << i << "] = " << spCfg->readConfigValueString(xxidx) << ";" << std::endl;
		}
		std::string dynamics = ssDynamics.str();
		paramvals.push_back(dynamics);
		params.push_back(AMYTISS_KERNEL_PARAM_POST_DYNAMICS_AFTER);
		paramvals.push_back(spCfg->readConfigValueString(AMYTISS_CONFIG_PARAM_post_dynamics_code_after));

		// noise stuff: 1- defines needed for the pdf
		params.push_back(AMYTISS_KERNEL_PARAM_PDF_DEFINES);
		paramvals.push_back(amytissGetPdfDefines());

		// noise stuff: 2- the pdf body
		params.push_back(AMYTISS_KERNEL_PARAM_PDF_FUNCTION_BODY);
		paramvals.push_back(amytissGetPdfAsCFunctionBody());
		
		// for contrller synthesis, number of steps in time to calc
		params.push_back(AMYTISS_KERNEL_PARAM_TIME_STEPS);
		paramvals.push_back(std::to_string(time_steps));

		size_t num_control_bytes = XU_bag::getNumControlBytes(time_steps);
		if (num_control_bytes > 0 && saveC) {
			params.push_back(AMYTISS_KERNEL_PARAM_HAS_CONTROL_BYTES);
			paramvals.push_back(std::string("#define HAS_CONTROL_BYTES"));
		}
		else {
			params.push_back(AMYTISS_KERNEL_PARAM_HAS_CONTROL_BYTES);
			paramvals.push_back(std::string(""));
		}
		params.push_back(AMYTISS_KERNEL_PARAM_CONTROL_BYTES);
		paramvals.push_back(std::to_string(num_control_bytes));

		// widths and number of symbols of all spaces
		xSpaceFlatWidth = amytissGetFlatWidthFromConcreteSpace(ssDim, ssEta, ssLb, ssUb, {}, xSpacePerDimWidth);
		uSpaceFlatWidth = amytissGetFlatWidthFromConcreteSpace(isDim, isEta, isLb, isUb, {}, uSpacePerDimWidth);
		wSpaceFlatWidth = amytissGetFlatWidthFromConcreteSpace(wsDim, wsEta, wsLb, wsUb, {}, wSpacePerDimWidth);

		if (xSpaceFlatWidth.getBlkCount() > 1 || uSpaceFlatWidth.getBlkCount() > 1 || wSpaceFlatWidth.getBlkCount() > 1)
			throw std::runtime_error("Symbolic spaces with more than 2^64 symbols is not yet supported in AMYTISS.");

		params.push_back(AMYTISS_KERNEL_PARAM_SS_NUMSYM);
		paramvals.push_back(std::to_string(pfacesBigInt::getPrimitiveValue(xSpaceFlatWidth)));
		params.push_back(AMYTISS_KERNEL_PARAM_IS_NUMSYM);
		paramvals.push_back(std::to_string(pfacesBigInt::getPrimitiveValue(uSpaceFlatWidth)));
		params.push_back(AMYTISS_KERNEL_PARAM_WS_NUMSYM);
		paramvals.push_back(std::to_string(pfacesBigInt::getPrimitiveValue(wSpaceFlatWidth)));

		params.push_back(AMYTISS_KERNEL_PARAM_SS_WIDTHS);
		paramvals.push_back(pfacesUtils::vector2string(xSpacePerDimWidth));
		params.push_back(AMYTISS_KERNEL_PARAM_IS_WIDTHS);
		paramvals.push_back(pfacesUtils::vector2string(uSpacePerDimWidth));
		params.push_back(AMYTISS_KERNEL_PARAM_WS_WIDTHS);
		paramvals.push_back(pfacesUtils::vector2string(wSpacePerDimWidth));

		// Extra include files
		std::string extra_inc_files = m_spCfg->readConfigValueString(AMYTISS_CONFIG_PARAM_include_files);
		std::string rep_inc_files;
		extra_inc_dir = "";
		if (!extra_inc_files.empty()) {
			std::stringstream ss_rep_inc_files;
			std::string CFG_DIR = pfacesFileIO::getFileDirectoryPath(m_spCfg->getConfigFilePath());
			if (CFG_DIR.empty() || CFG_DIR == std::string("")) {
				CFG_DIR = std::string(".") + std::string(PFACES_PATH_SPLITTER);
			}

			std::vector<std::string> file_names = pfacesUtils::strSplit(extra_inc_files, ";", false);
			for (size_t i = 0; i < file_names.size(); i++) {
				string expanded_file_names = file_names[i];
				expanded_file_names = pfacesUtils::strReplaceAll(expanded_file_names, ".\\", CFG_DIR);
				expanded_file_names = pfacesUtils::strReplaceAll(expanded_file_names, "./", CFG_DIR);
				if (!pfacesFileIO::isFileExist(expanded_file_names)) {
					pfacesTerminal::showWarnMessage(std::string("The exxtra include file: ") + expanded_file_names +
						std::string(" is ignored since it does not exist."));
					continue;
				}
				std::string file_dir = pfacesFileIO::getFileDirectoryPath(expanded_file_names);
				extra_inc_dir += std::string(" -I") + file_dir;
				file_names[i] = pfacesUtils::strReplaceAll(expanded_file_names, file_dir, "");
				file_names[i] = pfacesUtils::strReplaceAll(file_names[i], "\\", "");
				file_names[i] = pfacesUtils::strReplaceAll(file_names[i], "/", "");
				ss_rep_inc_files << "#include \"" << file_names[i] << "\"" << std::endl;
			}
			rep_inc_files = ss_rep_inc_files.str();
		}
		params.push_back(AMYTISS_KERNEL_PARAM_EXTRA_INC_FILES);
		paramvals.push_back(rep_inc_files);


		// updating the list of params
		updateParameters(params, paramvals);


		// TASK3: Creating the kernel function and load their memory fingerprints
		//------------------------------------------------------------------------
		std::string mem_fingerprint_file = spLaunchState->getKernelPackPath() + std::string("amytiss.mem");

		size_t XU_bag_size = XU_bag::getSize(saveP, num_reach_states, time_steps, saveC, 
			pfacesBigInt::getPrimitiveValue(wSpaceFlatWidth));

		size_t V_size = (sizeof(concrete_t))*pfacesBigInt::getPrimitiveValue(xSpaceFlatWidth);
	
		pfacesKernelFunction abstractFunction(AMYTISS_KERNEL_FUNC_ABSTRACT_NAME,
			{ AMYTISS_KERNEL_FUNC_ABSTRACT_ARG_XU_BAG_NAME});
		pfacesKernelFunctionArguments args_abstract = 
			pfacesKernelFunctionArguments::loadFromFile(mem_fingerprint_file, AMYTISS_KERNEL_FUNC_ABSTRACT_NAME, 
				{ AMYTISS_KERNEL_FUNC_ABSTRACT_ARG_XU_BAG_NAME});
		args_abstract.m_baseTypeSize = {XU_bag_size};
		abstractFunction.setArguments(args_abstract);
		addKernelFunction(abstractFunction);

		pfacesKernelFunction synthesizetFunction(AMYTISS_KERNEL_FUNC_SYNTHESIZE_NAME,
			{ AMYTISS_KERNEL_FUNC_SYNTHESIZE_ARG_XU_BAG_NAME, AMYTISS_KERNEL_FUNC_SYNTHESIZE_ARG_V_NAME});
		pfacesKernelFunctionArguments args_synthesize =
			pfacesKernelFunctionArguments::loadFromFile(mem_fingerprint_file, AMYTISS_KERNEL_FUNC_SYNTHESIZE_NAME,
				{ AMYTISS_KERNEL_FUNC_SYNTHESIZE_ARG_XU_BAG_NAME, AMYTISS_KERNEL_FUNC_SYNTHESIZE_ARG_V_NAME});
		args_synthesize.m_baseTypeSize = {XU_bag_size, V_size};
		synthesizetFunction.setArguments(args_synthesize);
		addKernelFunction(synthesizetFunction);

		pfacesKernelFunction collectFunction(AMYTISS_KERNEL_FUNC_COLLECT_NAME,
			{ AMYTISS_KERNEL_FUNC_COLLECT_ARG_XU_BAG_NAME, AMYTISS_KERNEL_FUNC_COLLECT_ARG_V_NAME});
		pfacesKernelFunctionArguments args_collect =
			pfacesKernelFunctionArguments::loadFromFile(mem_fingerprint_file, AMYTISS_KERNEL_FUNC_COLLECT_NAME,
				{ AMYTISS_KERNEL_FUNC_COLLECT_ARG_XU_BAG_NAME, AMYTISS_KERNEL_FUNC_COLLECT_ARG_V_NAME});
		args_collect.m_baseTypeSize = {XU_bag_size, V_size};
		collectFunction.setArguments(args_collect);
		addKernelFunction(collectFunction);

		// setting the dimensions of X and Y
		setDimensions(ssDim, singletonInput?1:isDim);


		// TASK4: show some data
		// -----------------------------
		flat_t xuSpaceWidth = xSpaceFlatWidth * uSpaceFlatWidth;
	
		pfacesTerminal::showMessage(std::string("X space size: ") +
			std::to_string(pfacesBigInt::getPrimitiveValue(xSpaceFlatWidth)) +
			std::string(" (") + pfacesUtils::vector2string(xSpacePerDimWidth, 'x') + std::string(")"));
		pfacesTerminal::showMessage(std::string("U space size: ") +
			std::to_string(pfacesBigInt::getPrimitiveValue(uSpaceFlatWidth)) +
			std::string(" (") + pfacesUtils::vector2string(uSpacePerDimWidth, 'x') + std::string(")"), !singletonInput);
		if (singletonInput)
			pfacesTerminal::showMessage(" [No input, singleton symbolic set]");
		pfacesTerminal::showMessage(std::string("W space size: ") +
			std::to_string(pfacesBigInt::getPrimitiveValue(wSpaceFlatWidth)) +
			std::string(" (") + pfacesUtils::vector2string(wSpacePerDimWidth, 'x') + std::string(")"), !singletonDisturbance);
		if (singletonDisturbance)
			pfacesTerminal::showMessage(" [No disturbance, singleton symbolic set]");

		pfacesTerminal::showMessage(std::string("AMYTISS's threads will mainly work on a 2D space (X x U) with size: ") +
			std::to_string(pfacesBigInt::getPrimitiveValue(xuSpaceWidth)));
	
		if (ssWasMisAlignedFlag) {
			std::stringstream ssMsg;
			ssMsg << "The X-space is realigned to match the quantization levels:" << std::endl;
			ssMsg << "New lower-bounds: " << pfacesUtils::vector2string(ssLb) << std::endl;
			ssMsg << "New upper-bounds: " << pfacesUtils::vector2string(ssUb) << std::endl;
			std::string msg = ssMsg.str();
			pfacesTerminal::showWarnMessage(msg);
		}
		if (isWasMisAlignedFlag && !singletonInput) {
			std::stringstream ssMsg;
			ssMsg << "The U-space is realigned to match the quantization levels:" << std::endl;
			ssMsg << "New lower-bounds: " << pfacesUtils::vector2string(isLb) << std::endl;
			ssMsg << "New upper-bounds: " << pfacesUtils::vector2string(isUb) << std::endl;
			std::string msg = ssMsg.str();
			pfacesTerminal::showWarnMessage(msg);
		}
		if (wsWasMisAlignedFlag && !singletonDisturbance) {
			std::stringstream ssMsg;
			ssMsg << "The W-space is realigned to match the quantization levels:" << std::endl;
			ssMsg << "New lower-bounds: " << pfacesUtils::vector2string(wsLb) << std::endl;
			ssMsg << "New upper-bounds: " << pfacesUtils::vector2string(wsUb) << std::endl;
			std::string msg = ssMsg.str();
			pfacesTerminal::showWarnMessage(msg);
		}

		pfacesTerminal::showMessage("Done configuring the AMYTISS kernel.");
	}

	/* providing implementation of the virtual method: configureParallelProgram*/
	void amytissKernel::configureParallelProgram(pfacesParallelProgram& parallelProgram) {

	
	#ifdef PFACES_USE_MPI
		pfacesTerminal::showWarnMessage("MPI support is not supported in AMYTISS. We run on local node only !.");
	#endif // PFACES_USE_MPI

		// A parallel advisor used for task scheduling
		pfacesParallelAdvisor parallelAdvisor(parallelProgram.getMachine(), parallelProgram.getTargetDevicesIndicies());


		// ---------------------------------------------------------
		// TASK SCHEDULING
		// ---------------------------------------------------------
		// - Creating the 2D compute space and scheduling the tasks
		// - Distributing the jobs for the three main functions: abstrac, synthesize
		cl::NDRange ndUniversalRangeXU(pfacesBigInt::getPrimitiveValue(xSpaceFlatWidth), pfacesBigInt::getPrimitiveValue(uSpaceFlatWidth));
		cl::NDRange ndUniversalRangeX(pfacesBigInt::getPrimitiveValue(xSpaceFlatWidth));
		cl::NDRange ndUniversalOffsetXU = cl::NullRange;
		std::pair<cl::NDRange, cl::NDRange> XU_processRangeAndOffset = parallelAdvisor.getProcessNDRangeAndOffset(ndUniversalRangeXU);
		cl::NDRange ndProcessRangeXU = XU_processRangeAndOffset.first;
		cl::NDRange ndProcessOffsetXU = XU_processRangeAndOffset.second;
		std::pair<cl::NDRange, cl::NDRange> X_processRangeAndOffset = parallelAdvisor.getProcessNDRangeAndOffset(ndUniversalRangeX);
		cl::NDRange ndProcessRangeX = X_processRangeAndOffset.first;
		cl::NDRange ndProcessOffsetX = X_processRangeAndOffset.second;	
		std::vector<std::shared_ptr<pfacesDeviceExecuteJob>> perDevAbstractionJobs, perDevSynthesisJobs, perDevCollectJobs;

		if (parallelProgram.m_beVerboseLevel >= 2) {
			pfacesTerminal::showMessage(std::string("Scheduling abstraction/synthesis jobs on the targeted devices ... "));
		}

		perDevAbstractionJobs = parallelAdvisor.distributeJob(
			*this, AMYTISS_KERNEL_FUNC_ABSTRACT_INDEX, ndProcessRangeXU, ndProcessOffsetXU,
			parallelProgram.m_isFixedJobDistribution, parallelProgram.m_fixedJobDistribution, true, false, false);

		perDevSynthesisJobs = parallelAdvisor.distributeJob(
			*this, AMYTISS_KERNEL_FUNC_SYNTHESIZE_INDEX, ndProcessRangeXU, ndProcessOffsetXU,
			parallelProgram.m_isFixedJobDistribution, parallelProgram.m_fixedJobDistribution, true, false, false);

		perDevCollectJobs = parallelAdvisor.distributeJob(
			*this, AMYTISS_KERNEL_FUNC_COLLECT_INDEX, ndProcessRangeX, ndProcessOffsetX,
			parallelProgram.m_isFixedJobDistribution, parallelProgram.m_fixedJobDistribution, true, false, false);		

		if (ndProcessRangeXU[0] != pfacesBigInt::getPrimitiveValue(xSpaceFlatWidth) 
			|| ndProcessRangeXU[1] != pfacesBigInt::getPrimitiveValue(uSpaceFlatWidth)) {
			std::stringstream ssmsg;
			ssmsg << "The space-size is modified so that devices will have no unused "
				<< "cores or to match the needs of local memory of the GPU-based kernel!" << std::endl
				<< "New X-space size: " << ndProcessRangeXU[0] << " symbols" << std::endl
				<< "New U-space size: " << ndProcessRangeXU[1] << " symbols";
			pfacesTerminal::showWarnMessage(ssmsg.str());
		}

		// print the task-scheduling report
		if (parallelProgram.m_beVerboseLevel >= 2) {
			parallelAdvisor.printTaskSchedulingReport(
				parallelProgram.getMachine(),
				{AMYTISS_KERNEL_FUNC_ABSTRACT_NAME, AMYTISS_KERNEL_FUNC_SYNTHESIZE_NAME, AMYTISS_KERNEL_FUNC_COLLECT_NAME},
				{ perDevAbstractionJobs, perDevSynthesisJobs, perDevCollectJobs},
				ndUniversalRangeXU[0]
			);
		}


		// ---------------------------------------------------------
		// MEMORY ALLOCATION
		// ---------------------------------------------------------
		// Allocating the memory used for abstraction/synthesis
		std::vector<std::pair<char*, size_t>> dataPool;
		pFacesMemoryAllocationReport memReport;


		memReport = allocateMemory(dataPool, parallelProgram.getMachine(), parallelProgram.getTargetDevicesIndicies(),
									pfacesUtils::oclGetRangeVolume(ndProcessRangeXU), false);

		// print the memory-allocation report
		if (parallelProgram.m_beVerboseLevel >= 2) {
			memReport.PrintReport();
		}	

		// preparing sub-buffer info for the all functions - at arg index 0 ! 
		if (parallelProgram.countTargetDevices() > 1) {
			subBuffersAbstractRWBag = getSubBuffers(perDevAbstractionJobs, AMYTISS_KERNEL_FUNC_ABSTRACT_INDEX,
				AMYTISS_KERNEL_FUNC_ABSTRACT_ARG_XU_BAG_INDEX, memReport.bufferFinalSize[0], 
				pfacesBigInt::getPrimitiveValue(uSpaceFlatWidth));

			subBuffersSznthesizeRWBag = getSubBuffers(perDevSynthesisJobs, AMYTISS_KERNEL_FUNC_SYNTHESIZE_INDEX,
				AMYTISS_KERNEL_FUNC_SYNTHESIZE_ARG_XU_BAG_INDEX, memReport.bufferFinalSize[0],
				pfacesBigInt::getPrimitiveValue(uSpaceFlatWidth));

			subBuffersCollectV = getSubBuffers(perDevCollectJobs, AMYTISS_KERNEL_FUNC_COLLECT_INDEX,
				AMYTISS_KERNEL_FUNC_COLLECT_ARG_V_INDEX, memReport.bufferFinalSize[1], 1);		
		
			// printing the sub-buffering report
			if (parallelProgram.m_beVerboseLevel >= 2) {
				parallelAdvisor.printSubBufferingReport(
					{ AMYTISS_KERNEL_FUNC_ABSTRACT_NAME,				AMYTISS_KERNEL_FUNC_SYNTHESIZE_NAME,				AMYTISS_KERNEL_FUNC_COLLECT_NAME},
					{ AMYTISS_KERNEL_FUNC_ABSTRACT_INDEX,				AMYTISS_KERNEL_FUNC_SYNTHESIZE_INDEX,				AMYTISS_KERNEL_FUNC_COLLECT_INDEX},
					{ AMYTISS_KERNEL_FUNC_ABSTRACT_ARG_XU_BAG_INDEX,	AMYTISS_KERNEL_FUNC_SYNTHESIZE_ARG_XU_BAG_INDEX,	AMYTISS_KERNEL_FUNC_COLLECT_ARG_V_INDEX},
					{ AMYTISS_KERNEL_FUNC_ABSTRACT_NUM_ARGS,			AMYTISS_KERNEL_FUNC_SYNTHESIZE_NUM_ARGS,			AMYTISS_KERNEL_FUNC_COLLECT_NUM_ARGS},
					{ subBuffersAbstractRWBag,							subBuffersSznthesizeRWBag,							subBuffersCollectV}
				);
			}
		}

		// ---------------------------------------------------------
		// Crearing the parallel program
		// ---------------------------------------------------------
		std::vector<std::shared_ptr<pfacesInstruction>> instrList;
		const cl::Device& dataAccessDevice = parallelProgram.getTargetDevices()[0];

		// preparing some repeatingly used isntructions
		std::shared_ptr<pfacesDeviceReadJob> jobReadAllData;
		std::shared_ptr<pfacesDeviceWriteJob> jobWriteAllData;
		std::shared_ptr<pfacesInstruction> instr_readAllData = std::make_shared<pfacesInstruction>();
		std::shared_ptr<pfacesInstruction> instr_writeAllData = std::make_shared<pfacesInstruction>();
		jobReadAllData = std::make_shared<pfacesDeviceReadJob>(dataAccessDevice);
		jobReadAllData->setKernelFunctionIdx(AMYTISS_KERNEL_FUNC_ABSTRACT_INDEX, AMYTISS_KERNEL_FUNC_ABSTRACT_NUM_ARGS);
		jobWriteAllData = std::make_shared<pfacesDeviceWriteJob>(dataAccessDevice);
		jobWriteAllData->setKernelFunctionIdx(AMYTISS_KERNEL_FUNC_ABSTRACT_INDEX, AMYTISS_KERNEL_FUNC_ABSTRACT_NUM_ARGS);
		instr_readAllData->setAsReadAllDeviceData(jobReadAllData);
		instr_writeAllData->setAsWriteAllDeviceData(jobWriteAllData);
		std::shared_ptr<pfacesInstruction> instrSyncPoint = std::make_shared<pfacesInstruction>();
		instrSyncPoint->setAsBlockingSyncPoint();
		std::shared_ptr<pfacesInstruction> instrLogOn = std::make_shared<pfacesInstruction>();
		std::shared_ptr<pfacesInstruction> instrLogOff = std::make_shared<pfacesInstruction>();
		instrLogOn->setAsLogOn();
		instrLogOff->setAsLogOff();

		// INSTRUCTION: a start message 
		std::shared_ptr<pfacesInstruction> instrMsg_start = std::make_shared<pfacesInstruction>();
		instrMsg_start->setAsMessage(
			std::string("The parallel program has started ... we start with the initialization") +
			(saveP?(std::string("/abstraction")):(std::string(""))) +
			std::string("!")
		);
		instrList.push_back(instrMsg_start);


		// INSTRUCTION: write memory bags to devices
		// if not using th direct access to host memory, we write the data to the device memory 
		// and followed by a barrier to sync among all device threads
		if (!parallelProgram.m_useHostMemory) {
			instrList.push_back(instr_writeAllData);

			if (parallelProgram.countTargetDevices() > 1)
				instrList.push_back(instrSyncPoint);
		}

		// INSTRUCTIONS: Log on
		// turn log on if we are debugging
		if(parallelProgram.m_oclDebug){
			instrList.push_back(instrLogOn);
		}

		// INSTRUCTIONS: Abatsractin parallal jobs
		// The first main task: ABSTRACTION
		for (size_t i = 0; i < perDevAbstractionJobs.size(); i++) {
			std::shared_ptr<pfacesInstruction> tmpExecuteInstr = std::make_shared<pfacesInstruction>();

			if (subBuffersAbstractRWBag.size() != 0) {
				perDevAbstractionJobs[i]->setSubBufferBase(
					AMYTISS_KERNEL_FUNC_ABSTRACT_ARG_XU_BAG_INDEX,
					subBuffersAbstractRWBag[i].first);

				perDevAbstractionJobs[i]->setSubBufferSize(
					AMYTISS_KERNEL_FUNC_ABSTRACT_ARG_XU_BAG_INDEX,
					subBuffersAbstractRWBag[i].second);
			}

			tmpExecuteInstr->setAsDeviceExecute(perDevAbstractionJobs[i]);
			instrList.push_back(tmpExecuteInstr);
		}


		// INSTRUCTION: a sync point after the constrution of abstraction !
		instrList.push_back(instrSyncPoint);

		// INSTRUCTIOJ: log off
		// turn log off after execution
		if(parallelProgram.m_oclDebug){
			instrList.push_back(instrLogOff);
		}

		// INSTRUCTION: a message
		// Notify the user that abstraction is complete
		std::shared_ptr<pfacesInstruction> instr_MsgAbsComplete = std::make_shared<pfacesInstruction>();
		instr_MsgAbsComplete->setAsMessage(
			std::string("Initialization") +
			(saveP ? (std::string("/abstraction")) : (std::string(""))) +
			std::string(" completed") +
			((time_steps != 0) ? std::string(" and we continue with synthesis") : std::string("")) +
			((time_steps != 0 && !saveP) ? std::string(" with on-the-fly abstraction.") : std::string("."))
		);
		instrList.push_back(instr_MsgAbsComplete);



		// INSTRUCTION: we put a asequecnce of synthesis job based on number of time steps
		for (size_t t = 0; t < time_steps; t++){

			// INSTRUCTIONS: Log on
			// turn log on if we are debugging
			if(parallelProgram.m_oclDebug){
				instrList.push_back(instrLogOn);
			}

			// the synthesis/collect jobs
			for (size_t i = 0; i < perDevSynthesisJobs.size(); i++) {

				// a synthesize task
				std::shared_ptr<pfacesInstruction> tmpSynthInstr = std::make_shared<pfacesInstruction>();
				if (subBuffersSznthesizeRWBag.size() != 0) {
					perDevSynthesisJobs[i]->setSubBufferBase(
						AMYTISS_KERNEL_FUNC_SYNTHESIZE_ARG_XU_BAG_INDEX,
						subBuffersSznthesizeRWBag[i].first);

					perDevSynthesisJobs[i]->setSubBufferSize(
						AMYTISS_KERNEL_FUNC_SYNTHESIZE_ARG_XU_BAG_INDEX,
						subBuffersSznthesizeRWBag[i].second);
				}
				tmpSynthInstr->setAsDeviceExecute(perDevSynthesisJobs[i]);
				instrList.push_back(tmpSynthInstr);

				// sync
				if (parallelProgram.countTargetDevices() > 1) {
					instrList.push_back(instrLogOff);
					instrList.push_back(instrSyncPoint);
					instrList.push_back(instrLogOn);
				}
				

				// a collect task
				std::shared_ptr<pfacesInstruction> tmpCollectInstr = std::make_shared<pfacesInstruction>();
				if (subBuffersCollectV.size() != 0) {
					perDevCollectJobs[i]->setSubBufferBase(
						AMYTISS_KERNEL_FUNC_COLLECT_ARG_V_INDEX,
						subBuffersCollectV[i].first);

					perDevCollectJobs[i]->setSubBufferSize(
						AMYTISS_KERNEL_FUNC_COLLECT_ARG_V_INDEX,
						subBuffersCollectV[i].second);
				}
				tmpCollectInstr->setAsDeviceExecute(perDevCollectJobs[i]);
				instrList.push_back(tmpCollectInstr);

				// sync
				instrList.push_back(instrSyncPoint);			
			}

			// INSTRUCTIOJ: log off
			// turn log off after execution
			if(parallelProgram.m_oclDebug){
				instrList.push_back(instrLogOff);
			}			

			// INSTRUCTION: a message of one time step
			// Notify the user that abstraction is complete
			std::shared_ptr<pfacesInstruction> instr_MsgSynthOneStepComplete = std::make_shared<pfacesInstruction>();
			instr_MsgSynthOneStepComplete->setAsMessage(
				std::to_string(t + 1) + std::string("/") + std::to_string(time_steps) +
				std::string(" time-step(s) of the synthesis completed.")
			);
			instrList.push_back(instr_MsgSynthOneStepComplete);
		}


		// INSTRUCTION: a message
		// Notify the user that abstraction is complete
		if(time_steps != 0){
			std::shared_ptr<pfacesInstruction> instr_MsgSynthComplete = std::make_shared<pfacesInstruction>();
			instr_MsgSynthComplete->setAsMessage("Synthesis completed. We now save the controller.");
			instrList.push_back(instr_MsgSynthComplete);
		}

		// INSTRUCTION: read memory bags from devices
		// if not using th direct access to host memory, we write the data to the device memory		
		// and followed by a barrier to sync among all device threads
		if (!parallelProgram.m_useHostMemory) {
			instrList.push_back(instr_readAllData);

			if (parallelProgram.countTargetDevices() > 1)
				instrList.push_back(instrSyncPoint);
		}

		// INSTRUCTION: last instructin is a sync point !
		instrList.push_back(instrSyncPoint);


		// ---------------------------------------------------------
		// Finalize !
		// ---------------------------------------------------------
		// setting the params back to the parallel program
		parallelProgram.m_Universal_globalNDRange = ndUniversalRangeXU;
		parallelProgram.m_Universal_offsetNDRange = ndUniversalOffsetXU;
		parallelProgram.m_Process_globalNDRange = ndProcessRangeXU;
		parallelProgram.m_Process_offsetNDRange = ndProcessOffsetXU;
		parallelProgram.m_dataPool = dataPool;
		parallelProgram.m_spInstructionList = instrList;
		if(!extra_inc_dir.empty())
			parallelProgram.m_oclOptions += extra_inc_dir;



		// register a pre/post-execute instruction to save the data
		std::vector<std::shared_ptr<void>> preExecuteParamsList;
		registerPreExecuteFunction(initializeV, "Initializing V", preExecuteParamsList);
		std::vector<std::shared_ptr<void>> postExecuteParamsList;
		registerPostExecuteFunction(saveData, "Saving results", postExecuteParamsList);	

	}

	/* providing implementation of the virtual method: configureTuneParallelProgram*/
	void amytissKernel::configureTuneParallelProgram(pfacesParallelProgram& tuneParallelProgram, size_t targetFunctionIdx) {
		(void)tuneParallelProgram;
		(void)targetFunctionIdx;

		pfacesTerminal::showInfoMessage("TODO: Implement the tuner program of AMYTISS to have better results !");
	}
}

// registering the kernel 
PFACES_REGISTER_LOADABLE_KERNEL(amytiss::amytissKernel)
