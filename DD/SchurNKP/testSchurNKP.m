function [lam] = testSchurNKP( m, k )
% Schur complement of the NKP preconditioner with quadrileteral domains.
n=m;
kd1=2:m-1; rd1=[1,m];
kd2=2:n-1; rd2=[1,n];
vec=@(x) x(:);

tol=1E-15;
maxit=100;
restart=7;

% Differential operators
[Dx,x0]=legD(m); Dx=Dx(end:-1:1,end:-1:1); x0=x0(end:-1:1);
[Dy,y0]=legD(n); Dy=Dy(end:-1:1,end:-1:1); y0=y0(end:-1:1);
% Constraint operator
a=[1,1;1,1];
b=[0,0;0,0];
C1=zeros(2,m); C1(:,rd1)=eye(2);
C2=zeros(2,n); C2(:,rd2)=eye(2);
C1=diag(a(1,:))*C1+diag(b(1,:))*Dx(rd1,:);
C2=diag(a(2,:))*C2+diag(b(2,:))*Dy(rd2,:);
% (xx,yy) fine grid for over-integration
[xx,wx]=gauleg(-1,1,m); 
[yy,wy]=gauleg(-1,1,n);

% Vertices
v0=[2i;-1;1];                                             % Isoceles
v0=4/sqrt(3*sqrt(3))*[1i;exp(1i*pi*7/6);exp(-1i*pi*1/6)]; % Equilateral
v0=[-2+3i;0;2];                                           % Scalene
v0=2/(2-sqrt(2))*[1i;0;1];                                % Right angle

L=abs(v0([3,1,2])-v0([2,3,1])); % Sides
V=eye(3)+diag((sum(L)/2-L)./L([2,3,1]))*[-1,0,1; 1,-1,0; 0,1,-1];

