function [ ] = waveGalerkin( n )
% Solves the wave equation using legedre collocation - weak Galerkin
% spectral method.

% Diff matrix, nodes and quadrature
[D,x,w]=legD(n);

% Boundary conditions
a=[1,1];  % Dirichlet
b=[-1,1]; % Neumann
kd=2:n-1;
rd=[1,n];
I=eye(n);
B=diag(a)*I(rd,:)+diag(b)*D(rd,:);
G=-B(:,rd)\B(:,kd);

% Boundary connection
J=diag([b(1)/a(1), -b(2)/a(2)]);

% Schur complement
E=I(:,kd)+I(:,rd)*G;
SD=D(:,kd)+D(:,rd)*G;

% Mass matrix
V=VandermondeLeg(x);
Minv=(V*V');
SM=E'*(Minv\E);
SM=(SM+SM')/2;

% Stiffness matrix
SK=SD'*diag(w)*SD-G'*J*G;
SK=(SK+SK')/2;

% Eigenmodes
S=zeros(n,n-2);
[S(kd,:), L]=eig(SK, SM, 'vector');
S(rd,:)=G*S(kd,:);
omega=sqrt(L);

% Force generator
F=-(G'*diag([1,-1])*D(rd,rd)+SD'*diag(w)*D(:,rd))/B(:,rd);

% Initiall conditions
u=(1-x.^2)+exp(-100*x.^2/2);
v=0*(1-x.^2);
bc=B*u;

% Force
f0=F*bc;

% DC component
u0=zeros(n,1);
u0(kd)=SK\f0;
u0(rd)=G*u0(kd)+B(:,rd)\bc;

% Normal modes amplitude
a0=S(kd,:)\(u(kd)-u0(kd));
b0=S(kd,:)\v(kd);

figure(1);
h1=plot(x,u);

figure(2);
h2=plot(x,u);

t=0; tf=16;
nframes=300;
dt=tf/nframes;

err=zeros(n,1);
E=zeros(nframes,1);
for i=1:nframes
    t=t+dt;
    u=u0+S*(cos(omega*t).*a0+(t*sinc(omega*t)).*b0);
    ut=  S*(-omega.*sin(omega*t).*a0+cos(omega*t).*b0);
    utt= S*(-omega.*(omega.*cos(omega*t).*a0+sin(omega*t).*b0));
    
    err(kd)=SM*utt(kd)+SK*u(kd)-f0;
    err(rd)=B*u-bc;
    
    set(h1, 'YData', u);
    set(h2, 'YData', err);
    drawnow;
    
    % Halmintonian
    E(i)=(ut(kd)'*SM*ut(kd)+u(kd)'*SK*u(kd))/2-u(kd)'*f0;
end

figure(3);
plot(dt*(1:nframes), E/mean(E)-1);
end