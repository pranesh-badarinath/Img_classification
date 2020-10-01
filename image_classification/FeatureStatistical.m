function [F]=FeatureStatistical(im)
% Summary of this function goes here
im=double(im);
r=mean(mean(im));
% g=mean(mean(im(:,:,2)));
% b=mean(mean(im(:,:,3)));
%s=std(std(im));
% k=skewness(skewness(im));
% t=kurtosis(kurtosis(im));
F=[r];
end

