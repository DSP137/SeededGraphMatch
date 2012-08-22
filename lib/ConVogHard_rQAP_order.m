function [ corr,iter ,max_fvals,fval,fval_after_proj,P_whole,P_proj] = ConVogHard_rQAP_order( A,B,m,ordering,useJV )

% [ corr,iter ,max_fvals,fval,fval_after_proj,P_whole,P_proj] = ConVogHard_rQAP_order( A,B,m,ordering,useJV ) 
% is the syntax.
%  A,B are (m+n)x(m+n) adjacency matrices, 
% loops/multiedges/directededges allowed.
% It is assumed that the first m vertices of A's graph
% correspond respectively to the first m vertices of B's graph,
% corr gives the vertex correspondences  
% For example, corr=[ 1 2 7 16 30 ...
% means that the vtx1ofA-->vtx1ofB, 2-->2, 3-->7, 4-->16, 5-->30 
%  example: EXECUTE the following:
% >> v=[ [1:5] 5+randperm(400)]; B=round(rand(405,405));A=B(v,v);
% >> [corr,P] = ConVogHard( A,B,5 ) ; [v; corr]
% ready June 1, 2012   (Donniell's code)


[totv,~]=size(A);
n=totv-m;

A12=A(ordering(1:m),ordering(m+1:m+n));
A21=A(ordering(m+1:m+n),ordering(1:m));
A22=A(ordering(m+1:m+n),ordering(m+1:m+n));
B12=B(ordering(1:m),ordering(m+1:m+n));
B21=B(ordering(m+1:m+n),ordering(1:m));
B22=B(ordering(m+1:m+n),ordering(m+1:m+n));


patience=25;
tol=1E-3;
epsilon=0.01;
P=ones(n,n)/n;
toggle=1;
iter=0;
fvals = zeros(patience+1,4);
alpha_vals =zeros(1,patience+1);
while (toggle==1)&(iter<patience)
    iter=iter+1;
    Grad=A22*P*B22'+A22'*P*B22+A21*B21'+A12'*B12;
    ind=[];
    if useJV 
        ind=lapjv(-Grad,0.01);
    else
        ind=YiCaoHungarian(-Grad);
    end
    T=eye(n);
    T=T(ind,:);
    c=trace(A22'*P*B22*P');
    d=trace(A22'*T*B22*P')+trace(A22'*P*B22*T');
    e=trace(A22'*T*B22*T');
    u=trace(P'*A21*B21'+P'*A12'*B12);
    v=trace(T'*A21*B21'+T'*A12'*B12);
    alpha=-(d-2*e+u-v)/(2*(c-d+e));
    f0=e+v;
    f1=c+u;
    falpha=(c-d+e)*alpha^2+(d-2*e+u-v)*alpha+e+v;
     fvals(iter,1)=f1;
    fvals(iter,2)=falpha;
    fvals(iter,3)=f0;
    fvals(iter,4)= norm(Grad,2);
    alpha_vals(iter+1) = alpha;
%     if (isnan(falpha))
%     Grad
%     c-d+e
%     alpha
%     end
    newfval=0;
    if ((alpha>0)&&(falpha>f0)&&(falpha>f1))
        P=alpha*P+(1-alpha)*T;
         newfval=falpha;
    elseif (f0>(f1+epsilon))
        P=T;
        newfval=f0;
    else
        toggle=0;
    end
    if ((abs(newfval-f1)/abs(f1))<tol) 
        toggle=0;    
    end
end
alpha_vals;
corr=[];
    if useJV 
        corr=lapjv(-P,0.01);
    else
        corr=YiCaoHungarian(-P);
        
    end
%corr=lapjv(-P,0.01);
%corr=lapjv(-P,0.01);


corr=[ ordering(1:m),  ordering(m+corr)];
P_whole=[ eye(m) zeros(m,n) ; zeros(n,m) P];
max_fvals= fvals;
norm_mat = A(ordering,ordering)*P_whole-P_whole*B(ordering,ordering);
fval=sum(sum(abs(norm_mat)));


 P_proj=eye(m+n);
 P_proj=P_proj(corr,:);
norm_mat_proj = A*P_proj-P_proj*B;
fval_after_proj= sum(sum(abs(norm_mat_proj)));

end

