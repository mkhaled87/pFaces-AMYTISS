#!/bin/bash

# get and show system size
n="$@"
echo "We will run the integrator example with n=" "$n"

# set device selection
dev="-CG -d 1"
echo "We will run pFaces using the following device config:" "$dev"

# config the template
project_name="integrator_$n"
save_transitions="true"
if [[ $n -gt 4 ]]
then
  echo "The dimension is greater than 4 and we decideed to switch to the memory efficent kernel."
  save_transitions="false"
fi

ss_eta=0.1
ss_lb=-10
ss_ub=10
for (( i=0; i<$n; i++ ))
do
    if [[ $i -gt 0 ]]
    then
        states_eta="$states_eta,"
        states_lb="$states_lb,"
        states_ub="$states_ub,"
    fi

    states_eta="$states_eta$ss_eta"
    states_lb="$states_lb$ss_lb"
    states_ub="$states_ub$ss_ub"
done
echo $states_eta
echo $states_lb
echo $states_ub


# build the override
overrides="\"project_name=$project_name,save_transitions=$save_transitions,states=$n\""

# run it
echo pfaces -cfg template.cfg -k amytiss.cpu@../../../kernel-pack -p -co $overrides $dev
#pfaces -cfg template.cfg -k amytiss.cpu@../../../kernel-pack -p -co "$overrides" $dev

