% Test the function Noise_Estimation
%
% Yoel Shkolnisky, October 2014.

%% Generate noise images.
p=129; % Each noise image is of size NxN.
K=10000; % Number of noise images to generate.

% The next line is slow since we compute the reference Power spectrum
% (about three minutes).
[noise,~,Sref]=noise_exp2d(p,K,1); % Generate a stack of noise images

%% Estimate the power spectrum of the noise
psd=Noise_Estimation(noise);

%% Prewhiten the images
prewhitened_data = Prewhiten_image2d(noise, psd);
psd_white=Noise_Estimation(prewhitened_data);

%% Display results
figure;
plot(Sref(p,:),'r');
hold on;
plot(psd(p,:));
hold off;
legend('True','Estimated');
title('1D profile of the noise spectrum');

figure;
plot(psd_white(p,:));
ylim([0,1.1]);
title('1D profile of the noise spectrum after prewhitening');

