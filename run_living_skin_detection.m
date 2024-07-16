%%%
% Please cite below paper if the code was used in your research or development.
% Z. Wang et al., "Living-Skin Detection based on Spatio-Temporal
% Analysis of Structured Light Pattern", IEEE Journal of Biomedical and
% Health Informatics, 2024. (under revision)
%%%

clear;close all;

%% parameter setup
Nframes         = 15;               % time length of the spot iamge sequence
iter            = 6;                % clustering times 
add_Wavelet     = 1;                % calculate STWTV or not (1-yes)
padding_size    = 0;                % Control the number of pixels that bboxes expand outward, to ensure that bboxes can contain all areas of the spot
spot_area_limit = 45;               % Lower limit of spot area
spot_area_uplimit = 2000;           % Upper limit of spot area

show_track      = 0;                % whether to display the spot tracking process
show_detection  = 1;                % whether to display the living-skin detection results


%% data input
%%% lab example
path_video = "./clips/lab_face_only.avi";
% path_video = "./clips/lab_face_with_palm.avi";

%%% NICU example
% path_video = "./clips/nicu_anti_dropout_bed.avi";
% path_video = "./clips/nicu_incubator.avi";


vid = VideoReader(path_video);

start_frame = 1;
I = read(vid,start_frame);          % read the first frame of the image sequence
I = I(:,:,1);
[height, width] = size(I);  


%% laser spot localization
T = adaptthresh(I, 0.09);               % using Bradley threshold method
J = imbinarize(I, T);
J = logical(J.*imbinarize(I, 0.13));    % set the lower limit of intensity

[L,num] = bwlabel(J, 8);  % label the laser spots in the binary image J

% calculate the spot centroid coordinates
props = regionprops(J, 'Centroid','BoundingBox');
centroids = int32(cat(1, props.Centroid));
bboxes = int32(cat(1, props.BoundingBox));


% filter out the invalid spots
for i = 1 : size(centroids,1)                                      
    if bboxes(i,3)*bboxes(i,4)<spot_area_uplimit && bboxes(i,3)*bboxes(i,4)>spot_area_limit && bboxes(i,2)+bboxes(i,4)<height -padding_size && bboxes(i,1)+bboxes(i,3)<width -padding_size && bboxes(i,2)>padding_size && bboxes(i,1)>padding_size
        bboxes(i,:) = [bboxes(i,1)-padding_size,bboxes(i,2)-padding_size,bboxes(i,3)+2*padding_size,bboxes(i,4)+2*padding_size];
    else
        bboxes(i,:) = [0,0,0,0];
    end
end
centroids(bboxes(:,1)==0,:) = [];
bboxes(bboxes(:,1)==0,:) = [];


% mark the location of the spot with a box
if show_detection
    figure; imshow(I);title("original structured image", "FontWeight", "bold")
    figure;
    imshow(I); title("localization of laser spots", "FontWeight", "bold")
    hold on;
end
for i = 1 : size(bboxes,1)
    if show_detection
        plot(centroids(i,1), centroids(i,2),'r.');
        rectangle('position', bboxes(i,:),'EdgeColor', 'g');   
    end
end


%% Spatio-temporal feature calculation

definition_of_spot = ST_EW(vid, start_frame, Nframes, bboxes, add_Wavelet,show_track);

centroids= (double(centroids))';

% Mark the living skin area under structured light illumination
grad_map = [];
definition_colormap = [definition_of_spot;grad_map];
for i = 1:size(definition_colormap)
    definition_colormap(i,:) = definition_colormap(i,:)/max(definition_colormap(i,:));
end
definition_colormap1 = definition_colormap;


%% K-means clustering
cen = centroids;    % select the centroids and bboxes of the spots with the required clarity as a backup
box = bboxes;       

for step =  1:iter
    
    [cidx,ctrs] = kmeans(definition_colormap',2,'MaxIter',1500,'Replicates',3);
    
    [~,min_cluster] = min(mean(ctrs,2));    % Pick out the cluster with the smallest feature mean.
    
    definition_colormap = definition_colormap(:,(cidx == min_cluster));
    cen = cen(:,cidx == min_cluster);
    box = box(cidx == min_cluster,:);       
    
end


%% Distinguish different live-skin regions, Label each skin spot set with a unique color label
live_not_detected = 1;

% Only when more than 10 spots with a definition less than definition_lim are detected will the localization begin.
if length(definition_colormap) > 10 
    live_not_detected = 0;
    
    % detect and locate the living region in the image
    
    h = round(linspace(1,height,5));
    w = round(linspace(1,width,6));
    one_hot_map_all = [];
    p_all = [];
    box_all = [];

    % The image is evenly divided into 6 parts, and then the living spot is searched in each region.
    for i = 1:length(h)-1                                                      
        for j =1:length(w)-1
            index = logical(ismember(cen(1,:),w(j):w(j+1)).*ismember(cen(2,:),h(i):h(i+1))); % the index of the spot in this sub-region
            p_area = cen(:,index);
            box_area = box(index,:);
            if isempty(p_area)
                continue
            end
            
            % The region growing algorithm is performed to determine the living area, based on the searched living spot.
            [one_hot_map, p_out, box_out] = live_target_NICU(p_area,cen,box,L);    
            
            if isempty(one_hot_map)
                continue
            end
           
            % Incorporating the detected living skin regions into the set (duplicates will be removed)
            if isempty(one_hot_map_all)                
                one_hot_map_all = cat(3,one_hot_map_all,one_hot_map);
                p_all = [p_all,p_out];                 % update the living spot set
                box_all = [box_all;box_out];
                % if show_detection
                %     figure;imshow(one_hot_map);
                % end
            end
            
            % To determine whether the newly detected living area coincides with the previously detected target.
            ismem = 0;                                           
            for c = 1:size(one_hot_map_all,3)
                if one_hot_map_all(:,:,c)==one_hot_map
                    ismem = 1;
                    break
                end
            end
            
            
            if ~ismem                                                 % included in the set, if not coincide
                one_hot_map_all = cat(3,one_hot_map_all,one_hot_map);
                p_all = [p_all,p_out];                                % update the living spot set
                box_all = [box_all;box_out];
                % if show_detection
                %     figure;imshow(one_hot_map);
                % end                     
            end                    
        end
    end
    
    % Mark the spot in the living-skin on the structured light image
    if show_detection
        color_array = [[1,0,0];[1,0.84,0];[0.49,0.99,0];[0,1,1];[0.74,0.99,0.79];[1,0.75,0.8];[0,0,1]];            
        
        
        color_mask = zeros([size(I),3]);
        anti_mask = ones(size(I));
        c_all = size(one_hot_map_all,3);
        for c = 1:c_all
            nc = c;
            anti_mask=anti_mask.*(1-one_hot_map_all(:,:,nc));
            color_mask = color_mask + cat(3, one_hot_map_all(:,:,nc)*color_array(nc,1), one_hot_map_all(:,:,nc)*color_array(nc,2), one_hot_map_all(:,:,nc)*color_array(nc,3));
        end
        
        result = uint8(255*color_mask) + uint8(anti_mask).* cat(3,I,I,I);
        
        figure; 
        imshow(result); title("Results of living-skin detection", "Interpreter","none", "FontWeight","bold");
    end
    
    
end

if live_not_detected
    figure;imshow(I);text(0.5*width,64,"No living region was detected!",'horiz','center','color','r','FontSize',16)
end


