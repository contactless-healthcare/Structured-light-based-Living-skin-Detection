function DF = ST_Energy(t,image1,image2)

% input:    image1, image2  -- NxNx2 matrix (two consecutive single-channel
% images)
%           t               -- Total number of frames of image sequence
% output:   DF              -- spatio-temporal energy of gradient

[h,w]= size(image1);

img = double(image1(1:h-1,1:w-1));
img1 = double(image2(1:h-1,1:w-1));

row = double(image1(2:h,1:w-1));
col = double(image1(1:h-1,2:w));

DF = sum(((img-row).^2) .* ((img-col).^2) ./ ((img1-img).^2+0.02), 'all');

DF = DF/((h-1)*(w-1)*(t-1));
end