function definition_of_spot = ST_EW(vid, start_frame, slide, bboxes, add_Wavelet,show_track)

% The function tracks the position of the spot in each frame of the image sequence, 
% and calculates their STEOG and STWTV.
% input：
%       vid         -- structured light video
%       start_frame -- the index of the first frame in the video
%       slide       -- time length of the iamge sequence
%       bboxes      -- the bounding boxes of all spots in the first frame of the sequence
%       add_Wavelet -- whether to calculate STWTV (1-yes)
%       show_track  -- whether to display the spot tracking process
% 
% output：definition_of_spot -- STEOG and STWTV of all spots

%%% track the laser spots
definition_of_spot = zeros(1,size(bboxes,1));
rect_old = bboxes;
bboxes = double(bboxes);
videoFrames = read(vid, [start_frame start_frame+slide-1]);

opticFlow = opticalFlowLK;
if add_Wavelet
    voxels = cell(1,size(bboxes,1));
end
for i = 1:slide
    % extract specific regions
    image = videoFrames(:,:,:,i);
    image_gray = rgb2gray(image);
    image_blur = image(:,:,1);
    imDisp = image;

    % Using the estimateFlow method to compute dense optical flow
    flow = estimateFlow(opticFlow, image_gray);
    
    for s = 1:size(bboxes,1)
        if i >1
            rect = int32(bboxes(s,:));
            u = mean(flow.Vx(rect(2)+1:rect(2)+rect(4)-1, rect(1)+1:rect(1)+rect(3)-1),'all');
            v = mean(flow.Vy(rect(2)+1:rect(2)+rect(4)-1, rect(1)+1:rect(1)+rect(3)-1),'all');
            bboxes(s,:) = bboxes(s,:) + [u v 0 0];
        else
            voxels{s} = cat(3,voxels{s},image_blur(rect_old(s,2):rect_old(s,2)+rect_old(s,4), rect_old(s,1):rect_old(s,1)+rect_old(s,3)));
        end
        rect1 = int32(bboxes(s,:));
        % Check whether the bbox exceeds the boundary and correct it.
        if rect1(1)<1
            rect1(1)  = 1;
        end
        if rect1(2)<1
            rect1(2) = 1;
        end
        if rect1(2)+rect1(4)>vid.Height
            rect1(4) = vid.Height-rect1(2);
        end
        if rect1(1)+rect1(3)>vid.Width
            rect1(3)=vid.Width-rect1(1);
        end
        
        % calculating STEOG
        if i>1 
            definition_of_spot(s) = definition_of_spot(s)+ST_Energy(slide,videoFrames(...
                rect_old(s,2):rect_old(s,2)+rect_old(s,4), rect_old(s,1):rect_old(s,1)+rect_old(s,3),1,i-1),image_blur(rect1(2):rect1(2)+rect1(4), rect1(1):rect1(1)+rect1(3)));
            if add_Wavelet
                voxels{s} = cat(3,voxels{s},image_blur(rect1(2):rect1(2)+rect1(4), rect1(1):rect1(1)+rect1(3)));
            end
        end
        rect_old(s,:) = rect1;
        
        if show_track
            bboxPoints   = bbox2points(bboxes(s,:));
            bboxPolygon = reshape(bboxPoints', 1, []);
            imDisp = insertShape(imDisp, 'FilledPolygon', bboxPolygon,'Opacity',0.4);
        end
        %disp(['-------Spots：' num2str(s) '/' num2str(size(bboxes,1)) '-------Frames：' num2str(i) '/' num2str(slide) ]);
    end
    
    if show_track
        figure(177);
        imshow(imDisp,'border','tight','initialmagnification','fit');
        
    end
    %disp(num2str(bboxes(s,:)))
    %disp([num2str(mean(flow.Vx,'all')) '++++' num2str(mean(flow.Vy,'all'))])
    %disp(['-------Frames：' num2str(i) '/' num2str(slide) ]);
end

% calculating STWTV
if add_Wavelet 
    spec_var =  zeros(1,size(bboxes,1));
    for s = 1:length(voxels)
        voxels_wave = [];
        spec_var_frame = zeros(1,size(voxels{s},3));
        spec_var(s) = Wavelet(voxels{s}(:,:,1));

        for t = 1:2:slide-1
            voxels_wave = cat(3,voxels_wave,voxels{s}(:,:,t)-voxels{s}(:,:,t+1)); % simplified Haar wavelet transform, which preserves the high frequency information in time domain.
        end
        voxels_wave = double(voxels_wave)./sqrt(2);
        spec_var(s) = spec_var(s)/var(voxels_wave,[],'all');
    end
    
    
    definition_of_spot = [definition_of_spot;spec_var];
end

end

