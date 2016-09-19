%DEMO_MATHIEU_JD   demo for method twopareigs_jd
%
% This example computes first eigenmodes for the Mathieu two-parameter eigenvalue problem
% using Jacobi-Davidson method for two-parameter eigenvalue problems
%
% See also: TWOPAREIGS_JD, MATHIEU_MEP, TWOPAREIGS_IRA, TWOPAREIGS_SI

% MultiParEig toolbox
% B. Plestenjak, University of Ljubljana
% FreeBSD License, see LICENSE.txt

% Last revision: 8.9.2015

n = 400;   % size of the matrices
neig = 10; % number of wanted eigenvalues
[A1,B1,C1,A2,B2,C2] = mathieu_mep(n,n,2,2,1); 

%% First version uses implicitly restarted Arnoldi with full vectors and
% Bartels-Stewart method for the Sylvester equation
tic; [lambda1,mu1,X1,Y1] = twopareigs_ira(A1,B1,C1,A2,B2,C2,neig); t1=toc
mu1

%% Second version uses subspace Arnoldi
opts = [];
opts.lowrank = neig;
opts.window = neig;
opts.arnsteps = 1;
opts.delta = eps*max(norm(A1),norm(A2));
opts.showinfo = 1;
opts.softlock = 0;
opts
tic; [lambda2,mu2,X1,Y1] = twopareigs_si(A1,B1,C1,A2,B2,C2,neig,opts); t2=toc
mu2

%% Third version is Jacobi-Davidson
opts = [];
opts.M1 = inv(A1);
opts.M2 = inv(A2);
opts.target = [0 0];
opts.harmonic = 1;
opts.extraction = 'minmu';
opts.innersteps = 10;
opts.minsize = 5;
opts.maxsize = 15;
opts.maxsteps = 100;
opts.delta = 5*eps*max(norm(A1),norm(A2));
opts.window = 0;
opts.showinfo = 2;
opts.forcereal = 1;
opts
tic; [lambda3,mu3,X3,Y3,X3l,Y3l] = twopareigs_jd(A1,B1,C1,A2,B2,C2,neig,opts); t3=toc
mu3
