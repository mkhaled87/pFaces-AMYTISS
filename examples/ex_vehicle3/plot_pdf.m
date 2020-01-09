mu = [0 0];
sigma = inv(diag([1.5, 1.5, 1.5]))
det_sigma = det(sigma)

x1 = -5:0.2:5;
x2 = -5:0.2:5;
[X1,X2] = meshgrid(x1,x2);
X = [X1(:) X2(:)];

y = mvnpdf(X,mu,sigma(1:2,1:2));
y = reshape(y,length(x2),length(x1));

surf(x1,x2,y)
caxis([min(y(:))-0.5*range(y(:)),max(y(:))])
axis([-5 5 -5 5 0 0.4])
xlabel('x1')
ylabel('x2')
zlabel('Probability Density')