%% 2009 Sergio Sánchez Méndez <ceo@starcostudios.com>
%%
%% Algoritmo de adaptative background substraction
%% con heurística orientada a la detección de personas.
%% NCC - Correlación cruzada normaliza (Normalized Cross-Correlation)
%%
%% Ejemplo de llamada a la función:
%% NCC('C:/Users/Desktop/VC_tracking/tests/imgs2', 0.75, 0.3)


function NCC(folder, alpha, ini_thres)

% Set number of frames (images) based on folder entered
%frames = length(dir(fullfile(folder, 'Walk*jpg')))
frames = length(dir(fullfile(folder, 'OneStopEnter2cor*jpg')))


% Direct read from video. (Disabled)
% Test sets already taken with images
% source = aviread('C:\Video\Source\video');
% % read in 1st frame as background frame
% bg = source(1).cdata;         
% bg_bw = int8(rgb2gray(bg));
% fr_size = size(bg);
% width = fr_size(2);
% height = fr_size(1);


% Set alpha
if ~exist('alpha', 'var')
	alpha = .25;
end


% Set ini_thres
if ~exist('ini_thres', 'var')
	ini_thres = .5;
end


   % Interface  
   % guiABS; % External
   % Create and hide the GUI as it is being constructed.
   f = figure('Visible','off','Position',[390,300,750,385]);
   
   % Construct components.
   % When components are declared a callback function is included
   % it will be executed when an event takes place. I will be an static
   % structure 
   sa = uicontrol(f,'Style','slider',...
               'Max',100,'Min',0,'Value',50,...
               'SliderStep',[0.05 0.2],...
               'Position',[55 25 20 300],...
               'Callback',@sliderA_callback);
           

   
   sh = uicontrol(f,'Style','slider',...
               'Max',100,'Min',0,'Value',15,...
               'SliderStep',[0.05 0.2],...
               'Position',[700 25 20 300],...
               'Callback',@sliderU_callback);


           
 
    % Labels        
    htextA    = uicontrol('Style','text','String','Adaptative Background Substraction',...
           'Position',[290, 340, 200,15]);
 
    
    htextA    = uicontrol('Style','text','String','Alfa',...
           'Position',[35, 340, 60,15]);
    htextNumA = uicontrol('Style','text','String','Alfa',...
           'Position',[95, 50,60,15]);          
       
    htextU    = uicontrol('Style','text','String','Umbral',...
           'Position',[680, 340, 60,15]);
    htextNumU = uicontrol('Style','text','String','Umbral',...
           'Position',[620, 50,60,15]);

             
       
   set(f,'Visible','on');
   
   % Initial values
   slider.val = 15; 
   set(sh,'Value',ini_thres*100);
   set(sa,'Value',alpha*100); 
   guidata(f,slider); 
   thresHld = get(sh,'Value');
   alpha = get(sa,'Value');

      
   set(htextNumA,'String',alpha);
   set(htextNumU,'String',thresHld);
   % End Inteface code  
   
   
% function slider1_Callback(hObject, eventdata, handles)
% slider_value = get(hObject,'Value');
% % Proceed with callback... - Not required


% Object tracking colors
color_list = [];
color_list = [color_list {[1 0 0]}]; % Red
color_list = [color_list {[0 1 0]}]; % Green
color_list = [color_list {[0 0 1]}]; % Blue
color_list = [color_list {[0 1 1]}]; % Cyan
color_list = [color_list {[1 0 1]}]; % Fuchsia (sp?)
color_list = [color_list {[1 1 1]}]; % White
color_list = [color_list {[1 .5 0]}]; % Orange
color_list = [color_list {[.914 .5882 .4784]}]; % Dark Salmon
color_list = [color_list {[0 1 .5]}]; % Spring green
color_list = [color_list {[.42 .557 .137]}]; % Olive drab
image_list = [{} {} {} {} {}];

% Initialize variables and structs 
tic; 
boxes = [];
SE = strel('disk', 3);
outm = [];
impad = 5; % Padding around ncc box
ncc_thresh = 0.8; % Threshold for good ncc match
timeave = 0;


% Adaptive Background Subtraction
% Hardcoded
frames = 540;

