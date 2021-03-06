function Q=GivensRotation(i, j, theta)
% Returns a rotation matrix along the axis that is not present(i>j).
    k=3-mod(i+j, 3);
    cosine=cos(theta);
    sine=sign(i-j)*sin(theta);
    Q=zeros(3,3);
    Q(i,i)=cosine;
    Q(j,j)=cosine;
    Q(i,j)=sine;
    Q(j,i)=-sine;
    Q(k,k)=1;
end

