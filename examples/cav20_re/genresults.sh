#!/bin/bash

PFACES_OPTIONS='-CGH -d 1 -p -k amytiss.cpu@../../kernel-pack'
TARGET_CONFIGS=( \
    ../ex_stochy/stochy2.cfg \
    ../ex_stochy/stochy3.cfg \
    ../ex_stochy/stochy4.cfg \
    ../ex_stochy/stochy5.cfg \
    ../ex_stochy/stochy6.cfg \
    ../ex_stochy/stochy7.cfg \
    ../ex_stochy/stochy8.cfg \
    ../ex_stochy/stochy9.cfg \
    ../ex_stochy/stochy10.cfg \
    ../ex_stochy/stochy11.cfg \
    ../ex_stochy/stochy12.cfg \
    ../ex_stochy/stochy13.cfg \
    ../ex_stochy/stochy14.cfg \
    ../ex_toy_safety/toy2d.cfg \
    ../ex_toy_safety/toy2d.cfg \
    ../ex_toy_reachavoid/toy2d.cfg \
    ../ex_toy_reachavoid/toy2d.cfg \
    ../ex_roomtemp3/roomtemp3.cfg \
    ../ex_roomtemp3/roomtemp3.cfg \
    ../ex_roomtemp5/roomtemp5.cfg \
    ../ex_roomtemp5/roomtemp5.cfg \
    ../ex_traffic3/traffic3.cfg \
    ../ex_traffic3/traffic3.cfg \
    ../ex_traffic5/traffic5.cfg \
    ../ex_traffic5/traffic5.cfg \
    ../ex_vehicle3/vehicle3d.cfg \
    ../ex_vehicle3/vehicle3d.cfg \
    ../ex_vehicle7/vehicle7d.cfg \
    ../ex_vehicle7/vehicle7d.cfg \
)
TARGET_NAMES=( \
    "2D_STCHY_SAFETY    " \
    "3D_STCHY_SAFETY    " \
    "4D_STCHY_SAFETY    " \
    "5D_STCHY_SAFETY    " \
    "6D_STCHY_SAFETY    " \
    "7D_STCHY_SAFETY    " \
    "8D_STCHY_SAFETY    " \
    "9D_STCHY_SAFETY    " \
    "10D_STCHY_SAFETY   " \
    "11D_STCHY_SAFETY   " \
    "12D_STCHY_SAFETY   " \
    "13D_STCHY_SAFETY   " \
    "14D_STCHY_SAFETY   " \
    "2D_ROBOT_SAFETY    " \
    "2D_ROBOT_SAFETY_OFA" \
    "2D_ROBOT_RAVOID    " \
    "2D_ROBOT_RAVOID_OFA" \
    "3D_RTEMP_SAFETY    " \
    "3D_RTEMP_SAFETY_OFA" \
    "5D_RTEMP_SAFETY    " \
    "5D_RTEMP_SAFETY_OFA" \
    "3D_TRAFK_SAFETY    " \
    "3D_TRAFK_SAFETY_OFA" \
    "5D_TRAFK_SAFETY    " \
    "5D_TRAFK_SAFETY_OFA" \
    "3D_AUCAR_RAVOID    " \
    "3D_AUCAR_RAVOID_OFA" \
    "7D_AUCAR_RAVOID    " \
    "7D_AUCAR_RAVOID_OFA" \
)
TARGET_OPTIONS=( \
    "-co \"save_transitions=true\"" \
    "-co \"save_transitions=true\"" \
    "-co \"save_transitions=true\"" \
    "-co \"save_transitions=true\"" \
    "-co \"save_transitions=true\"" \
    "-co \"save_transitions=true\"" \
    "-co \"save_transitions=true\"" \
    "-co \"save_transitions=true\"" \
    "-co \"save_transitions=true\"" \
    "-co \"save_transitions=true\"" \
    "-co \"save_transitions=true\"" \
    "-co \"save_transitions=true\"" \
    "-co \"save_transitions=true\"" \
    "-co \"save_transitions=true\"" \
    "-co \"save_transitions=false\"" \
    "-co \"save_transitions=true\"" \
    "-co \"save_transitions=false\"" \
    "-co \"save_transitions=true\"" \
    "-co \"save_transitions=false\"" \
    "-co \"save_transitions=true\"" \
    "-co \"save_transitions=false\"" \
    "-co \"save_transitions=true\"" \
    "-co \"save_transitions=false\"" \
    "-co \"save_transitions=true\"" \
    "-co \"save_transitions=false\"" \
    "-co \"save_transitions=true\"" \
    "-co \"save_transitions=false\"" \
    "-co \"save_transitions=true\"" \
    "-co \"save_transitions=false\"" \
)

if test ${#TARGET_CONFIGS[@]} -ne ${#TARGET_NAMES[@]}
then
    printf "Size mismatch in the lngths of arrays: TARGET_CONFIGS, TARGET_NAMES !\n"
    exit 1
fi
if test ${#TARGET_CONFIGS[@]} -ne ${#TARGET_OPTIONS[@]}
then
    printf "echo Size mismatch in the lngths of arrays: TARGET_CONFIGS, TARGET_OPTIONS !\n"
    exit 1
fi

for i in "${!TARGET_CONFIGS[@]}"
do
    rm -f tmp.out
    printf "(${TARGET_NAMES[i]}):"
	pfaces $PFACES_OPTIONS -cfg ${TARGET_CONFIGS[i]} ${TARGET_OPTIONS[i]} > tmp.out

    CONFIG_DIR=$(eval "dirname \"${VAR}\"")
    rm -f CONFIG_DIR/*.raw

    PET_LINE=$(eval "cat tmp.out | grep 'Program execution time'")
    ALC_LINE=$(eval "cat tmp.out | grep 'Total Alloc.'")
    XU_SIZE=$(eval "cat tmp.out | grep -Ei -o '(\(X x U\) with size: )[0-9]*'")
    
    printf "  $PET_LINE\t|\t$ALC_LINE\t|\t$XU_SIZE\n" 
    mv tmp.out ${TARGET_NAMES[i]}
done