z0=zeros(7,1);
z0([1,2,3])=v0;       % Vertices
z0([4,5,6])=V*v0;     % Touch points
z0(7)=(L'*v0)/sum(L); % Incenter


% Assemble quads [NE, NW, SE, SW]
quads=[7,5,4,1; 7,6,5,2; 7,4,6,3];
curv=zeros(size(quads)); curv(:)=-inf;
%[z0, quads, curv]=bingrid();

% Topology
adj=zeros(3,4);
adj(1:3,[1,3])=[2,1; 3,2; 1,3]; % [E,W,N,S]
net=topo(adj);
corners=zeros(size(net));
corners(:,1)=1;                 % [EN,WN,ES,WS]
edges=[1,0;1,0;1,0];
ndom=size(quads,1);
d=[ndom*(m-2)^2, size(adj,1)*(m-2), max(corners(:))];
dofs=sum(d);

% Function handles
stiff=cell(ndom,1); % block stiffness
mass =cell(ndom,1); % block mass
nkp  =cell(ndom,1); % block NKP
gf   =cell(ndom,1); % block NKP Green's function

% Construct Schur NKP preconditioner
S=sparse(m*size(adj,1), m*size(adj,1));

% Evaluate Jacobian determinant J and metric tensor [E, F; F, G]
% Galerkin stiffness and mass (matrix-free) operators, with their NKP
% Update NKP Schur complement and compute local Green functions
for j=1:ndom
F=curvedquad(z0(quads(j,:)),curv(j,:));
[jac,g11,g12,g22] = diffgeom(F,xx,yy);
[stiff{j},mass{j},A1,B1,A2,B2]=lapGalerkin(Dx,Dy,x0,y0,xx,yy,wx,wy,jac,g11,g12,g22);
[S,nkp{j},gf{j}]=feedSchurNKP(S,net(j,:),A1,B1,A2,B2,C1,C2);
end

% Schur LU decomposition
ix=1:size(S,2);
iy=zeros(m,size(adj,1));
e=ones(size(iy));
e([1,end],:)=1/2;

iy(2:end-1,:)=reshape(1:d(2),m-2,[]);
edges(edges==0)=-d(2);
iy([1,end],:)=d(2)+edges';

iy=reshape(iy, size(ix));
e=reshape(e, size(ix));
e(iy==0)=[];
ix(iy==0)=[];
iy(iy==0)=[];
Rschur=sparse(ix,iy,e, size(S,2), d(2)+d(3));
S=Rschur'*S*Rschur;
[Lschur, Uschur, pschur]=lu(S,'vector');

figure(2);
imagesc(log(abs(S)));
title(sprintf('cond(\\Sigma) = %.3f', condest(S)));
colormap(gray(256)); colorbar; axis square;
drawnow;


net(net==0)=max(net(:))+1; 

function [vv] = fullop(op,uu)
    vv=reshape(uu,m,n,[]);
    for r=1:size(vv,3)
        vv(:,:,r)=op{r}(vv(:,:,r));
    end
    vv=reshape(vv,size(uu));
end

function [u] = precond(rhs)
    RHS=reshape(rhs(1:d(1)), m-2, n-2, []);
    v=zeros(m,n,size(RHS,3));
    for r=1:size(adj,1)
        v(:,:,r)=gf{r}(RHS(:,:,r),0,0,0);
    end
    p=d(1);
    s1=zeros(m-2, size(adj,1));
    for r=1:size(adj,1)
        s1(:,r)=rhs(1+p:p+m-2) + ...
                -vec(nkp{adj(r,1)}(v(:,:,adj(r,1)),1,kd2)) + ...
                -vec(nkp{adj(r,3)}(v(:,:,adj(r,3)),kd1,1));
            
        p=p+m-2;
    end
    s0=rhs(p+1)-nkp{1}(v(:,:,1),1,1)-nkp{2}(v(:,:,2),1,1)-nkp{3}(v(:,:,3),1,1);
    srhs=[s1(:); s0];

    % Solve for boundary nodes
    bb=Uschur\(Lschur\srhs(pschur));
    b1=reshape(bb(1:end-corners), m-2, []);
    b1=[b1, zeros(m-2,1)];
    b0=zeros(2,2); 
    b0(1,1)=bb(end-corners+1:end);

    % Solve for interior nodes with the given BCs
    u=zeros(size(v));
    for r=1:ndom
        u(:,:,r)=gf{r}(RHS(:,:,r), b1(:,net(r,1:2))', b1(:,net(r,3:4)), b0);
    end
    u=u(:);
end

function [u] = pick(uu)
    uu=reshape(uu,m,n,[]);
    u=zeros(dofs,1);
    u(1:d(1))=uu(kd1,kd2,:);
    p=d(1);
    for r=1:size(adj,1)
        bx=rd1(adj(r,1:2)>0);
        u(1+p:p+m-2)=vec(uu(bx,kd2,adj(r,1)));
        p=p+m-2;
    end
    u(1+p)=uu(1,1,1);
end

function [uu] = assembly(u)
    uu=zeros(m,n,ndom);
    p=ndom*(m-2)^2;
    uu(kd1,kd2,:)=reshape(u(1:p), m-2,n-2,[]);
    for r=1:size(adj,1)
        bx=rd1(adj(r,1:2)>0);
        by=rd2(adj(r,3:4)>0);
        uu(bx,kd2,adj(r,1))=reshape(u(1+p:p+m-2),n-2,[])';
        uu(kd1,by,adj(r,3))=reshape(u(1+p:p+m-2),m-2,[]);
        p=p+m-2;
    end
    uu(1,1,:)=u(1+p);
end

function [u] = Rtransp(uu)
    uu=reshape(uu,m,n,[]);
    u=zeros(dofs,1);
    u(1:d(1))=uu(kd1,kd2,:);
    p=d(1);
    for r=1:size(adj,1)
        bx=rd1(adj(r,1:2)>0);
        by=rd2(adj(r,3:4)>0);
        u(1+p:p+m-2)=vec(uu(bx,kd2,adj(r,1)))+vec(uu(kd1,by,adj(r,3)));
        p=p+m-2;
    end
    u(1+p)=sum(uu(1,1,:));
end

function [u] = afun(u)
    for r=1:size(u,2)
        u(:,r)=Rtransp(fullop(stiff, assembly(u(:,r))));
    end
end

function [u] = bfun(u)
    for r=1:size(u,2)
        u(:,r)=Rtransp(fullop(mass, assembly(u(:,r))));
    end
end

pcalls=0;
function [u] = pfun(u)
    for r=1:size(u,2)
        pcalls=pcalls+1;
        u(:,r)=pick(precond(u(:,r)));
    end    
end

function [uu,flag,relres,iter]=poissonSolver(F,ub)
    if nargin==1
        ub=zeros(size(F));
    end
    rhs=Rtransp(fullop(mass,F)-fullop(stiff,ub));
    uu=pfun(rhs);
    [uu,flag,relres,iter]=gmres(@afun,rhs,restart,tol,ceil(maxit/restart),[],@pfun,uu);
    uu=ub+reshape(assembly(uu),size(ub));  
end
[xx,yy]=ndgrid(x0,y0);

if nargin>1
    tol=1E-11;
    [U,lam,~,~,relres]=lobpcg(rand(dofs,k),@afun,@bfun,@pfun,[],tol,maxit);
    relres=relres(:,end);
    display(relres);
    
    uuu=zeros(m,n,ndom,k);
    for j=1:k
        uuu(:,:,:,j)=assembly(U(:,j));
    end
    uuu=ipermute(uuu,[1,2,4,3]);
    
    figure(1); zoom off; pan off; rotate3d off;
    for j=1:size(uuu,4)
        ww=mapquad(z0(quads(j,:)),xx,yy);
        modegallery(real(ww), imag(ww), uuu(:,:,:,j));
        if j==1, hold on; end
    end
    hold off;    
else
    F=ones(m,n,ndom);
    [uu,~,relres,~]=poissonSolver(F);
    lam=[];
    display(relres);
    
    figure(1);
    for j=1:ndom
        ww=mapquad(z0(quads(j,:)), xx, yy);
        surf(real(ww), imag(ww), uu(:,:,j));
        if j==1, hold on; end
    end 
    hold off;
end

colormap(jet(256));
view(2);
shading interp; camlight;
dx=diff(xlim());
dy=diff(ylim());
pbaspect([dx,dy,min(dx,dy)]);
display(pcalls);
end

function [net]=topo(adj)
% Inverts adjacency map from inter->doms to dom->inters (E,W,N,S)
ndoms=max(adj(:));
net=zeros(ndoms,4);
net(adj(adj(:,1)>0,1),1)=find(adj(:,1)>0);
net(adj(adj(:,2)>0,2),2)=find(adj(:,2)>0);
net(adj(adj(:,3)>0,3),3)=find(adj(:,3)>0);
net(adj(adj(:,4)>0,4),4)=find(adj(:,4)>0);
end