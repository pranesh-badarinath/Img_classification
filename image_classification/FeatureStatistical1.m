function [F]=FeatureStatistical1(im)

try
    im=double(im);
    r=mean(mean(im(:,:,1)));
    g=mean(mean(im(:,:,2)));
    b=mean(mean(im(:,:,3)));
    r1=std(std(im(:,:,1)));
    g1=std(std(im(:,:,2)));
    b1=std(std(im(:,:,3)));
    F=[r g b r1 b1 g1];
catch
    im=double(im);
    r =mean(mean(im));
    r1=std(std(im));
    F=[r r r r1 r1 r1];
end
end

