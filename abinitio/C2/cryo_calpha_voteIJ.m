function [goodK3,peakh,cosalpha, Kfeasible,cosphifeas] = cryo_calpha_voteIJ(clmatrix,k1,k2,K3,cl_layer,is_perturbed,n_theta,refq)
%
% Apply the voting algorithm for images k1 and k2. clmatrix is the common
% lines matrix, constructed using angular reslution L. K3 are the images to
% use for voting of the pair (k1,k2).
% verbose  1 for detailed massages, 0 for silent execution (default).
%
% The function returns
%   goodK3     The list of all third projections in the peak of the histogram
%              corresponding to the pair (k1,k2).
%   peakh      The height of the peak
%   cosalpha   The cosine of the angle between k1 and k2 induced by each third image in the peak.
%   Kfeasible  Number of third images that satisfy the feasibility
%              condition, that is, form a triangle  with k1 and k2.
%   cosphifeas List of cosine of all feasible angles (no only the peak
%              angles as in cosalpha).
%
% Yoel Shkolnisky, September 2010.
% Revised Match 2012. Revised July 2012 by X. Cheng


%K=size(clmatrix,1);

% Parameters used to compute the smoothed nagle histogram. Same as in
% histfilter_v6 (for compatibility).

if (cl_layer~=1) && (cl_layer~=2)
    error('cl_layer can be either 1 or 2 in a C_2 setting');
end

g = diag([-1 -1 1]);
ntics=60;

x=linspace(0,180,ntics);
h=zeros(size(x));

l_idx=zeros(3); % The matrix of common lines between the triplet (k1,k2,k3).
l_idx(1,2) = clmatrix(k1,k2,cl_layer);
l_idx(2,1) = clmatrix(k2,k1,cl_layer);

% for each k3 image, there are 2 common lines matching to image k1, and the
% same goes for image k2. Therefore every image k2 induces 2^2 possible
% angles (=votes).
nVotesPerImage = 2^2;
phis=zeros(nVotesPerImage*numel(K3),2); % Angle between k1 and k2 induced by each third
% projection k3. The first column is the cosine of
% that angle, The second column is the index k3 of
% the projection that creates that angle.
phis=zeros(nVotesPerImage*numel(K3),4); 

idx=1;

rejected=zeros(nVotesPerImage*numel(K3),3);
rejidx=0;

