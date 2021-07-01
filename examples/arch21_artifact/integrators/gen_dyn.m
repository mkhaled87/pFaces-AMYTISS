clear all
clc

n = 18;


Ns = 0.1;
cut_region = '';
cov = '';
det_cov = 1;
for i=1:n
    str = ['xx' num2str(i-1) ' = "'];
    for c= 1:n
        elem = ['x' num2str(c-1) '*('];
        
        if i == c
            val = '1.0';
        elseif c > i
            x = c-i;
            computed = (Ns^x)/(factorial(x));
            val = num2str(computed);
        else
            val = '0.0';
        end
        
        elem = [elem val ')'];
        if c == 1
            str = [str elem];
        else
            str = [str '+' elem];
        end
    end
    x = n-i+1;
    computed = (Ns^x)/(factorial(x));
    str = [str '+ u0*(' num2str(computed) ')";'];
    disp(str);
    
    cov = [cov '100'];
    cut_region = [cut_region '{-1,1}'];
    if i ~= n
        cov = [cov ', '];
        cut_region = [cut_region ','];
    end
    det_cov = det_cov*0.01;
end
disp('---')
disp(['inv_covariance_matrix = "' cov '";'])
disp(['det_covariance_matrix = "' num2str(det_cov) '";'])
disp(['cutting_region = "' cut_region '";'])