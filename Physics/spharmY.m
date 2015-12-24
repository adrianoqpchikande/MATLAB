function [] = spharmY(l, m, k)
% Plots the Yml spherical harmonic.
theta=linspace(0, pi, k);
phi=linspace(0, 2*pi, 2*k);
ct=cos(theta(:));
st=sin(theta(:));

% Evaluate Legendre associated polynomial
a(l+1)=1;
P=LegendreP(a,m,ct);
g=sqrt((2*l+1)*factorial(l-abs(m))/(4*pi*factorial(l+abs(m))));
rho=g*P*exp(1i*m*phi);

r=abs(real(rho));
x=r.*(st*cos(phi));
y=r.*(st*sin(phi));
z=bsxfun(@times, ct, r);

figure(1); surf(x,y,z,'EdgeColor','none','CData',angle(rho));
light('Position',[0 0 1]);
caxis([-pi pi]); colormap(hsv(256)); colorbar();
axis equal;
end