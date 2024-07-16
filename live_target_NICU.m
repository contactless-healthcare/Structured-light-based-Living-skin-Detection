function [hot_map,p_out,box_out] = live_target_NICU(p_area, cen, box, L)

% This function performs a region growing algorithm based on a living-skin spot 
% in the current sub-region to find all living-skin spots on the same connected skin region.
%
% input:  p_area -- The center coordinates of the living-skin spot in the current sub-region
%         cen    -- The center coordinates of the living skin spots in all regions of the image
%         box    -- The boxxes coordinates of the living skin spot in the current sub-region
%         L      -- The marker matrix of the image, which gives each spot a serial number
%
% output: hot_map   -- The binary image contains all the skin spots found on the connected skin area
%         p_out     -- The center coordinates of the above spots
%         box_out   -- The boxxes coordinates of the above spots


seed = p_area(:, 1);                         % The first living spot in the current sub-region is used as the initial seed.
[h,w] = size(L);
hot_map = zeros(h,w);

search_scope = 100;                          % the radius of the search range (need to be adjusted according to the density of the spot in the figure)
p_out = [];                                  % initialization of living spot set
box_out = [];
while 1
    
    seed1 = [];
    seed1_box = [];
    for i = 1:size(seed,2)                               % search the living spot around each seed
        index = logical(ismember(cen(1,:), seed(1,i) - search_scope : seed(1,i) + search_scope ).*ismember(cen(2,:), seed(2,i) - search_scope : seed(2,i) + search_scope ));
        % the index of the center coordinates of the living spot found
        p_chosen = cen(:, index);
        box_chosen = box(index,:); 
        
        % Exclude the spot found in the previous cycle
        for j = 1:size(p_chosen,2)                      
            for k = 1:size(p_out,2)
                if p_chosen(:,j) == p_out(:,k)
                    p_chosen(1,j)=0;
                    break
                end
            end
        end
        
        % Exclude the spot already found in this cycle
        for j = 1:size(p_chosen,2)                                
            for k = 1:size(seed1,2)
                if p_chosen(:,j) == seed1(:,k)
                    p_chosen(1,j)=0;
                    break
                end
            end
        end
        seed1_box = [seed1_box;box_chosen(p_chosen(1,:)>0,:)];
        seed1 = [seed1,p_chosen(:,p_chosen(1,:)>0)];
    end
    
    seed = seed1;                       % Update the seed set
    seed_box = seed1_box;
    
    if isempty(seed)
        break                           % If no new living spot is found, the cycle is terminated.
    else
        p_out = [p_out, seed];          % Update the living spot set
        box_out = [box_out;seed_box];
    end
end

% Only when more than 10 spots are found, the area is considered to be an effective living-skin area.
if size(p_out,2) >10  
    for i = 1:size(box_out,1)
            hot_map(box_out(i,2):box_out(i,2)+box_out(i,4),box_out(i,1):box_out(i,1)+box_out(i,3)) = ...
               logical(L(box_out(i,2):box_out(i,2)+box_out(i,4),box_out(i,1):box_out(i,1)+box_out(i,3)));     % 给光斑上色
    end
    %figure;imshow(hot_map);
else
    hot_map = [];
end
end