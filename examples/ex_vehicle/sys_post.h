// The post function
void sys_post(float* xp, const float* x, const float* u);
void sys_post(float* xp, const float* x, const float* u){

    // decide a good solving step for this syste based on Ts
    // this is to be chosen imperically for each system and we use
    // matlab's ODE45 solver as a reference for error
	float Ts = 0.100f;
    int divider = 200;
	
	// BMW 320i params
	float mu = 1.0489f;
	float C_Sf = 20.898084f; 
	float C_Sr = 20.898084f; 
	float lf = 1.156195f;
	float lr = 1.422717f;
	float h = 0.613730f;
	float m = 1.093295e+03f;
	float I = 1.791599e+03f;
	float g = 9.81f;
	float lwb = 2.578913f; 
	
	// the rhs
	float f[7];
    
    // now we have new smaller Ts
    Ts = Ts/((float)divider);
	
	// init xp
	for (int i=0; i<7; i++){
		xp[i] = x[i];
	}
	
	// solve
    for (int k=0; k <divider; k++){
        
		// kinematic model for small velocities ?
        if (fabs(x[3]) < 0.1){
		
            f[0] = x[3]*cos(x[4]);
            f[1] = x[3]*sin(x[4]);
            f[2] = u[0];
            f[3] = u[1];
            f[4] = x[3]/lwb*tan(x[2]);
            f[5] = u[1]*lwb*tan(x[2]) + x[3]/(lwb*cos(x[2])*cos(x[2]))*u[0];
            f[6] = 0;
		}
        else{
            f[0] = x[3]*cos(x[6] + x[4]);
            f[1] = x[3]*sin(x[6] + x[4]);
            f[2] = u[0];
            f[3] = u[1];
            f[4] = x[5];
            f[5] = -mu*m/(x[3]*I*(lr+lf))*(lf*lf*C_Sf*(g*lr-u[1]*h) + lr*lr*C_Sr*(g*lf + u[1]*h))*x[5]
                +mu*m/(I*(lr+lf))*(lr*C_Sr*(g*lf + u[1]*h) - lf*C_Sf*(g*lr - u[1]*h))*x[6]
                +mu*m/(I*(lr+lf))*lf*C_Sf*(g*lr - u[1]*h)*x[2];
            f[6] = (mu/(x[3]*x[3]*(lr+lf))*(C_Sr*(g*lf + u[1]*h)*lr - C_Sf*(g*lr - u[1]*h)*lf)-1)*x[5]
                -mu/(x[3]*(lr+lf))*(C_Sr*(g*lf + u[1]*h) + C_Sf*(g*lr-u[1]*h))*x[6]
                +mu/(x[3]*(lr+lf))*(C_Sf*(g*lr-u[1]*h))*x[2]; 
        }
		
        // post state for the given Ts
		for (int i=0; i<7; i++){
			xp[i] = xp[i] + Ts*f[i];
		}
    }
}