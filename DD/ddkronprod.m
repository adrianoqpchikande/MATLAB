function [ lam ] = ddkronprod(m,k)
% Solves the equation Dxx*X*Dyy' using domain decomposition
n=m;


% UIUC block-I
adjx=[3 4; 4 5; 6 7; 7 8];
adjy=[4 2; 2 1; 1 7];

% L-shaped membrane
adjx=[2 1];
adjy=[3 1];

% Topology
[topo,net,RL,TB]=ddtopo(adjx,adjy);
pos=ddpatches(topo);
x0=real(pos);
y0=imag(pos);

% Degrees of freedom
rd1=[1,m];
rd2=[1,n];
kd1=2:m-1;
kd2=2:n-1;

% Constraint operators
E1=eye(m);
E2=eye(n);
C1=E1(rd1,:);
C2=E2(rd2,:);

% Differential operators
[Dx,x]=chebD(m);
[Dy,y]=chebD(n);
A1=Dx*Dx;
A2=Dy*Dy;

% Schur complement
[S,H,V1,V2,LL]=ddschurprod(adjx,adjy,A1,A2,Dx,Dy,C1,C2);
[Lschur, Uschur, pschur]=lu(S,'vector');

figure(2);
imagesc(log(abs(S)));
colormap(gray(256)); colorbar; axis square;
drawnow;

% Poisson solver on the square [-1,1]^2
W1=inv(V1(kd1,kd1));
W2=inv(V2(kd2,kd2));
greenF=@(F) A1(kd1,kd1)\F/A2(kd2,kd2)' ;

% Poisson solver
function [u]=poissonTiles(F)
    F=reshape(F, m-2, n-2, []);
    v=cell([size(net,1),1]);
    for j=1:size(net,1)
        v{j}=greenF(F(:,:,j));
    end
    
    rhs=zeros(m-2, size(RL,1)+size(TB,1));
    for j=1:size(RL,1)
        rhs(:,RL(j,1))=-(Dx(rd1(2),kd1)*v{adjx(j,1)}-Dx(rd1(1),kd1)*v{adjx(j,2)});
    end
    for j=1:size(TB,1)
        rhs(:,TB(j,1))=-(v{adjy(j,1)}*Dy(rd2(2),kd2)'-v{adjy(j,2)}*Dy(rd2(1),kd2)');
    end
    rhs=rhs(:);

    % Solve for boundary nodes
    b=Uschur\(Lschur\rhs(pschur));
    b=reshape(b, m-2, []);
    b=[b, zeros(m-2,1)];
    
    % Solve for interior nodes with the given BCs
    u=zeros(size(F));
    for j=1:size(net,1)
        bb=zeros(m,n);
        bb(rd1,kd2)=b(:,net(j,1:2))';
        bb(kd1,rd2)=b(:,net(j,3:4));
        u(:,:,j)=greenF(F(:,:,j)-A1(kd1,:)*bb*A2(kd2,:)');
    end   
    u=u(:);
end

% Compute eigenmodes using Arnoldi iteration
[U,lam]=eigs(@poissonTiles, size(net,1)*(m-2)*(n-2), k, 'sm');
[lam,id]=sort(real(diag(lam)),'ascend');
U=U(:,id);

um=reshape(U, m-2, n-2, [], k);
uuu=zeros(m,n,k,size(um,3));
[xx,yy]=ndgrid(x,y);
for mode=1:k
    % Retrieve boundary nodes, since they were lost in the eigenmode computation
    rhs=zeros(m-2,size(RL,1)+size(TB,1));
    for i=1:size(RL,1)
        rhs(:,RL(i,1))=-(Dx(rd1(2),kd1)*um(:,:,adjx(i,1),mode)-Dx(rd1(1),kd1)*um(:,:,adjx(i,2),mode));
    end
    for i=1:size(TB,1)
        rhs(:,TB(i,1))=-(um(:,:,adjy(i,1),mode)*Dy(rd2(2),kd2)'-um(:,:,adjy(i,2),mode)*Dy(rd2(1),kd2)');
    end
    b=[reshape(H\rhs(:), m-2, []), zeros(m-2,1)];
    
    % Assemble eigenmode
    for i=1:size(um,3)
        uuu(kd1,kd2,mode,i)=um(:,:,i,mode);
        uuu(rd1,kd2,mode,i)=b(:,net(i,1:2))';
        uuu(kd1,rd2,mode,i)=b(:,net(i,3:4));
    end

end

figure(1);
for i=1:size(uuu,4)
    modegallery(xx+x0(i),yy+y0(i),real(uuu(:,:,:,i)));
    if i==1, hold on; end;
end
hold off;
colormap(jet(256)); camlight; view(2); shading interp; 
xlabel('x'); ylabel('y');

end

