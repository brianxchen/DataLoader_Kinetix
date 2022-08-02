function varargout = SCAPE_QuickView_v1_kinetix(varargin)
% SCAPE_QUICKVIEW_V1_KINETIX MATLAB code for SCAPE_QuickView_v1_kinetix.fig

% SCAPE_QuickView allows you to quickly visualize SCAPE_data in 3 dimensions, create time
% courses and save summary movies and screenshots. Data can be visualized in
% dual color if the RGBtransform.mat file has already been created.


% Developed by the Hillman Lab at Columbia University (2018)

% Edit the above text to modify the response to help SCAPE_QuickView_v1_kinetix

% Last Modified by GUIDE v2.5 01-Aug-2022 16:53:21

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @SCAPE_QuickView_v1_kinetix_OpeningFcn, ...
    'gui_OutputFcn',  @SCAPE_QuickView_v1_kinetix_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% End initialization code - DO NOT EDIT %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Open and Output Functions %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SCAPE_QuickView_v1_kinetix_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
try clear_data = evalin('base', 'clear_data');
catch
    clear_data = 0;
end

try
    handles.data = evalin('base', 'SCAPE_data');
    handles.info = evalin('base', 'info');
    if clear_data == 1; evalin('base', 'clear SCAPE_data');
        disp('workspace data cleared - Click "write data to workspace" to transfer back when you close!');
    end
catch
    msgbox('Please Load Data to Workspace in advance');
end

handles.RGB = varargin{1};


% Set default slice numbers
handles.t = 1;
handles.xslice = 1;
handles.yslice = 1;
handles.zslice = 1;


if ~handles.RGB
    
    handles.ss = size(handles.data);
    
    % Set axes
    handles.y = [1:handles.ss(1)]-1;
    handles.x = [1:handles.ss(3)]-1;
    handles.z = [1:handles.ss(2)]-1;
    
    % Set default colormap
    if (length(handles.ss) == 3)
        handles.maxDataColor = double(squeeze(max(max(max(handles.data)))));
    elseif (length(handles.ss) == 4)
        handles.maxDataColor = double(squeeze(max(max(max(max(handles.data))))));
    end
    set(handles.colorMaxTextbox, 'String', num2str(handles.maxDataColor));
    set(handles.colorMinSlider, 'Value', (110/handles.maxDataColor));
    % keyboard
    set(handles.colorMaxSlider, 'Value', (1));
    
else
    
    % Data is dual color - align red and green and set scaling individually
    try RGBname = evalin('base','RGBname');
        FilePath2 = RGBname;
    catch
        fname = handles.info.scanName;
        names = dir(fullfile(handles.info.storage_dir, sprintf('RGBtransform*%s*.mat',fname)));
        for k = 1:size(names,1)
            tt(k) = names(k).datenum;
        end
     %   [o oo] = max(tt);
        if isempty(names)
            FilePath2= fullfile(handles.info.storage_dir, 'RGBtransform.mat');
        else
            FilePath2 = [names(oo).folder, '/', names(oo).name];
        end
    end
    [out] = questdlg(sprintf('Using: %s -- ok?',FilePath2),'Confirm RGB Transform','Ok','No, chose a different one','Ok');
    if strcmp(out,'Ok')==0;
     [filename, pathname] =  uigetfile([handles.info.storage_dir],'chose RGB transform file to use');
    FilePath2 = [pathname '/' filename];
    end
        
   % FilePath2 = fullfile(handles.info.storage_dir, 'RGBtransform.mat');
    if (2 == exist(FilePath2, 'file'))
        load(FilePath2)
        
        newss = size(handles.data);
        
        transforms.ss = newss;
        %update x reference points
        tempxg = transforms.ss(1)/2-transforms.xg; %distance of x point from centerline of camera width on alignment image
        transforms.xg = round(newss(1)/2-tempxg); %accounts for differences in camera FOV width
        tempxr = transforms.xr - transforms.ss(1)/2; %distance of x point from centerline of camera width on alignment image
        transforms.xr = round(newss(1)/2+tempxr); %accounts for differences in camera FOV width
        
        %update z reference points
        tempzg = transforms.ss(2)/2-transforms.zg; %distance of z point from centerline of camera height on alignment image
        transforms.zg = round(newss(2)/2-tempzg); %accounts for differences in camera FOV height
        tempzr = transforms.ss(2)/2-transforms.zr; %distance of z point from centerline of camera height on alignment image
        transforms.zr = round(newss(2)/2-tempzr); %accounts for differences in camera FOV height
            
        handles.xg2 = transforms.xg;
        handles.xr2 = transforms.xr;
        handles.yr2 = transforms.yr;
        handles.yg2 = transforms.yg;
        handles.zr2 = transforms.zr;
        handles.zg2 = transforms.zg;
        
        xg = handles.xg2;
        xr = handles.xr2;
        yr = handles.yr2;
        yg = handles.yg2;
        zr = handles.zr2;
        zg = handles.zg2;
        try
            scaleR = transforms.scaleR;   % The code is RED/GREEN shifted!!
        catch
            scaleR = 1; % If there is not scaleR
        end
        left = floor(min([xg xr]))-1;
        right = floor(size(handles.data,1)-max([xg xr]));
        
        top = floor(min([zr zg]))-1;
        bot = floor(size(handles.data,2)-max([zr zg]));
        topy = floor(min([yr yg]))-1;
        boty = floor(size(handles.data,3)-max([yr yg]));
        
        if length(size(handles.data))>3
            red = (handles.data(round(xg+[-left:right]),round(zg+[-top:bot]),:,:));
            green = (handles.data(round(xr+[-left:right]),round(zr+[-top:bot]),:,:));
        else
            red = (handles.data(round(xg+[-left:right]),round(zg+[-top:bot]),:));
            green = (handles.data(round(xr+[-left:right]),round(zr+[-top:bot]),:));
        end
        
        % scale correction for 1st gen imagesplitter
        if scaleR~=1
            red = imresize(red,scaleR*[size(red,1) size(red,2)]);
            if scaleR <1
                dif1 = size(green,1) - size(red,1);
                dif2 =  size(green,2) - size(red,2);
                x1 = floor(dif1/2) ;
                x2 = ceil(dif1/2);
                y1 = floor(dif2/2);
                y2 = ceil(dif2/2);
                red = padarray(red,[x1 y1],0,'pre');
                red = padarray(red,[x2 y2],0,'post');
            else
                dif1 = size(red,1) - size(green,1);
                dif2 =  size(red,2) - size(green,2);
                x1 = floor(dif1/2)+1; x2 = ceil(dif1/2);
                y1 = floor(dif2/2)+1; y2 = ceil(dif2/2);
                if length(size(handles.data))>3
                    red = red(x1:end-x2,y1:end-y2,:,:);
                else
                    red = red(x1:end-x2,y1:end-y2,:);
                end
            end
        end
        
        handles = rmfield(handles,'data'); %clear handles.data % beth banana
               
        handles.ss = size(red);        
                 
        % Set axes
        handles.y = [1:handles.ss(1)]-1;
        handles.x = [1:handles.ss(3)]-1;
        handles.z = [1:handles.ss(2)]-1;
        
        % Set default colormap
        % red
        if (length(handles.ss) == 3)
            handles.maxredColor = double(squeeze(max(max(max(red)))));
        elseif (length(handles.ss) == 4)
            handles.maxredColor = double(squeeze(max(max(max(max(red))))));
        end
        if (length(handles.ss) == 3)
            handles.maxredColor = double(squeeze(max(max(max(red)))));
        elseif (length(handles.ss) == 4)
            handles.maxredColor = double(squeeze(max(max(max(max(red))))));
        end
        
        set(handles.redMaxTextbox, 'String', num2str(handles.maxredColor));
        set(handles.redMinSlider, 'Value', (110/handles.maxredColor));
        set(handles.redMaxSlider, 'Value', (1))
        
        % green
        if (length(handles.ss) == 3)
            handles.maxgreenColor = double(squeeze(max(max(max(green)))));
        elseif (length(handles.ss) == 4)
            handles.maxgreenColor = double(squeeze(max(max(max(max(green))))));
        end
        if (length(handles.ss) == 3)
            handles.maxgreenColor = double(squeeze(max(max(max(green)))));
        elseif (length(handles.ss) == 4)
            handles.maxgreenColor = double(squeeze(max(max(max(max(green))))));
        end
               
        set(handles.greenMaxTextbox, 'String', num2str(handles.maxgreenColor));
        set(handles.greenMinSlider, 'Value', (110/handles.maxgreenColor));
        set(handles.greenMaxSlider, 'Value', (1));
        
        handles.red = red;
        handles.green = green;
        clear red green
       
    end
    
    
