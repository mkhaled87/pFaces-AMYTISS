% X, Y, Theta, V
mu = [0 0 0 0];
sigma = inv(diag([250 250 250 250]))
det_sigma = det(sigma)

% The grid generators + the grid
x1 = -2.5:0.1:2.5;
x2 = -2.5:0.1:2.5;
x3 = -3.2:0.1:3.2;
x4 = -1.9:0.1:1.9;
[X1,X2,X3,X4] = ndgrid(x1,x2, x3, x4);

% gen MV-PF
X = [X1(:) X2(:) X3(:) X4(:)];
y = mvnpdf(X,mu,sigma);

% cross-section at others=0 to extraact the PDF at one dim
y_for_x1 = y(all(X(:,[2 3 4]) == 0, 2),:);
y_for_x2 = y(all(X(:,[1 3 4]) == 0, 2),:);
y_for_x3 = y(all(X(:,[1 2 4]) == 0, 2),:);
y_for_x4 = y(all(X(:,[1 2 3]) == 0, 2),:);

% plot sepratae
subplot(2,2,1);
title('x1');
plot(x1,y_for_x1);

subplot(2,2,2);
title('x2');
plot(x2,y_for_x2);

subplot(2,2,3);
title('x3');
plot(x3,y_for_x3);

subplot(2,2,4);
title('x4');
plot(x4,y_for_x4);





