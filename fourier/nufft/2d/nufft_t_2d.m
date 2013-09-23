function g=nufft_t_2d(beta,x,precision)
%
% Compute the adjoint non-equally spaced FFT in two dimensions.
%
% The function computes the sums
%                   n/2
%        g(j) = sum beta(k1,k2)*exp(i*(k1,k2)*x(j))
%                  k1,k2=-n/2
% for j=1,...,n.
%
% The complexity of the algorithm is O(n^2*log(1/eps)+m*n^2(log(n)))
% m is the oversampling factor (m=2).
%
% Input parameters:
%    beta       Coefficients in the sums above. Real or complex numbers.
%               beta is assumed to be a square matrix.
%    x          Sampling points. Real numbers in the range
%               [-pi,pi]x[-pi,pi]. 
%    precision  'double' or 'single'. Default is 'single'.
%    
%    beta and x need not be the same length, but x should be longer than
%    beta.
%
% Output:
%    g        The sums defined above.
%
% Yoel Shkolnisky, April 2007.
%
% Revisions:
% Filename changed from nufft_t2 to nufft_t_2d. Fixed editor warnings.
% Change default for precision to single. (Y.S. December 22, 2009) 


if nargin<3
    precision='single';
end

if (~strcmpi(precision,'single')) && (~strcmpi(precision,'double'))
    precision='single';
    warning('MATLAB:unkownOption','Unrecognized precsion. Using ''single''.');
end

if strcmpi(precision,'double')
    b=1.5629;
    m=2;
    q=28;
else %single precision
    b=0.5993;
    m=2;
    q=10;
end


if mod(q,2)==1
    error('Set q to an even integer');
end

if length(size(beta))~=2
    error('beta must be a square matrix');
end

if size(beta,1)~=size(beta,2)
    error('beta must be a square matrix');
end

if length(size(x))~=2
    error('x must be a mx2 array')
end

if size(x,2)~=2
    error('x must be a mx2 array');
end

n=length(beta);
len_x=size(x,1);

low_idx=-ceil((n-1)/2);
high_idx=floor((n-1)/2);
idx=low_idx:high_idx;

Q=zeros(len_x,q+1,q+1);
%E=zeros(n,1);
g=zeros(len_x,1);

nu=round(x*m*n/(2*pi));

for k1=-q/2:q/2
    for k2=-q/2:q/2
        tmp=-((x(:,1).*m.*n./(2*pi)-(nu(:,1)+k1)).^2+(x(:,2).*m.*n./(2*pi)-(nu(:,2)+k2)).^2)/(4*b);
        Q(:,k1+q/2+1,k2+q/2+1)=exp(tmp)/(4*b*pi);
    end
end

E=exp(b.*(2.*pi.*idx./(m*n)).^2);
E=E(:);
E=E*E.';
u=beta.*E;

low_idx_u=ceil((m*n-1)/2);
%high_idx_u=floor((n*m-1)/2);
w=zeros(m*n,m*n);
w(low_idx_u+low_idx+1:low_idx_u+low_idx+1+n-1,low_idx_u+low_idx+1:low_idx_u+low_idx+1+n-1)=u;

W=fftshift(ifft2(ifftshift(w)));
%W=W*prod(size(W));
W=W*numel(W);

% Slow version (was replaced by the subsequent block) 
% for k1=-q/2:q/2
%     for k2=-q/2:q/2
%         idx=nu+repmat([k1 k2],len_x,1);
%         idx=idx+repmat([low_idx_u low_idx_u],len_x,1);
%         idx=mod(idx,m*n);
%         for j=1:size(idx,1)
%             g(j)=g(j)+Q(j,k1+q/2+1,k2+q/2+1).*W(idx(j,1)+1,idx(j,2)+1);
%         end
%     end
% end


offset1=zeros(len_x,1);
offset2=repmat([low_idx_u low_idx_u],len_x,1);
for k1=-q/2:q/2
    for k2=-q/2:q/2
        offset1(:,1)=k1; offset1(:,2)=k2;  %avoid allocating memory each time using repmat
        idx=nu+offset1;
        idx=idx+offset2;
        idx=mod(idx,m*n)+1;
        j=(idx(:,2)-1)*n*m+idx(:,1); % fast implementation of  sub2ind([m*n m*n],idx(:,1),idx(:,2));        
        g=g+Q(:,k1+q/2+1,k2+q/2+1).*W(j);
    end
end