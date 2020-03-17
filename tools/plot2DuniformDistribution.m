% config
mu = [0 0];
sigma = [0.0005 0;0 0.0005];
x1 = -3:0.2:3;
x2 = -3:0.2:3;
inv(sigma)
det(sigma)

% plot
[X1,X2] = meshgrid(x1,x2);
X = [X1(:) X2(:)];
y = mvnpdf(X,mu,sigma);
y = reshape(y,length(x2),length(x1));
surf(x1,x2,y)
caxis([min(y(:))-0.5*range(y(:)),max(y(:))])
axis([-3 3 -3 3 0 max(y(:))])
xlabel('x1')
ylabel('x2')
zlabel('Probability Density')