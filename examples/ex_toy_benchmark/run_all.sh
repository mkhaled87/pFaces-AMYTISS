#!/bin/bash

DEV=1

../../../../bin/pfaces -CGH -d $DEV -k amytiss.cpu@../../kernel-pack -cfg toy2d_safe.cfg -p;
../../../../bin/pfaces -CGH -d $DEV -k amytiss.cpu@../../kernel-pack -cfg toy2d_safe_ofa.cfg -p;
../../../../bin/pfaces -CGH -d $DEV -k amytiss.cpu@../../kernel-pack -cfg toy2d_reachavoid.cfg -p;
../../../../bin/pfaces -CGH -d $DEV -k amytiss.cpu@../../kernel-pack -cfg toy2d_reachavoid_ofa.cfg -p;
