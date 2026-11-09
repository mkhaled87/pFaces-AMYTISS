#!/bin/sh
set -e

# build kernel driver if not present
[ ! -f ./kernel-pack/amytiss.driver ] && sh ./build.sh

# Testing example: ex_toy_reach (Reachability)
echo "\n=================================================="
echo " Running: ex_toy_reach (Reachability)"
echo "=================================================="
cd examples/ex_toy_reach
pfaces -CG -k amytiss.cpu@../../kernel-pack -cfg ./toy2d.cfg -d 1 -p
cd ../..
python3 ./examples/ex_toy_reach/verify_closedloop.py

# Testing example: ex_toy_safety (Safety)
echo "\n=================================================="
echo " Running: ex_toy_safety (Safety)"
echo "=================================================="
cd examples/ex_toy_safety
pfaces -CG -k amytiss.cpu@../../kernel-pack -cfg ./toy2d.cfg -d 1 -p
cd ../..
python3 ./examples/ex_toy_safety/verify_safety.py

# Testing example: ex_toy_reachavoid (Reach-Avoid)
echo "\n=================================================="
echo " Running: ex_toy_reachavoid (Reach-Avoid)"
echo "=================================================="
cd examples/ex_toy_reachavoid
pfaces -CG -k amytiss.cpu@../../kernel-pack -cfg ./toy2d.cfg -d 1 -p
cd ../..
python3 ./examples/ex_toy_reachavoid/verify_reachavoid.py

# Testing example: ex_roomtemp3 (Coupled Thermal Safety)
echo "\n=================================================="
echo " Running: ex_roomtemp3 (Coupled Thermal Safety)"
echo "=================================================="
cd examples/ex_roomtemp3
pfaces -CG -k amytiss.cpu@../../kernel-pack -cfg ./roomtemp3.cfg -d 1 -p
cd ../..
python3 ./examples/ex_roomtemp3/verify_safety.py

echo "\n=================================================="
echo " ALL E2E VERIFICATION SUITES PASSED SUCCESSFULLY!"
echo "=================================================="
