x = [0,1,3];
xx = [1 1 1
      x]';
u = [2;1;1];

%% 1
% least square fit
% u = a0 + a1x
a = (xx'*xx)\(xx'*u)

ix=0:0.1:3;
gx = a(1) + a(2) * ix;
plot(ix,gx)
hold on;
scatter(x,u)

gx2 = 1/3*ix.^2 - 4/3*ix +2;
figure;
plot(ix,gx2)
hold on;
scatter(x,u)

%% 2
gx3 = 1.9444 * phi(-1,0,1,ix) + 0.9444 * phi(0,1,2,ix) + 0.6111*phi(1,2,3,ix) + 0.9444*phi(2,3,4,ix);
plot(ix,gx3)

