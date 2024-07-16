function DF = Wavelet(img)

% input:    img -- NxN matrix (single channel infrared image)
% output:   DF  -- sharpness of wavelet transform of the input image

X = double(img);

[c,s]=wavedec2(X,1,'haar');

ch1=detcoef2('h',c,s,1);
cv1=detcoef2('v',c,s,1);
cd1=detcoef2('d',c,s,1);

%DF = std2(ch1)*std2(cv1)*std2(cd1);
DF = var(ch1,[],'all')*var(cv1,[],'all')*var(cd1,[],'all');

end
