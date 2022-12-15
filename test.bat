@ECHO OFF

rem Testing example: ex_toy_reach
cd examples\ex_toy_reach
pfaces -CG -k amytiss.cpu@..\..\kernel-pack -cfg .\toy2d.cfg -d 1 -p
cd ..\..
