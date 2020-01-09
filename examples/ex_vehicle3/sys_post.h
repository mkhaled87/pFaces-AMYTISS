// The post function
void sys_post(float* xp, const float* x, const float* u);
void sys_post(float* xp, const float* x, const float* u){

    // decide a good solving step for this syste based on Ts
    // this is to be chosen imperically for each system and we use
    // matlab's ODE45 solver as a reference for error
	float Ts = 0.100f;
    int divider = 200;
	
	// the rhs
	float f[3];
    
    // now we have new smaller Ts
    Ts = Ts/((float)divider);
	
	// init xp
	for (int i=0; i<3; i++){
		xp[i] = x[i];
	}
	
	// solve
    for (int k=0; k <divider; k++){
        
		f[0] = u[0]*cos(atan((float)(tan(u[1])/2.0))+xp[2])/cos((float)atan((float)(tan(u[1])/2.0)));
		f[1] = u[0]*sin(atan((float)(tan(u[1])/2.0))+xp[2])/cos((float)atan((float)(tan(u[1])/2.0)));
		f[2] = u[0]*tan(u[1]);
		
        // post state for the given Ts
		for (int i=0; i<3; i++){
			xp[i] = xp[i] + Ts*f[i];
		}
    }
}