function g=slow_nufft_t_2d(beta,x)
%
% Compute directly the sums
% The function computes the sums
%               n/2
%        g(j) = sum beta(k1,k2)*exp(i*(k1,k2)*x(j))
%              k1,k2=-n/2
% for j=1,...,m.
% where n is the length of beta and x.
%
% x must have two columns.
%
% The complexity of the computation is O(m*n^2).
%
% If m is missing then m=n;
%
% Yoel Shkolnisky, December 2006.

n=size(beta);
m=size(x,1);

if size(x,2)~=2
    error('x must have two columns')
end

low_idx1=-ceil((n(1)-1)/2);
high_idx1=floor((n(1)-1)/2);
low_idx2=-ceil((n(2)-1)/2);
high_idx2=floor((n(2)-1)/2);

g=zeros(size(x,1),1);

for j=1:m
    for k1=low_idx1:high_idx1
        for k2=low_idx2:high_idx2
            g(j)=g(j)+beta(k1-low_idx1+1,k2-low_idx2+1)*exp(i*(k1*x(j,1)+k2*x(j,2)));
        end
    end
end


