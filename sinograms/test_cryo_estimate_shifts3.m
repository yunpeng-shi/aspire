% Like test_cryo_estimate_rotations2, but estimates the rotations from the
% common lines using synchronization.  
%
% Yoel Shkolnisky, January 2015.
clear;
n=65;
n_projs=100;
SNRlist=[2^10 2^1 1 1/2 1/4 1/8 1/16];
max_shift=3;
shift_step=0.5;
results=zeros(numel(SNRlist),5);

open_log(0);

for snridx=1:numel(SNRlist)
    initstate;
    [projs,noisy_projs,shifts_2d_ref,rots_ref]=cryo_gen_projections(n,n_projs,SNRlist(snridx),max_shift,shift_step);
    
    log_message('SNR=%5.3e',SNRlist(snridx));
    
    %viewstack(noisy_projs,5,5);
    masked_projs=mask_fuzzy(noisy_projs,floor(n/2)); % Applly circular mask
            
    % Compute polar Fourier transform, using radial resolution n_r and angular
    % resolution n_theta.
    n_theta=360;
    n_r=ceil(n/2);
    [pf,sampling_freqs]=cryo_pft(masked_projs,n_r,n_theta,'single');  % take Fourier transform of projections
    
    %% Compte common lines matrix
    % Compute reference common lines matrix
    clstack_ref=clmatrix_cheat(rots_ref,n_theta);
    
    % Search for common lines in the presence of shifts
    [clstack,corrstack,shift_equations1,shift_equations_map,clstack_mask]=...
        cryo_clmatrix(pf,n_projs,0,ceil(2*sqrt(2)*max_shift),shift_step);
    
    % Print the percentage of correctly detected commonlines. Shoule be very
    % close to 100%.
    prop=comparecl( clstack, clstack_ref, n_theta, 5 );
    log_message('Percentage of correct common lines: %f%%',prop*100);
    
    % Estimate 2D shifts from the equations estimated using common lines.
    est_shifts1=shift_equations1(:,1:end-1)\shift_equations1(:,end);
    est_shifts1=full(transpose(reshape(est_shifts1,2,n_projs)));
    
    % Compare the shift estimation of the current function to the shift
    % estimation from the equations computed by cryo_clmatrix.
    [~,~,V]=svd(full(shift_equations1(:,1:end-1)));
    s1=reshape(shifts_2d_ref.',2*n_projs,1);
    s2=reshape(est_shifts1.',2*n_projs,1);
    V=V(:,1:end-3); % Null space of shift_equations.
    err1=norm(V.'*(s1-s2))/norm(V.'*s1);
    log_message('cryo_clmatrix shift errors: %8.5e',err1);
    
    %% Estimate shifts using estimated rotations
    S=cryo_syncmatrix_vote(clstack,n_theta);
    [rotations,~,mse]=cryo_syncrotations(S,rots_ref);
    log_message('MSE of the estimated rotations: %f',mse); %Show be close to zero.

    
    [est_shifts2,shift_equations2]=cryo_estimate_shifts(pf,rotations,...
        ceil(2*sqrt(2)*max_shift),shift_step,1,[],0);
    
    [~,~,V]=svd(full(shift_equations2(:,1:end-1)));
    s1=reshape(shifts_2d_ref.',2*n_projs,1);
    s2=reshape(est_shifts2.',2*n_projs,1);
    V=V(:,1:end-3); % Null space of shift_equations.
    err2=norm(V.'*(s1-s2))/norm(V.'*s1);
    log_message('cryo_estimate_shifts error: %8.5e',err2);
    log_message('***********************')
    
    
    results(snridx,1)=SNRlist(snridx);  % SNR
    results(snridx,2)=prop;        % Percentange of correctly detected common lines
    results(snridx,3)=err1;        % Shift error from cryo_clmatrix
    results(snridx,4)=err2;        % Shift error from cryo_estimate_shifts
    results(snridx,5)=mse;         % MSE of estimated rotations
end

%% Plot results

figure;
semilogx(results(:,1),results(:,3),'r');
hold on;
semilogx(results(:,1),results(:,4),'b');
legend('cryo\_clmatrix','cryo\_est\_shifts');
hold off;
set(gca, 'xdir','reverse')
xlabel('SNR')
ylabel('shift estimation error');


figure;
plot(results(:,2),results(:,3),'r');
hold on;
plot(results(:,2),results(:,4),'b');
legend('cryo\_clmatrix','cryo\_est\_shifts');
hold off;
set(gca, 'xdir','reverse')
xlabel('detection rate')
ylabel('shift estimation error');