for i=1:frames
    
    % Figure out time left
    timeave = (toc+6*timeave)/7;
    timeleft = timeave * (frames - i);
    minutes = floor(timeleft/60);
    seconds = floor(mod(timeleft,60));
    tic;
	disp(['Working on frame ' num2str(i) ' (' num2str(minutes) ':' num2str(seconds) ' left)']);
	[I, cI] = getimage(folder, i);

	% Initialize B
	if ~exist('B', 'var')
		B = I;
	end

	% Get difference data
	diff = abs(B - I) * 255;
    
    thresHld = get(sh,'Value'); 
    set(htextNumU,'String',thresHld);
    
    % In range from 0 - 100 direct value form slider
	M = threshold(diff, thresHld);
	
    
    alpha = get(sa,'Value');      
    set(htextNumA,'String',alpha); 
    alpha = alpha/100;
    
	% Prepare next B. Range between 1 - 0. Direcr range is between 0 and 100
	B = alpha*I + (1-alpha)*B;
	
	% Initalize current frame box data
	curbox = [];
	ncc_pass = 0;
	ncc_fail = 0;
	
    % Preprocess data section
	% Dilate the difference image
	dim = imdilate(M, SE);
    dim = imclose(dim, SE);
	% End preprocess data section
    
    
	% Find each object
	for j = 1:size(dim, 1)
		for k = 1:size(dim, 2)
			if dim(j,k) == 1
				doit = 0;
				
				% Trace out the object. Returns boundary in the image 'dim'
                % starting at point (j,k)with the initial direction 'E'est.  
				T = bwtraceboundary(dim, [j,k], 'E');
				
				% Filter small objects
				if length(T) > 120
					doit = 1;
                end
				
                
				% Convert trace into a blob. 
                % Gets selected matrix T. Contour values to 1
				T = full(spconvert([T ones(length(T), 1)]));
				[x1 y1 x2 y2] = find_bounds(T);
				T(y1:y2,x1:x2) = ones(y2-y1+1,x2-x1+1); %Fullfill contour with ones 
				
                
				% Find original parts and draw a box
				if doit
					C = and(T, M(1:size(T,1),1:size(T,2)) );    % Original matrix corresponding to the
                                                                % blob boundary
					[x1, y1, x2, y2] = find_bounds(C);

                    % Current image cut
                    imbox = I(y1:y2,x1:x2);

                    % Find best matching image to known blobs
                    matched = 0;
                    curcolor = [1 1 1]; % White fallback
                    for k = 1:length(image_list)

                        if ~isempty(image_list{k})
                            
                            % make sure template is small enough
                            if (size(image_list{k},1) <= size(imbox,1)) ...
									&& (size(image_list{k},2) <= size(imbox,2)) ...
									&& ~matched
                                score = max(max(normxcorr2(image_list{k}, imbox)));
                                
                                % If match is good enough, replace known
                                % image with current image
                                if score > ncc_thresh
                                    matched = 1;
                                    image_list{k} = imbox(impad:end-impad,impad:end-impad);
                                    curcolor = color_list{k};
									ncc_pass = ncc_pass + 1;
								else
									ncc_fail = ncc_fail + 1;								
                                end
                            end
                        end
                    end
                    
                    % If nothing matched well and there is still room, make
                    % a new blob.
                    if (length(image_list) < length(color_list)) && ~matched
                        image_list = [image_list {imbox(impad:end-impad,impad:end-impad)}];
                        curcolor = color_list{length(image_list)};
                    end
                    
                    % Store box information
                    curbox  = [curbox; x1 y1 x2 y2 curcolor];
                end
                
				% Remove the current blob
				T = ~T;
				T = [T  ones(size(T,1), size(dim,2) - size(T,2))];
				T = [T; ones(size(dim,1) - size(T,1), size(T,2))];
				dim = and(dim, T);
                
			end
		end
	end
	
	% Handle all the box data for this frame
	disp(['   Boxes: ' num2str(size(curbox,1))]);
	boxes = [boxes {curbox}];

	% Add frame to movie
    % Requires the 3 layers
	hold off;
    Z(:,:,1) = M*255;       % Create 3-layer difference image
    Z(:,:,2) = M*255;
    Z(:,:,3) = M*255;    
	imshow([cI Z]);
	hold on;

    
	% Box each object. Curv (x1, x2, y1, y2, R, G, B)
	for j = 1:size(curbox,1)
		curv = curbox(j, :);
		x1 = curv(1);
		y1 = curv(2);
		x2 = curv(3);
		y2 = curv(4);
        color = curv(5:7);
        % Plot the four intervals (bounding-box)
		plot([x1,x2],[y1,y1],'Color',color);
		plot([x1,x1],[y1,y2],'Color',color);
		plot([x2,x2],[y1,y2],'Color',color);
		plot([x1,x2],[y2,y2],'Color',color);
	end

	% Save frame for movie
	outm = [outm getframe];
    drawnow; %pause(.001);
	
	% Display NCC results
	disp(['   NCC fails  : ' num2str(ncc_fail)]);
	disp(['   NCC passes : ' num2str(ncc_pass)]);
    
    
    
end



% Output the final movie
warning off;
filename = './vcNCC-TestN.avi';
disp(['Saving movie file "' filename '".']);
movie2avi(outm, filename, 'fps', 30);




% Finds the bounds of a binary image (a box around the 1's)
function [x1, y1, x2, y2] = find_bounds(C)
x1 = 0;
x2 = 0;
y1 = 0;
y2 = 0;

for i = 1:size(C,1)    % Search 4 limits 'till finds first different from zero
    if sum(C(i, :)) > 0
        y1 = i;
        break;
    end
end
for i = size(C,1):-1:1
    if sum(C(i, :)) > 0
        y2 = i;
        break;
    end
end
for i = 1:size(C,2)
    if sum(C(:, i)) > 0
        x1 = i;
        break;
    end
end
for i = size(C,2):-1:1
    if sum(C(:, i)) > 0
        x2 = i;
        break;
    end
end

% Turns data into binary data at given threshhold
% diff contains the image difference (scalar matrix)
function diff = threshold(diff, thresh)
for i = 1:size(diff, 1)
    for j = 1:size(diff, 2)        
        if diff(i,j) < thresh
            diff(i,j) = 0;            
        else
            diff(i,j) = 1;
        end
    end
end



 function sliderU_callback(hObject,eventdata)
     slider.val = get(hObject,'Value');
     thresHld = slider.val;
     disp(['Threshold value:']);
     disp([slider.val]);
%    thresHld = get(hObject,'Value');
%    set(htextNumU,'String',thresHld);  
%    set(eth,'String',num2str(slider.val));
 
        
        
 function sliderA_callback(hObject,eventdata)
     slider.val = get(hObject,'Value');
     alfa = slider.val;
     disp(['Threshold value:']);
     disp([slider.val]);
     %set(eth,'String',num2str(slider.val));
%    alpha = get(hObject,'Value');
%    set(htextNumA,'String',alpha);


% Fetches image index from the given folder
function [I, cI] = getimage(folder, i)
i = i+550;
filename = [folder '/OneStopEnter2cor' repmat('0',1,4-length(num2str(i))) num2str(i) '.jpg'];
cI = imread(filename);
I = mean(cI, 3);       % Calculated as contributions of R-G-B equally 
I = double(I)/255;