end

% Set default crop parameters
handles.cropParams.xmin = 1;%handles.x(1);
handles.cropParams.ymin = 1;%handles.y(1);
handles.cropParams.zmin = 1;%handles.z(1);
handles.cropParams.xmax = 10000;%handles.x(end);
handles.cropParams.ymax = 10000;%handles.y(end);
handles.cropParams.zmax = 10000; %handles.z(end);
set(handles.cropXmaxTextbox, 'String', num2str(handles.cropParams.xmax))
set(handles.cropYmaxTextbox, 'String', num2str(handles.cropParams.ymax))
set(handles.cropZmaxTextbox, 'String', num2str(handles.cropParams.zmax))

% Update handles structure
axis(handles.axes1);

if ~handles.RGB
    imagesc(handles.y, handles.x, squeeze(handles.data(:,1,:,1))');
    axis image
    colormap gray;
    xlabel('Y', 'Color', 'w')
    ylabel('X', 'Color', 'w')
    set(handles.axes1, 'YColor', 'w');
    set(handles.axes1, 'XColor', 'w');
    set(handles.greyscaling, 'Visible', 'On')
    set(handles.RGBscaling, 'Visible', 'Off')
else
    rgb(:,:,1) = squeeze(handles.red(:,1,:,1))';
    rgb(:,:,2) = squeeze(handles.green(:,1,:,1))';
    rgb(:,:,3) = zeros(size(rgb(:,:,1)));
    imagesc(handles.y, handles.x, rgb);
    axis image
    xlabel('Y', 'Color', 'w')
    ylabel('X', 'Color', 'w')
    set(handles.axes1, 'YColor', 'w');
    set(handles.axes1, 'XColor', 'w');
    set(handles.RGBscaling, 'Visible', 'On')
    set(handles.greyscaling, 'Visible', 'Off')
end

if(length(handles.ss) == 3)
    sliderStep = 1;
    set(handles.timeStamp, 'Visible', 'Off');
    set(handles.timeslider, 'Enable', 'Off');
    set(handles.timenum, 'Enable', 'Off');
    set(handles.playPushbutton, 'Enable', 'Off');
    set(handles.playbackSpeedSlider, 'Enable', 'Off');
    set(handles.timecoursePushbutton, 'Enable', 'Off');
    set(handles.clearTimecoursesPushbutton, 'Enable', 'Off');
    set(handles.exportTimecoursesPushbutton, 'Enable', 'Off');
else
    sliderStep = 1/(handles.ss(4)-1);
    set(handles.timeStamp, 'Visible', 'On');
    set(handles.timeslider, 'Enable', 'On');
    set(handles.timenum, 'Enable', 'On');
    set(handles.playPushbutton, 'Enable', 'On');
    set(handles.playbackSpeedSlider, 'Enable', 'On');
    set(handles.timecoursePushbutton, 'Enable', 'On');
    set(handles.clearTimecoursesPushbutton, 'Enable', 'On');
    set(handles.exportTimecoursesPushbutton, 'Enable', 'On');
end
set(handles.timeslider, 'SliderStep', [sliderStep, sliderStep*5])
sliceSliderStep = 1/(handles.ss(2)-1);
set(handles.sliceslider, 'SliderStep', [sliceSliderStep, sliceSliderStep*5])
handles.playbackSpeed = handles.info.daq.scanRate;
handles.numTC = 1;
handles.info.listbox{end+1} = ['Scan Name: ',handles.info.scanName];
if isfield(handles.info,'listbox'); set(handles.infobox,'String',handles.info.listbox); end

sliceslider_Callback(hObject, eventdata, handles)

guidata(hObject, handles);

function varargout = SCAPE_QuickView_v1_kinetix_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Callback Functions %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
function sliceslider_Callback(hObject, eventdata, handles)
sl = get(handles.sliceslider,'Value');

if (sl==0)
    sl = 0.00000001; % Prevents the slice number from being set to zero.
end

if ~handles.RGB
    colorMaxVal = get(handles.colorMaxSlider, 'Value')*handles.maxDataColor;
    colorMinVal = get(handles.colorMinSlider, 'Value')*handles.maxDataColor;
    tmp = uint16([colorMinVal colorMaxVal]);
    
    logscale = get(handles.logScaleCheckbox, 'Value');
    if(logscale)
        clims = log10(double([min(tmp) max(tmp)]));
    else
        clims = [min(tmp) max(tmp)];
    end
    
else
    greenMaxVal = get(handles.greenMaxSlider, 'Value')*handles.maxgreenColor;
    greenMinVal = get(handles.greenMinSlider, 'Value')*handles.maxgreenColor;
    tmpg = uint16([greenMinVal greenMaxVal]);
    
    logscaleg = get(handles.greenlogscale, 'Value');
    if(logscaleg)
        climg = log10(double([min(tmpg) max(tmpg)]));
    else
        climg = [min(tmpg) max(tmpg)];
    end
    
    redMaxVal = get(handles.redMaxSlider, 'Value')*handles.maxredColor;
    redMinVal = get(handles.redMinSlider, 'Value')*handles.maxredColor;
    tmpr = uint16([redMinVal redMaxVal]);
    
    logscaler = get(handles.redlogscale, 'Value');
    if(logscaler)
        climr = log10(double([min(tmpr) max(tmpr)]));
    else
        climr = [min(tmpr) max(tmpr)];
    end
    
    scr = 1/double(climr(2));
    scg = 1/double(climg(2));
    minr = double(climr(1));
    ming = double(climg(1));
    scr =1/(1/scr-minr);
    scg =1/(1/scg-minr);
    
end

mipview = get(handles.mipViewCheckbox, 'Value');
xwin = round(str2num(get(handles.xSliceThicknessTextbox, 'String'))/2);
ywin = round(str2num(get(handles.ySliceThicknessTextbox, 'String'))/2);
zwin = round(str2num(get(handles.zSliceThicknessTextbox, 'String'))/2);

if get(handles.xyzview,'Value')==1
    if(mipview)
        win = [-zwin zwin];
    else
        win = [0 0];
    end
    sll = ceil(handles.ss(2)*sl);
    handles.zslice = sll+win;
    handles.zslice(1) = max(handles.zslice(1), 1);
    handles.zslice(2) = min(handles.zslice(2), handles.ss(2));
    handles.zslice = [handles.zslice(1):handles.zslice(2)];
    
    axis(handles.axes1);
    
    if ~handles.RGB
        if(~logscale)
            imagesc(handles.y, handles.x, squeeze(max(handles.data(:,handles.zslice,:,handles.t), [], 2))');
        else
            imagesc(handles.y, handles.x, log10(double(squeeze(max(handles.data(:,handles.zslice,:,handles.t), [], 2))')));
        end
    else
        if(~logscaleg)
           green = squeeze(max(handles.green(:,handles.zslice,:,handles.t), [], 2))'; 
        else
           green = log10(double(squeeze(max(handles.green(:,handles.zslice,:,handles.t), [], 2))'));
        end
        if(~logscaler)
           red = squeeze(max(handles.red(:,handles.zslice,:,handles.t), [], 2))'; 
        else
           red = log10(double(squeeze(max(handles.red(:,handles.zslice,:,handles.t), [], 2))'));
        end
        rgb(:,:,1) = scr.*double(red-minr);
        rgb(:,:,2) = scg.*double(green-ming);
        rgb(:,:,3) = zeros(size(red));
        image(handles.y, handles.x, rgb);
     end
    
    axis image
    xlim([max(handles.cropParams.ymin, 0) min(handles.y(end), handles.cropParams.ymax)])
    ylim([max(handles.cropParams.xmin, 0) min(handles.x(end), handles.cropParams.xmax)])
    xlabel('Y (um)', 'Color', 'w')
    ylabel('X (um)', 'Color', 'w')
    
elseif get(handles.xyzview,'Value')==2
    if(mipview)
        win = [-xwin xwin];
    else
        win = [0 0];
    end
    sll = ceil(handles.ss(3)*sl);
    handles.xslice = sll+win;
    handles.xslice(1) = max(handles.xslice(1), 1);
    handles.xslice(2) = min(handles.xslice(2), handles.ss(3));
    handles.xslice = [handles.xslice(1):handles.xslice(2)];
    
    axis(handles.axes1);
    
    if ~handles.RGB
        if(~logscale)
            imagesc(handles.y, handles.z, squeeze(max(handles.data(:,:,handles.xslice,handles.t), [], 3))');
        else
            imagesc(handles.y, handles.z, log10(double(squeeze(max(handles.data(:,:,handles.xslice,handles.t), [], 3))')));
        end
    else
        if(~logscaleg)
            green = squeeze(max(handles.green(:,:,handles.xslice,handles.t), [], 3))';
        else
            green = log10(double(squeeze(max(handles.green(:,:,handles.xslice,handles.t), [], 3))'));
        end
        if(~logscaler)
            red = squeeze(max(handles.red(:,:,handles.xslice,handles.t), [], 3))';
        else
            red = log10(double(squeeze(max(handles.green(:,:,handles.xslice,handles.t), [], 3))'));
        end
        rgb(:,:,1) = scr.*double(red-minr);
        rgb(:,:,2) = scg.*double(green-ming);
        rgb(:,:,3) = zeros(size(red));
        image(handles.y, handles.z, rgb);
    end
         
    ylabel('Z (um)', 'Color', 'w')
    xlabel('Y (um)', 'Color', 'w')
    axis image
    xlim([max(handles.cropParams.ymin, 0) min(handles.y(end), handles.cropParams.ymax)])
    ylim([max(handles.cropParams.zmin, 0) min(handles.z(end), handles.cropParams.zmax)])
    
elseif get(handles.xyzview,'Value')==3
    if(mipview)
        win = [-ywin ywin];
    else
        win = [0 0];
    end
    sll = ceil(handles.ss(1)*sl);
    handles.yslice = sll+win;
    handles.yslice(1) = max(handles.yslice(1), 1);
    handles.yslice(2) = min(handles.yslice(2), handles.ss(1));
    handles.yslice = [handles.yslice(1):handles.yslice(2)];
    
    axis(handles.axes1);
    
    if ~handles.RGB
    if(~logscale)
        imagesc(handles.x, handles.z, squeeze(max(handles.data(handles.yslice,:,:,handles.t), [], 1)));
    else
        imagesc(handles.x, handles.z, log10(double(squeeze(max(handles.data(handles.yslice,:,:,handles.t), [], 1)))));
    end
    else
        if(~logscaleg)
            green = squeeze(max(handles.green(handles.yslice,:,:,handles.t), [], 1));
        else
            green = log10(double(squeeze(max(handles.green(handles.yslice,:,:,handles.t), [], 1))));
        end
        if(~logscaler)
            red = squeeze(max(handles.red(handles.yslice,:,:,handles.t), [], 1));
        else
            red = log10(double(squeeze(max(handles.green(handles.yslice,:,:,handles.t), [], 1))));
        end
        rgb(:,:,1) = scr.*double(red-minr);
        rgb(:,:,2) = scg.*double(green-ming);
        rgb(:,:,3) = zeros(size(red));
        image(handles.x, handles.z, rgb);
    end
    
    ylabel('Z (um)', 'Color', 'w')
    xlabel('X (um)', 'Color', 'w')
    axis image
    xlim([max(handles.cropParams.xmin, 0) min(handles.cropParams.xmax, handles.x(end))])
    ylim([max(handles.cropParams.zmin, 0) min(handles.z(end), handles.cropParams.zmax)])
end
set(handles.timeStamp, 'String', ['Time: ' num2str(round(handles.t/handles.info.daq.scanRate*100)/100) ' sec']);

if ~handles.RGB
caxis(clims);
colormap gray;
end

set(handles.axes1, 'YColor', 'w');
set(handles.axes1, 'XColor', 'w');
set(handles.slicenum,'String',sll);

guidata(hObject, handles);

function slicenum_Callback(hObject, eventdata, handles)
mipval = get(handles.xyzview,'Value');
sliceval = str2num(get(handles.slicenum, 'String'));

switch mipval
    case 1
        maxsliceval = handles.ss(2);
    case 2
        maxsliceval = handles.ss(3);
    case 3
        maxsliceval = handles.ss(1);
end
if(sliceval> maxsliceval)
    sliceval = maxsliceval;
    set(handles.slicenum, 'String', num2str(sliceval));
end
if (sliceval < 1)
    sliceval = 1;
    set(handles.slicenum, 'String', num2str(sliceval));
end
set(handles.sliceslider,'Value', sliceval/maxsliceval);

sliceslider_Callback(hObject, eventdata, handles)

function xyzview_Callback(hObject, eventdata, handles)
val = get(handles.xyzview, 'Value');

switch val
    case 1
        sliceSliderStep = 1/(handles.ss(2)-1);
        set(handles.sliceslider, 'SliderStep', [sliceSliderStep, sliceSliderStep*5])
        set(handles.xSliceThicknessTextbox, 'Enable','Off');
        set(handles.ySliceThicknessTextbox, 'Enable','Off');
        set(handles.zSliceThicknessTextbox, 'Enable','On');
    case 2
        sliceSliderStep = 1/(handles.ss(3)-1);
        set(handles.sliceslider, 'SliderStep', [sliceSliderStep, sliceSliderStep*5])
        set(handles.xSliceThicknessTextbox, 'Enable','On');
        set(handles.ySliceThicknessTextbox, 'Enable','Off');
        set(handles.zSliceThicknessTextbox, 'Enable','Off');
    case 3
        sliceSliderStep = 1/(handles.ss(1)-1);
        set(handles.sliceslider, 'SliderStep', [sliceSliderStep, sliceSliderStep*5])
        set(handles.xSliceThicknessTextbox, 'Enable','Off');
        set(handles.ySliceThicknessTextbox, 'Enable','On');
        set(handles.zSliceThicknessTextbox, 'Enable','Off');
end


sliceslider_Callback(hObject, eventdata, handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% TIME PLAYBACK CALLBACKS %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function timeslider_Callback(hObject, eventdata, handles)
if (length(handles.ss) == 3)
    handles.t = 1;
else
    handles.t = ceil(handles.ss(4)*get(handles.timeslider,'Value'));
    if(handles.t == 0)
        handles.t = 1;
    end
end
set(handles.timenum,'String',num2str(handles.t));
sliceslider_Callback(hObject, eventdata, handles)

function timenum_Callback(hObject, eventdata, handles)
val = str2num(get(handles.timenum, 'String'));
if (val <=0)
    val = 1
elseif (val >= handles.ss(4))
    val = handles.ss(4);
end
handles.t = val;
set(handles.timeslider, 'Value', val/handles.ss(4));
timeslider_Callback(hObject, eventdata, handles)

function playPushbutton_Callback(hObject, eventdata, handles)
val = get(handles.playPushbutton, 'Value');
set(handles.timeslider, 'Enable', 'Off');
set(handles.playbackSpeedSlider, 'Enable', 'Off');

while(val == 1)
    val = get(handles.playPushbutton, 'Value');
    handles.t = handles.t+1;
    if(handles.t>handles.ss(4))
        handles.t = 1;
    end
    set(handles.timenum,'String',num2str(handles.t));
    sliceslider_Callback(hObject, eventdata, handles);
    pause(1/handles.playbackSpeed)
end
set(handles.timeslider, 'Enable', 'On');
set(handles.playbackSpeedSlider, 'Enable', 'On');
timenum_Callback(hObject, eventdata, handles)

function playbackSpeedSlider_Callback(hObject, eventdata, handles)
val = get(handles.playbackSpeedSlider, 'Value');
val = val-0.5;
if (val <0)
    val = round(abs(val*100)/5);
    handles.playbackSpeed = (handles.info.daq.scanRate)*power(0.8, val);
else
    val = round(abs(val*100)/5);
    handles.playbackSpeed = (handles.info.daq.scanRate)*power(1.2, val);
end

guidata(hObject, handles);

function timecoursePushbutton_Callback(hObject, eventdata, handles)
mipval = get(handles.xyzview, 'Value');
calval = (get(handles.uniformAspectRadiobutton, 'Value')*1)+...
    (get(handles.calibratedAspectRadiobutton, 'Value')*2)+...
    (get(handles.customAspectRadiobutton, 'Value')*3);
slicenum = str2num(get(handles.slicenum, 'String'));
cmap = lines(50);
hold on;

switch mipval
    case 1
        [y,x] = ginput_col(2);
        x = round(x);
        y = round(y);
        z = slicenum;
        plot(handles.axes1, mean(y), mean(x), 'o', 'color', cmap(handles.numTC, :));
    case 2
        [y,z] = ginput_col(2);
        y = round(y);
        z = round(z);
        x = slicenum;
        plot(handles.axes1, mean(y), mean(z), 'o', 'color', cmap(handles.numTC, :));
    case 3
        [x,z] = ginput_col(2);
        x = round(x);
        z = round(z);
        y = slicenum;
        plot(handles.axes1, mean(x), mean(z), 'o', 'color', cmap(handles.numTC, :));
end
hold off

time = ([1:handles.ss(4)]-1)/handles.info.daq.scanRate;
switch calval
    case 1
        % Do nothing. The axes coordinates and the indices of the data
        % matrix are already the same.
    case 2
        x = (x/handles.info.GUIcalFactors.x_umPerPix)+1;
        y = (y/handles.info.GUIcalFactors.y_umPerPix)+1;
        z = (z/handles.info.GUIcalFactors.z_umPerPix)+1;
    case 3
        xCal = str2num(get(handles.xCalTextbox, 'String'));
        yCal = str2num(get(handles.yCalTextbox, 'String'));
        zCal = str2num(get(handles.zCalTextbox, 'String'));
        x = (x/xCal)+1;
        y = (y/yCal)+1;
        z = (z/zCal)+1;
end

isMIP = get(handles.mipViewCheckbox, 'Value');

switch mipval
    case 1
        if (isMIP)
            thickness = round(str2num(get(handles.zSliceThicknessTextbox, 'String'))/2);
        else
            thickness = 0;
        end
        win = [-thickness:thickness];
        z = slicenum+win;
        z(1) = max(1, z(1));
        z(end) = min(z(end), handles.ss(2));
        z = [z(1):z(end)];
    case 2
        if (isMIP)
            thickness = round(str2num(get(handles.xSliceThicknessTextbox, 'String'))/2);
        else
            thickness = 0;
        end
        win = [-thickness:thickness];
        x = slicenum+win;
        x(1) = max(1, x(1));
        x(end) = min(x(end), handles.ss(3));
        x = [x(1):x(end)];
    case 3
        if (isMIP)
            thickness = round(str2num(get(handles.ySliceThicknessTextbox, 'String'))/2);
        else
            thickness = 0;
        end
        win = [-thickness:thickness];
        y = slicenum+win;
        y(1) = max(1, y(1));
        y(end) = min(y(end), handles.ss(1));
        y = [y(1):y(end)];
end


x =round(x); y = round(y); z = round(z);
if (isMIP)
    if ~handles.RGB
    switch mipval
        case 1
            handles.ROI(handles.numTC).TC = squeeze(mean(mean(squeeze(max(handles.data(min(y):max(y), ...
                min(z):max(z), min(x):max(x), :),[], 2)), 1), 2));
        case 2
            handles.ROI(handles.numTC).TC = squeeze(mean(mean(squeeze(max(handles.data(min(y):max(y), ...
                min(z):max(z), min(x):max(x), :),[], 3)), 1), 2));
        case 3
            handles.ROI(handles.numTC).TC = squeeze(mean(mean(squeeze(max(handles.data(min(y):max(y), ...
                min(z):max(z), min(x):max(x), :),[], 1)), 1), 2));
    end
    else
     switch mipval
        case 1
            handles.ROI(handles.numTC).TC = squeeze(mean(mean(squeeze(max(handles.green(min(y):max(y), ...
                min(z):max(z), min(x):max(x), :),[], 2)), 1), 2));
        case 2
            handles.ROI(handles.numTC).TC = squeeze(mean(mean(squeeze(max(handles.green(min(y):max(y), ...
                min(z):max(z), min(x):max(x), :),[], 3)), 1), 2));
        case 3
            handles.ROI(handles.numTC).TC = squeeze(mean(mean(squeeze(max(handles.green(min(y):max(y), ...
                min(z):max(z), min(x):max(x), :),[], 1)), 1), 2));
    end    
        
    end
    
    handles.ROI(handles.numTC).x  = x;
    handles.ROI(handles.numTC).y = y;
    handles.ROI(handles.numTC).z = z;
    handles.ROI(handles.numTC).isMIP = 1;
    handles.ROI(handles.numTC).MIPval = mipval;
     
else
    if ~handles.RGB
    handles.ROI(handles.numTC).TC = squeeze(mean(mean(squeeze(handles.data(min(y):max(y), ...
        min(z):max(z), min(x):max(x), :)), 1), 2));
    else
    handles.ROI(handles.numTC).TC = squeeze(mean(mean(squeeze(handles.green(min(y):max(y), ...
        min(z):max(z), min(x):max(x), :)), 1), 2));
        
    end
    handles.ROI(handles.numTC).x  = x;
    handles.ROI(handles.numTC).y = y;
    handles.ROI(handles.numTC).z = z;
    handles.ROI(handles.numTC).isMIP = 0;
end
figure(2);
hold on;
plot(time, handles.ROI(handles.numTC).TC'+(10*handles.numTC), 'color', cmap(handles.numTC, :));

handles.numTC = handles.numTC+1;
guidata(hObject, handles);

function clearTimecoursesPushbutton_Callback(hObject, eventdata, handles)
choice = questdlg('Are you sure you want to delete all saved timecourses?', ...
    'Yes', 'No');
if (strcmp(choice, 'Yes'))
    try
        close(2)
    catch
    end
    handles.numTC = 1;
    handles.ROI = [];
end
guidata(hObject, handles);

function exportTimecoursesPushbutton_Callback(hObject, eventdata, handles)
varname = cell2mat(inputdlg('Enter variable name of exported time courses:'));
assignin('base', varname, handles.ROI);

guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% COLORMAP CALLBACKS %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function colorMaxSlider_Callback(hObject, eventdata, handles)
val = get(handles.colorMaxSlider, 'Value');
set(handles.colorMaxTextbox, 'String', num2str(uint16(val*handles.maxDataColor)))
sliceslider_Callback(hObject, eventdata, handles)

function colorMinSlider_Callback(hObject, eventdata, handles)
val = get(handles.colorMinSlider, 'Value');
set(handles.colorMinTextbox, 'String', num2str(uint16(val*handles.maxDataColor)))
sliceslider_Callback(hObject, eventdata, handles)

function colorMaxTextbox_Callback(hObject, eventdata, handles)
val = str2num(get(handles.colorMaxTextbox, 'String'));
set(handles.colorMaxSlider, 'Value', val/handles.maxDataColor)
sliceslider_Callback(hObject, eventdata, handles)

function colorMinTextbox_Callback(hObject, eventdata, handles)
val = str2num(get(handles.colorMinTextbox, 'String'));
set(handles.colorMinSlider, 'Value', val/handles.maxDataColor)
sliceslider_Callback(hObject, eventdata, handles)

function logScaleCheckbox_Callback(hObject, eventdata, handles)
sliceslider_Callback(hObject, eventdata, handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% RGB Color scaling %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function greenMaxTextbox_Callback(hObject, eventdata, handles)
val = str2num(get(handles.greenMaxTextbox, 'String'));
set(handles.greenMaxSlider, 'Value', val/handles.maxgreenColor)
sliceslider_Callback(hObject, eventdata, handles)

function greenMinSlider_Callback(hObject, eventdata, handles)
val = get(handles.greenMinSlider, 'Value');
set(handles.greenMinTextbox, 'String', num2str(uint16(val*handles.maxgreenColor)))
sliceslider_Callback(hObject, eventdata, handles)

function greenMinTextbox_Callback(hObject, eventdata, handles)
val = str2num(get(handles.greenMinTextbox, 'String'));
set(handles.greenMinSlider, 'Value', val/handles.maxgreenColor)
sliceslider_Callback(hObject, eventdata, handles)

function greenMaxSlider_Callback(hObject, eventdata, handles)
val = get(handles.greenMaxSlider, 'Value');
set(handles.greenMaxTextbox, 'String', num2str(uint16(val*handles.maxgreenColor)))
sliceslider_Callback(hObject, eventdata, handles)

function greenlogscale_Callback(hObject, eventdata, handles)
sliceslider_Callback(hObject, eventdata, handles)

function redMaxTextbox_Callback(hObject, eventdata, handles)
val = str2num(get(handles.redMaxTextbox, 'String'));
set(handles.redMaxSlider, 'Value', val/handles.maxredColor)
sliceslider_Callback(hObject, eventdata, handles)

function redMinSlider_Callback(hObject, eventdata, handles)
val = get(handles.redMinSlider, 'Value');
set(handles.redMinTextbox, 'String', num2str(uint16(val*handles.maxredColor)))
sliceslider_Callback(hObject, eventdata, handles)

function redMinTextbox_Callback(hObject, eventdata, handles)
val = str2num(get(handles.redMinTextbox, 'String'));
set(handles.redMinSlider, 'Value', val/handles.maxredColor)
sliceslider_Callback(hObject, eventdata, handles)

function redMaxSlider_Callback(hObject, eventdata, handles)
val = get(handles.redMaxSlider, 'Value');
set(handles.redMaxTextbox, 'String', num2str(uint16(val*handles.maxredColor)))
sliceslider_Callback(hObject, eventdata, handles)

function redlogscale_Callback(hObject, eventdata, handles)
sliceslider_Callback(hObject, eventdata, handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% CROP FIELD CALLBACKS %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cropFieldCheckbox_Callback(hObject, eventdata, handles)
val = get(handles.cropFieldCheckbox, 'Value');
if(val == 0)
    set(handles.cropUIPanel, 'Visible', 'Off');
    handles.cropParams.xmin = handles.x(1);
    handles.cropParams.ymin = handles.y(1);
    handles.cropParams.zmin = handles.z(1);
    handles.cropParams.xmax = handles.x(end);
    handles.cropParams.ymax = handles.y(end);
    handles.cropParams.zmax = handles.z(end);
else
    set(handles.cropUIPanel, 'Visible', 'On');
    handles.cropParams.xmin = str2num(get(handles.cropXminTextbox, 'String'));
    handles.cropParams.ymin = str2num(get(handles.cropYminTextbox, 'String'));
    handles.cropParams.zmin = str2num(get(handles.cropZminTextbox, 'String'));
    handles.cropParams.xmax = str2num(get(handles.cropXmaxTextbox, 'String'));
    handles.cropParams.ymax = str2num(get(handles.cropYmaxTextbox, 'String'));
    handles.cropParams.zmax = str2num(get(handles.cropZmaxTextbox, 'String'));
end
sliceslider_Callback(hObject, eventdata, handles)

function cropXminTextbox_Callback(hObject, eventdata, handles)
val = str2num(get(handles.cropXminTextbox, 'String'));
if(val>=handles.cropParams.xmax)
    val = handles.cropParams.xmax-1;
    set(handles.cropXminTextbox, 'String', num2str(val));
elseif (val<0)
    val = 0;
    set(handles.cropXminTextbox, 'String', num2str(val));
end
cropFieldCheckbox_Callback(hObject, eventdata, handles)

function cropXmaxTextbox_Callback(hObject, eventdata, handles)
val = str2num(get(handles.cropXmaxTextbox, 'String'));
if(val<=handles.cropParams.xmin)
    val = handles.cropParams.xmin+1;
    set(handles.cropXmaxTextbox, 'String', num2str(val));
elseif (val>handles.x(end))
    val = handles.x(end);
    set(handles.cropXmaxTextbox, 'String', num2str(val));
end
cropFieldCheckbox_Callback(hObject, eventdata, handles)

function cropYminTextbox_Callback(hObject, eventdata, handles)
val = str2num(get(handles.cropYminTextbox, 'String'));
if(val>=handles.cropParams.ymax)
    val = handles.cropParams.ymax-1;
    set(handles.cropYminTextbox, 'String', num2str(val));
elseif (val<0)
    val = 0;
    set(handles.cropYminTextbox, 'String', num2str(val));
end
cropFieldCheckbox_Callback(hObject, eventdata, handles)

function cropYmaxTextbox_Callback(hObject, eventdata, handles)
val = str2num(get(handles.cropYmaxTextbox, 'String'));
if(val<=handles.cropParams.ymin)
    val = handles.cropParams.ymin+1;
    set(handles.cropYmaxTextbox, 'String', num2str(val));
elseif (val>handles.y(end))
    val = handles.y(end);
    set(handles.cropYmaxTextbox, 'String', num2str(val));
end
cropFieldCheckbox_Callback(hObject, eventdata, handles)

function cropZminTextbox_Callback(hObject, eventdata, handles)
val = str2num(get(handles.cropZminTextbox, 'String'));
if(val>=handles.cropParams.zmax)
    val = handles.cropParams.zmax-1;
    set(handles.cropZminTextbox, 'String', num2str(val));
elseif (val<0)
    val = 0;
    set(handles.cropZminTextbox, 'String', num2str(val));
end
cropFieldCheckbox_Callback(hObject, eventdata, handles)

function cropZmaxTextbox_Callback(hObject, eventdata, handles)
val = str2num(get(handles.cropZmaxTextbox, 'String'));
if(val<=handles.cropParams.zmin)
    val = handles.cropParams.zmin+1;
    set(handles.cropZmaxTextbox, 'String', num2str(val));
elseif (val>handles.z(end))
    val = handles.z(end);
    set(handles.cropZmaxTextbox, 'String', num2str(val));
end
cropFieldCheckbox_Callback(hObject, eventdata, handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% ASPECT RATIO CALLBACKS %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function uniformAspectRadiobutton_Callback(hObject, eventdata, handles)
set(handles.customCalPanel, 'Visible', 'Off');
handles.y = [1:handles.ss(1)]-1;
handles.x = [1:handles.ss(3)]-1;
handles.z = [1:handles.ss(2)]-1;
cropFieldCheckbox_Callback(hObject, eventdata, handles)

function calibratedAspectRadiobutton_Callback(hObject, eventdata, handles)
handles.y = ([1:handles.ss(1)]-1)*handles.info.GUIcalFactors.y_umPerPix;
try
    handles.x = ([1:handles.ss(3)]-1)*handles.info.GUIcalFactors.x_umPerPix;
catch
    handles.info.GUIcalFactors.x_umPerPix = handles.info.GUIcalFactors.xK_umPerVolt*handles.info.daq.scanAngle/(handles.info.daq.pixelsPerLine-2);
    handles.x = ([1:handles.ss(3)]-1)*handles.info.GUIcalFactors.x_umPerPix;
end
handles.z = ([1:handles.ss(2)]-1)*handles.info.GUIcalFactors.z_umPerPix;
set(handles.customCalPanel, 'Visible', 'Off');
cropFieldCheckbox_Callback(hObject, eventdata, handles)

function customAspectRadiobutton_Callback(hObject, eventdata, handles)
set(handles.customCalPanel, 'Visible', 'On');

xCal = str2num(get(handles.xCalTextbox, 'String'));
yCal = str2num(get(handles.yCalTextbox, 'String'));
zCal = str2num(get(handles.zCalTextbox, 'String'));

handles.y = yCal*([1:handles.ss(1)]-1);
handles.x = xCal*([1:handles.ss(3)]-1);
handles.z = zCal*([1:handles.ss(2)]-1);
cropFieldCheckbox_Callback(hObject, eventdata, handles)

function xCalTextbox_Callback(hObject, eventdata, handles)
customAspectRadiobutton_Callback(hObject, eventdata, handles)

function yCalTextbox_Callback(hObject, eventdata, handles)
customAspectRadiobutton_Callback(hObject, eventdata, handles)

function zCalTextbox_Callback(hObject, eventdata, handles)
customAspectRadiobutton_Callback(hObject, eventdata, handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% MIP CALLBACKS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mipViewCheckbox_Callback(hObject, eventdata, handles)
val = get(handles.mipViewCheckbox,'Value');
if (val)
    set(handles.mipUIPanel, 'Visible', 'On');
else
    set(handles.mipUIPanel, 'Visible', 'Off');
end
sliceslider_Callback(hObject, eventdata, handles)

function xSliceThicknessTextbox_Callback(hObject, eventdata, handles)
% These 3 lines always make slice thickness an odd number (remember that
% going from -5 to 5 has 11 stops)

val = str2num(get(handles.xSliceThicknessTextbox, 'String'));
val = round((val-1)/2)*2+1;
val(val<0) = 0;
set(handles.xSliceThicknessTextbox, 'String', num2str(val));

sliceslider_Callback(hObject, eventdata, handles)

function ySliceThicknessTextbox_Callback(hObject, eventdata, handles)
val = str2num(get(handles.ySliceThicknessTextbox, 'String'));
val = round((val-1)/2)*2+1;
val(val<0) = 0;
set(handles.ySliceThicknessTextbox, 'String', num2str(val));

sliceslider_Callback(hObject, eventdata, handles)

function zSliceThicknessTextbox_Callback(hObject, eventdata, handles)
val = str2num(get(handles.zSliceThicknessTextbox, 'String'));
val = round((val-1)/2)*2+1;
val(val<0) = 0;
set(handles.zSliceThicknessTextbox, 'String', num2str(val));

sliceslider_Callback(hObject, eventdata, handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Analysis Functions go after this point %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cellTrackerPushButton_Callback(hObject, eventdata, handles)
condition = 0;

ss = size(handles.data);
cell.position.x = zeros(1, ss(4));
cell.position.y = zeros(1, ss(4));
cell.position.z = zeros(1, ss(4));

keyboard
while condition == 0
    disp('waiting for button press')
    k = waitforbuttonpress;
    switch k
        case 1 
    end
    disp('button pressed');
    
end
sliceslider_Callback(hObject, eventdata, handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Tiff generator %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function generateMIPTiffsPushButton_Callback(hObject, eventdata, handles)
mipval = get(handles.xyzview, 'Value');
handles.scanName = handles.info.scanName;
if ~handles.RGB
switch mipval
    case 1
        dataToWrite = permute(squeeze(max(handles.data, [], 2)), [2 1 3]);
        fileName = [handles.scanName '_XYMIP.tif'];
    case 2
        dataToWrite = permute(squeeze(max(handles.data, [], 3)), [2 1 3]);
        fileName = [handles.scanName '_YZMIP.tif'];
    case 3
        dataToWrite = squeeze(max(handles.data, [], 1));
        fileName = [handles.scanName '_XZMIP.tif'];
end
else
switch mipval
    case 1
        red = permute(squeeze(max(handles.red, [], 2)), [2 1 3]);
        green = permute(squeeze(max(handles.green, [], 2)), [2 1 3]);
        dataToWrite = cat(4, red, green, zeros(size(red)));
        dataToWrite = permute(dataToWrite,[1 2 4 3]); 
        fileName = [handles.scanName '_XYMIP_rgb.tif'];
    case 2
        red = permute(squeeze(max(handles.red, [], 3)), [2 1 3]);
        green = permute(squeeze(max(handles.green, [], 3)), [2 1 3]);
        dataToWrite = cat(4, red, green, zeros(size(red)));
        dataToWrite = permute(dataToWrite,[1 2 4 3]); 
        fileName = [handles.scanName '_YZMIP_rgb.tif'];
    case 3
        red = squeeze(max(handles.red, [], 1));
        green = squeeze(max(handles.green, [], 1));
        dataToWrite = cat(4, red, green, zeros(size(red)));
        dataToWrite = permute(dataToWrite,[1 2 4 3]); 
        fileName = [handles.scanName '_XZMIP_rgb.tif'];
end    
    
end
ss = size(dataToWrite);
[fileName pathName] = uiputfile([handles.info.storage_dir fileName], 'Save as');
if (fileName ~= 0)
    fileName = fullfile(pathName, fileName);
    h = waitbar(0, 'Please wait');
    if ~handles.RGB
    for i = 1:ss(end)
        imwrite(uint16(squeeze(dataToWrite(:, :, i))), fileName, 'tif', 'Compression', 'none', 'WriteMode', 'Append');
        waitbar(i/ss(end));
    end
    else
    for i = 1:ss(end)
        imwrite(uint16(squeeze(dataToWrite(:, :, :, i))), fileName, 'tif', 'Compression', 'none', 'WriteMode', 'Append');
        waitbar(i/ss(end));
    end 
    end
    close(h);
    disp('Finished saving to tiff');
end

function saveMovie_Callback(hObject, eventdata, handles)
calibratedAspectRadiobutton_Callback(hObject, eventdata, handles)
[out]= questdlg('What dimension do you want to make your movie over?','Movie Maker','time','stack','snapshot','time');

if strcmp(out,'time') && size(handles.ss,2)<4
    errordlg('Cannot make TIME movie - You only took one frame!')
    return
end
disp('Writing movie..')

if strcmp(out,'time');
if ~handles.RGB
fileName =  [handles.info.scanName '_' out '.avi'];
else
fileName =  [handles.info.scanName '_' out 'RGB.avi'];
end
[fileName pathName] = uiputfile([handles.info.storage_dir fileName], 'Save as');
    sliceslider_Callback(hObject, eventdata, handles);
    tmp = getframe(handles.axes1);
    tmp(1).cdata = zeros(size(tmp(1).cdata));
    for t = 1:handles.ss(4)
        F(t) = tmp;
    end
    for t = 1:handles.ss(4)
        handles.t = t;
        set(handles.timenum,'String',num2str(handles.t));
        sliceslider_Callback(hObject, eventdata, handles);
        axes(handles.axes1);
        hold on;
        a = axis;
        plot([a(2)-150, a(2)-50] ,[a(4)*0.9,a(4)*0.9],'LineWidth',2,'color','w');
        text(a(1)+20,a(3)+20,sprintf('t = %.2f s', t/handles.info.daq.scanRate),'color','w','FontSize',12);
        grid off
        F(t) = getframe(handles.axes1);
        axes(handles.axes1);
        cla
    end
            sliceslider_Callback(hObject, eventdata, handles);

    vidObj = VideoWriter(fullfile(pathName, fileName));% 'uncompressed avi');
    vidObj.FrameRate = handles.info.daq.scanRate;
    open(vidObj);
    for t = 1:handles.ss(end)
        writeVideo(vidObj,F(t));
    end
end
if strcmp(out,'stack')
    xyz = get(handles.xyzview, 'Value')
    if xyz ==1
        dd = handles.ss(2);
        ddd = 'z';
        cal = handles.info.cal.zdep;
    end
    if xyz ==2
        dd = handles.ss(3);
        ddd = 'x';
        cal = handles.info.cal.xwid;
    end
    if xyz ==3
        dd = handles.ss(1);
        ddd = 'y';
        cal = handles.info.cal.ylat;
    end
        if ~handles.RGB
            fileName =  [handles.info.scanName '_' ddd out '.avi'];
        else
            fileName =  [handles.info.scanName '_' ddd out 'RGB.avi'];
        end
        [fileName pathName] = uiputfile([handles.info.storage_dir fileName], 'Save as');%,handles.info.directory);
      
    sliceslider_Callback(hObject, eventdata, handles);
    tmp = getframe(handles.axes1);
    tmp(1).cdata = zeros(size(tmp(1).cdata));
    for t = 1:dd
        F(t) = tmp;
    end
    for d = 1:dd
        
        set(handles.sliceslider,'Value',d/dd);
        %        set(handles.timenum,'String',num2str(handles.t));
        sliceslider_Callback(hObject, eventdata, handles);
        axes(handles.axes1);
        hold on;
        a = axis;
        plot([a(2)-150, a(2)-50] ,[a(4)*0.9,a(4)*0.9],'LineWidth',2,'color','w');
        text(a(1)+20,a(3)+20,sprintf('%s = %.2f um', ddd,d*cal),'color','w','FontSize',12);
        grid off
        F(d) = getframe(handles.axes1);
        %     movieToWrite(:,:,:,handles.t) = F.cdata;
        axes(handles.axes1);
        cla
    end
        sliceslider_Callback(hObject, eventdata, handles);
    vidObj = VideoWriter(fullfile(pathName, fileName));
    vidObj.FrameRate = 10;
    open(vidObj);
    for t = 1:dd
        writeVideo(vidObj,F(t));
    end
    close(vidObj)
    disp('Done writing movie!')
end
if strcmp(out,'snapshot')
    if ~handles.RGB
        fileName =  [handles.info.scanName '.jpg'];
    else
        fileName =  [handles.info.scanName '.jpg'];
    end
    
[fileName pathName] = uiputfile([handles.info.storage_dir fileName], 'Save as');
    axes(handles.axes1);
    a = axis;
    hold on
    plot([a(2)-150, a(2)-50] ,[a(4)*0.9,a(4)*0.9],'LineWidth',2,'color','w');
    %        text(a(1)+20,a(3)+20,sprintf('%s = %.2f um', ddd,d*cal),'color','w','FontSize',12);
    F = getframe(handles.axes1);
    imwrite(F.cdata,fullfile(pathName, fileName),'JPEG');
end

function generateVolumeTiffsPushButton_Callback(hObject, eventdata, handles)
ss = size(dataToWrite);

mipval = get(handles.xyzview, 'Value');
handles.scanName = handles.info.scanName;
switch mipval
    case 1
        dataToWrite = permute(squeeze(max(handles.data, [], 2)), [2 1 3]);
        fileName = [handles.scanName '_XYMIP.tif'];
    case 2
        dataToWrite = permute(squeeze(max(handles.data, [], 3)), [2 1 3]);
        fileName = [handles.scanName '_YZMIP.tif'];
    case 3
        dataToWrite = squeeze(max(handles.data, [], 1));
        fileName = [handles.scanName '_XZMIP.tif'];
end


[fileName pathName] = uiputfile([handles.info.storage_dir fileName], 'Save as');
if (fileName ~= 0)
    fileName = fullfile(pathName, fileName);

    h = waitbar(0, 'Please wait');
    for i = 1:ss(end)
        imwrite(uint16(squeeze(dataToWrite(:, :, i))), fileName, 'tif', 'Compression', 'none', 'WriteMode', 'Append');
        waitbar(i/ss(end));
    end
    close(h);
    disp('Finished saving to tiff');
end


% --- Executes on button press in dataToWS.
function dataToWS_Callback(hObject, eventdata, handles)
% hObject    handle to dataToWS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles,'red');
    
    [out] = questdlg('Clear SCAPE_data?');
    if isempty(strfind(out,'Yes'));
    else
        evalin('base','clear SCAPE_data');
    end
    assignin('base','red',handles.red);
    assignin('base','green',handles.green);
else
    out = evalin('base','who(''SCAPE_data'')');
    if isempty(strfind(out,'SCAPE_data'));
        assignin('base','SCAPE_data',handles.data);
    else
         fname = evalin('base','info.scanName');
        [out] = questdlg(sprintf('Replace loaded SCAPE_data? (%s)',fname));
        if isempty(strfind(out,'Yes'));
        else
            assignin('base','SCAPE_data',handles.data);
        end
    end
end
 
%     handles.info.info.listbox = get(handles.text2,'String');
%     handles.info.info.storage_dir = get(handles.foldername,'String');
%     assignin('base','info',handles.info.info);
%     h = waitbar(1,'SCAPE data written to workspace');pause(1);close(h);
%     guidata(hObject,handles);
