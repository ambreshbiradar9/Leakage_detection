clear all
clc
input('Stabilize the level of float in the tube and then press any key to continue');
fileID=fopen('C:\Users\Srinivas\Desktop\Experiments\SerialPortSotware\leakbatch2.txt','a');
I=imread('C:\Users\Srinivas\Desktop\Experiments\SerialPortSotware\OutputDisplay2.jpg');
videoplayer=vision.VideoPlayer('Name','Pressure and Leak');
position1=[210 130];
position2=[580 130];
box_color={'white'};

%% Initialization

vidDevice = imaq.VideoDevice('winvideo', 1, 'MJPG_1024x768', ...% Acquire input video stream
    'ROI', [265 210 610 260], ...
    'ReturnedColorSpace', 'rgb');
vidInfo = imaqhwinfo(vidDevice); % Acquire input video property

hblob = vision.BlobAnalysis('AreaOutputPort', false, ... % Set blob analysis handling
    'CentroidOutputPort', true, ...
    'BoundingBoxOutputPort', true', ...
    'MinimumBlobArea', 1200, ...
    'MaximumBlobArea', 55000, ...
    'MaximumCount', 2);

hVideoIn = vision.VideoPlayer('Name', 'Final Video', ... % Output video player
    'Position', [100 100 vidInfo.MaxWidth+20 vidInfo.MaxHeight+30]);
nFrame = 0; % Frame number initialization

%% Processing Loop
while(nFrame < 200)
    rgbFrame = step(vidDevice); % Acquire single frame
    %%
    diffFrameBlue = imsubtract(rgbFrame(:,:,3), rgb2gray(rgbFrame)); % Get blue component of the image
    diffFrameBlue = medfilt2(diffFrameBlue, [3 3]); % Filter out the noise by using median filter
    %binFrameBlue = im2bw(diffFrameBlue, blueThresh); % Convert the image into binary image with the blue objects as white
    binFrameBlue = imbinarize(diffFrameBlue);
   [centroidBlue, bboxBlue] = step(hblob, binFrameBlue); % Get the centroids and bounding boxes of the blue blobs
    centroid1 = uint16(centroidBlue); % Convert the centroids into Integer for further steps 
    %%
    if length(centroid1)==2
        text=append(num2str(centroid1(1,1)),' ',num2str(centroid1(1,2)));
        rgbFrame=insertText(rgbFrame,[centroid1(1,1)-6 centroid1(1,2)-9],text);
        if (height(centroid1)==2)&&(width(centroid1)==2)
            text_1=append(num2str(centroid1(2,1)),' ',num2str(centroid1(2,2)));
            rgbFrame=insertText(rgbFrame,[centroid1(2,1)-6 centroid1(2,2)-9],text_1);
        end
    end
    step(hVideoIn, rgbFrame); % Output video stream
    nFrame = nFrame+1;
end

%% Insert
lev1=70;
lev2=230;

%% Calibrate the leak value
konst=(lev2-lev1)/sqrt(((centroidBlue(1,1)-centroidBlue(2,1))^2)+((centroidBlue(1,2)-centroidBlue(2,2))^2));


%% blob for red
hblob1 = vision.BlobAnalysis('AreaOutputPort', false, ... % Set blob analysis handling
    'CentroidOutputPort', true, ...
    'BoundingBoxOutputPort', true', ...
    'MinimumBlobArea', 2000, ...
    'MaximumBlobArea', 55000, ...
    'MaximumCount', 1);


%% Check
num=0;
Pressure=xlsread('C:\Users\Srinivas\Desktop\Experiments\SerialPortSotware\Control.xls','Sheet1','D5');
Leak=0;
while(num~=1)
    rgbFrame = step(vidDevice); % Acquire single frame
    %rgbFrame = flipdim(rgbFrame,2); % obtain the mirror image for displaying
    diffFrame = imsubtract(rgbFrame(:,:,1), rgb2gray(rgbFrame)); % Get red component of the image
    diffFrame = medfilt2(diffFrame, [3 3]); % Filter out the noise by using median filter
    binFrame = imbinarize(diffFrame); % Convert the image into binary image with the red objects as white
    [centroid, bbox] = step(hblob1, binFrame); % Get the centroids and bounding boxes of the blobs
    centroid3f=centroid;
    centroid3 = uint16(centroid); % Convert the centroids into Integer for further steps
    if length(centroid3)==2
        leakread=lev1+konst*sqrt(((centroid3f(1)-centroidBlue(1,1))^2)+((centroid3f(2)-centroidBlue(1,2))^2));
        rgbFrame = insertText(rgbFrame,centroid3,leakread);
    end
    %vidIn = step(htextins, vidIn, uint8(length(bbox(:,1)))); % Count the number of blobs
    step(hVideoIn, rgbFrame); % Output video stream

    nFrame = nFrame+1;
    if rem(nFrame,100)==0
        D=xlsread('C:\Users\Srinivas\Desktop\Experiments\SerialPortSotware\Control.xls','Sheet1','D5:F5');
        Pressure=D(1);
        num=D(2);
        Leak=D(3);
    end
    
    %% Display Data
    RaGaBa=insertText(I,position1,Pressure,'FontSize',45,'TextColor','black','BoxColor', box_color);
    RaGaBa=insertText(RaGaBa,position2,leakread,'FontSize',45,'TextColor','black','BoxColor', box_color);
    %step(videoplayer,RaGaBa)
    
    %% Save Data
    fprintf(fileID,'%f\t%f\t%f\t%f\n',[now-693960 Pressure leakread Leak]);
        
end

%Clearing Memory
release(hVideoIn); % Release all memory and buffer used
release(vidDevice);
clc;