for k3=K3
    if (k1~=k2) && (k1~=k3) && clmatrix(k1,k2,cl_layer)~=0 ...
        && clmatrix(k1,k3,cl_layer)~=0 && clmatrix(k2,k3,cl_layer)~=0
        % some of the entries in clmatrix may be zero if we cleared
        % them due to small correlation, or if for each image
        % we compute intersections with only some of the other
        % images.
        % l_idx=clmatrix([k1 k2 k3],[k1 k2 k3]);
        %
        % Note that as long as the diagonal of the common lines matrix is
        % zero, the conditions (k1~=k2) && (k1~=k3) are not needed, since
        % if k1==k2 then clmatrix(k1,k2)==0 and similarly for k1==k3 or
        % k2==k3. Thus, the previous voting code (from the JSB paper) is
        % correct even though it seems that we should test also that
        % (k1~=k2) && (k1~=k3) && (k2~=k3), and only (k1~=k2) && (k1~=k3)
        % as tested there.
        
        for layer_in_k1=1:2
            for layer_in_k2=1:2
                l_idx(1,3)=clmatrix(k1,k3,layer_in_k1);
                l_idx(3,1)=clmatrix(k3,k1,layer_in_k1);
                l_idx(2,3)=clmatrix(k2,k3,layer_in_k2);
                l_idx(3,2)=clmatrix(k3,k2,layer_in_k2);
                
                % theta1 is the angle on C1 created by its intersection with C3 and C2.
                % theta2 is the angle on C2 created by its intersection with C1 and C3.
                % theta3 is the angle on C3 created by its intersection with C2 and C1.
                theta1 = (l_idx(1,3) - l_idx(1,2))*2*pi/n_theta; %angle from l12 to l13 (since we only take cosine later on, sign doesn't matter)
                theta2 = (l_idx(2,3) - l_idx(2,1))*2*pi/n_theta; %angle from l21 to l23 (since we only take cosine later on, sign doesn't matter)
                theta3 = (l_idx(3,2) - l_idx(3,1))*2*pi/n_theta; %angle from l31 to l32 (since we only take cosine later on, sign doesn't matter)
                
                c1=cos(theta1);
                c2=cos(theta2);
                c3=cos(theta3);
                % Each common-line corresponds to a point on the unit sphere. Denote the
                % coordinates of these points by (Pix, Piy Piz), and put them in the matrix
                %   M=[ P1x  P2x  P3x ; ...
                %       P1y  P2y  P3y ; ...
                %       P1z  P2z  P3z ].
                %
                % Then the matrix
                %   C=[ 1 c1 c2 ;...
                %       c1 1 c3 ;...
                %       c2 c3 1],
                % where c1,c2,c3 are given above, is given by C=M.'*M.
                % For the points P1,P2, and P3 to form a triangle on the unit shpere, a
                % necessary and sufficient condition is for C to be positive definite. This
                % is equivalent to
                %      1+2*c1*c2*c3-(c1^2+c2^2+c3^2)>0.
                % However, this may result in a traingle that is too flat, that is, the
                % angle between the projections is very close to zero. We therefore use the
                % condition below
                %       1+2*c1*c2*c3-(c1^2+c2^2+c3^2) > 1.0e-5
                % This ensures that the smallest singular value (which is actually
                % controlled by the determinant of C) is big enough, so the matrix is far
                % from singular. This condition is equivalent to computing the singular
                % values of C, followed by checking that the smallest one is big enough.
                
                if 1+2*c1*c2*c3-(c1^2+c2^2+c3^2) > 1.0e-5
                    
                    cos_phi2 = (c3-c1*c2)/(sin(theta1)*sin(theta2));
                    if abs(cos_phi2)>1
                        if abs(cos_phi2)-1>1.0e-12
                            warning('GCAR:numericalProblem','cos_phi2>1. diff=%7.5e...Setting to 1.',abs(cos_phi2)-1);
                        else
                            cos_phi2=sign(cos_phi2);
                        end
                    end
                    
                    phis(idx,1)=cos_phi2;
                    phis(idx,2)=k3;
                    phis(idx,3:4) = [layer_in_k1,layer_in_k2];
                    idx=idx+1;
                else
                    rejidx=rejidx+1;
                    rejected(rejidx,1)=k3;
                    rejected(rejidx,2:3)=[layer_in_k1,layer_in_k2];
                end
            end
            
        end
        
        
    end
end

Kfeasible=idx-1;
phis=phis(1:Kfeasible,:);
rejected=rejected(1:rejidx,:);
cosphifeas=phis(:,1);



goodK3=[];
peakh=-1;
cosalpha=-1;

if idx>1
    % Compute the histogram of the angles between projections k1
    % and k2.
    
    angles=acos(phis(:,1))*180/pi;
    % Angles that are up to 10 degrees apart are considered
    % similar. This sigma ensures that the width of the density
    % estimation kernel is roughly 10 degrees. For 15 degress, the
    % value of the kernel is negligible.
    
    %sigma=2.64;
    sigma=3.0; % For compatibility with histfilter_v6
    
    for j=1:numel(x)
        h(j)=sum(exp(-(x(j)-angles).^2/(2*sigma.^2)));
    end
    
    % We assume that at the location of the peak we get the true angle
    % between images k1 and k2. Find all third images k3, that induce an
    % angle between k1 and k2 that is at most 10 off the true
    % angle. Even for debugging, don't put a value that is smaller than two
    % tics, since the peak might move a little bit due to wrong k3 images
    % that accidentally fall near the peak.
    [peakh,peakidx]=max(h);
    idx=find(abs(angles-x(peakidx))<360/ntics);
    goodK3=phis(idx,2);
    cosalpha=phis(idx,1);
    
%     plot(x,h)
%     hold on;
%     clr=repmat([1 0 0],numel(angles),1);
%     clr(idx,:)=repmat([0 1 0],numel(idx),1);
%     scatter(angles,zeros(size(angles)),20,clr);
%     hold off;
%    
%     shg;
    
    if exist('refq','var') && ~isempty(refq)
        % For debugging, compute the true angle between the images, and compare to
        % the estimated one. The following debugging code is correct only when
        % p=1, for otherwise, it is hard to predict how the errors would affect
        % the results.
        R1t=(q_to_rot(refq(:,k1)))';
        R2t=(q_to_rot(refq(:,k2)))';
        
        cosalpharef=dot(R1t(:,3), R2t(:,3));
        cosalpharefg=dot(R1t(:,3), g*R2t(:,3));
        
        if min(  max(abs(asind(cosalpha-cosalpharef))) , max(abs(asind(cosalpha-cosalpharefg))) )> 1.5*360/ntics
            %warning(['Voted the wrong angle : ' num2str([k1, k2]) ', layer: ' num2str(cl_layer)]);
        end
        
        if ~isscalar(is_perturbed)
            if ~is_perturbed(k1,k2) % Check the angle only for correct common lines.
                % Otherwise, we expect grabageanyway.
                if (max(abs(acosd(cosalpha-cosalpharef)-90))>360/ntics) && ...
                        (max(abs(acosd(cosalpha+cosalpharef)-90))>360/ntics)
                    %warning('Voted the wrong angle');
                end
                
                % Check that we have found the correct third images, and only those.
                % Note that it is possible for wrong k3 images to appear in the list
                % due to an angle that is mistakenly correct. No warnings
                % should appear if there are no errors in the common lines
                % matrix.
                % If the pair (k1,k2) is correct, we are looking for all images k3
                % such that (k1,k3) and (k2,k3) are correct. from this list
                % we subtract the list of images rejected due to too small
                % triangle. The resulting list should be identical to the list
                % goodK3.
                
                goodcount=0;
                goodK3ref=zeros(numel(K3),1);
                
                for k3=K3
                    if (k1~=k2) && (k2~=k3) && (k1~=k3)
                        kk1=min(k1,k3);
                        kk2=max(k1,k3);
                        kk3=min(k2,k3);
                        kk4=max(k2,k3);
                        
                        if kk2>kk1 && kk4>kk3
                            if ~is_perturbed(kk1,kk2) && ~is_perturbed(kk3,kk4)
                                goodcount=goodcount+1;
                                goodK3ref(goodcount)=k3;
                            end
                        end
                    end
                end
                goodK3ref=goodK3ref(1:goodcount);
                goodK3ref=setdiff(goodK3ref,rejected);
                diff=setxor(goodK3ref,goodK3);
                if ~isempty(diff)
                    warning('Voted the wrong images');
                end
            end
        end
    end
end
% fname=sprintf('tmp_%03d_%0.3d.mat',k1,k2);
% save(fname)