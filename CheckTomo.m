function varargout = CheckTomo(varargin)
% CHECKTOMO MATLAB code for CheckTomo.fig
%      CHECKTOMO, by itself, creates a new CHECKTOMO or raises the existing
%      singleton*.
%
%      H = CHECKTOMO returns the handle to a new CHECKTOMO or the handle to
%      the existing singleton*.
%
%      CHECKTOMO('CALLBACK',hObject,eventData,handles,...) calls the local_menu
%      function named CALLBACK in CHECKTOMO.M with the given input arguments.
%
%      CHECKTOMO('Property','Value',...) creates a new CHECKTOMO or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before CheckTomo_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to CheckTomo_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help CheckTomo

% Last Modified by GUIDE v2.5 03-May-2017 15:54:36

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CheckTomo_OpeningFcn, ...
                   'gui_OutputFcn',  @CheckTomo_OutputFcn, ...
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
% End initialization code - DO NOT EDIT


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function CheckTomo_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to CheckTomo (see VARARGIN)

% Turn off MATLAB warnings
warning('off', 'all');

% Choose default command line output for DicomViewer
handles.output = hObject;

% Set version handle
handles.version = '0.1';

% Determine path of current application
[path, ~, ~] = fileparts(mfilename('fullpath'));

% Set current directory to location of this application
cd(path);

% Clear temporary variable
clear path;

% Set version information.  See LoadVersionInfo for more details.
handles.versionInfo = LoadVersionInfo;

% Store program and MATLAB/etc version information as a string cell array
string = {'TomoTherapy Plan Second Dose Calculation'
    sprintf('Version: %s (%s)', handles.version, handles.versionInfo{6});
    sprintf('Author: Mark Geurts <mark.w.geurts@gmail.com>');
    sprintf('MATLAB Version: %s', handles.versionInfo{2});
    sprintf('MATLAB License Number: %s', handles.versionInfo{3});
    sprintf('Operating System: %s', handles.versionInfo{1});
    sprintf('CUDA: %s', handles.versionInfo{4});
    sprintf('Java Version: %s', handles.versionInfo{5})
};

% Add dashed line separators      
separator = repmat('-', 1,  size(char(string), 2));
string = sprintf('%s\n', separator, string{:}, separator);

% Log information
Event(string, 'INIT');

%% Add submodules
% Add matlab calculation submodule to search path
addpath('./thomas_tomocalc');

% Check if MATLAB can find CheckTomoDose
if exist('CheckTomoDose', 'file') ~= 2
    
    % If not, throw an error
    Event(['The thomas_tomocalc submodule does not exist in the ', ...
        'search path. Use git clone --recursive or git submodule init ', ...
        'followed by git submodule update to fetch all submodules'], ...
        'ERROR');
end

% Add archive extraction submodule to search path
addpath('./tomo_extract');

% Check if MATLAB can find LoadPlan
if exist('LoadPlan', 'file') ~= 2
    
    % If not, throw an error
    Event(['The tomo_extract submodule does not exist in the ', ...
        'search path. Use git clone --recursive or git submodule init ', ...
        'followed by git submodule update to fetch all submodules'], ...
        'ERROR');
end

% Add gamma submodule to search path
addpath('./gamma');

% Check if MATLAB can find CalcGamma
if exist('CalcGamma', 'file') ~= 2
    
    % If not, throw an error
    Event(['The gamma submodule does not exist in the ', ...
        'search path. Use git clone --recursive or git submodule init ', ...
        'followed by git submodule update to fetch all submodules'], ...
        'ERROR');
end

% Add structure atlas submodule to search path
addpath('./structure_atlas');

% Check if MATLAB can find LoadDICOMImages
if exist('LoadAtlas', 'file') ~= 2
    
    % If not, throw an error
    Event(['The Structure Atlas submodule does not exist in the ', ...
        'search path. Use git clone --recursive or git submodule init ', ...
        'followed by git submodule update to fetch all submodules'], ...
        'ERROR');
end

%% Load configuration settings
% Open file handle to config.txt file
fid = fopen('config.txt', 'r');

% Verify that file handle is valid
if fid < 3
    
    % If not, throw an error
    Event(['The config.txt file could not be opened. Verify that this ', ...
        'file exists in the working directory. See documentation for ', ...
        'more information.'], 'ERROR');
end

% Scan config file contents
c = textscan(fid, '%s', 'Delimiter', '=');

% Close file handle
fclose(fid);

% Loop through textscan array, separating key/value pairs into array
for i = 1:2:length(c{1})
    handles.config.(strtrim(c{1}{i})) = strtrim(c{1}{i+1});
end

% Clear temporary variables
clear c i fid;

% Log completion
Event('Loaded config.txt parameters');

%% Initialize UI and global variables
% Set version UI text
handles.version_text = ['Version ', handles.version];

% Set default transparency
set(handles.alpha, 'String', handles.config.DEFAULT_TRANSPARENCY);

% Set dose calculation options
handles.methods = {
    'Standalone GPU Dose Calculator (fast)'
    'Standalone GPU Dose Calculator (full)'
    'MATLAB Dose Calculator (no supersampling)'
    'MATLAB Dose Calculator (supersampling)'
};
set(handles.method_menu, 'String', handles.methods);
set(handles.method_menu, 'Value', ...
    str2double(handles.config.DEFAULT_CALC_METHOD));
Event(['Default calculation method set to ', ...
    handles.methods{str2double(handles.config.DEFAULT_CALC_METHOD)}]);

% Set resolution options
handles.resolutions = {
    'Fine (1)'
    'Normal (2)'
    'Coarse (4)'
    'Extra Coarse (8)'
};
set(handles.resolution_menu, 'String', handles.resolutions);
set(handles.resolution_menu, 'Value', ...
    str2double(handles.config.DEFAULT_RESOLUTION));
Event(['Default resolution set to ', ...
    handles.resolutions{str2double(handles.config.DEFAULT_RESOLUTION)}]);

% Set Gamma criteria
handles.percent = str2double(handles.config.GAMMA_PERCENT); % percent
handles.dta = str2double(handles.config.GAMMA_DTA_MM); % mm
handles.local = str2double(handles.config.GAMMA_LOCAL); % boolean
set(handles.gamma_text, 'String', sprintf('%0.1f%%/%0.1f mm', ...
    handles.percent, handles.dta));
set(handles.gamma_text, 'enable', 'off');
set(handles.local_menu, 'String', {'Global', 'Local'});
set(handles.local_menu, 'Value', handles.local+1);
set(handles.local_menu, 'enable', 'off');
if handles.local == 0
    Event(sprintf('Gamma criteria set to %0.1f%%/%0.1f mm global', ...
        handles.percent, handles.dta));
else
    Event(sprintf('Gamma criteria set to %0.1f%%/%0.1f mm local', ...
        handles.percent, handles.dta));
end

% Set TCS display options
set(handles.tcs_menu, 'String', UpdateTCSDisplay());

% Set line display options
set(handles.line_menu, 'String', UpdateLineDisplay());

% Define default folder path when selecting input files
if strcmpi(handles.config.DEFAULT_PATH, 'userpath')
    handles.path = userpath;
else
    handles.path = handles.config.DEFAULT_PATH;
end
Event(['Default file path set to ', handles.path]);

% If an atlas file is specified in the config file
if isfield(handles.config, 'ATLAS_FILE')
    
    % Attempt to load the atlas
    handles.atlas = LoadAtlas(handles.config.ATLAS_FILE);
    
% Otherwise, declare an empty atlas
else
    handles.atlas = cell(0);
end

% Check for MVCT calculation flag
if isfield(handles.config, 'ALLOW_MVCT_CALC') && ...
        str2double(handles.config.ALLOW_MVCT_CALC) == 1
    
    % Log status
    Event('MVCT dose calculation enabled');
    
    % Enable MVCT dose calculation
    handles.mvctcalc = 1;

% If dose calc flag does not exist or is disabled
else
    
    % Log status
    Event('MVCT dose calculation disabled');
    
    % Disable MVCT dose calculation
    handles.mvctcalc = 0;
end

%% Clear UI, initializing plots
handles = clearData(handles);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function CheckTomo_OutputFcn(~, ~, ~) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tcs_menu_Callback(hObject, ~, handles) %#ok<*DEFNU>
% hObject    handle to tcs_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute UpdateTCSDisplay
handles = UpdateTCSDisplay(handles);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tcs_menu_CreateFcn(hObject, ~, ~)
% hObject    handle to tcs_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Popupmenu controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function line_menu_Callback(hObject, ~, handles)
% hObject    handle to line_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function line_menu_CreateFcn(hObject, ~, ~)
% hObject    handle to line_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Popupmenu controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function browse_text_Callback(~, ~, ~)
% hObject    handle to browse_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function browse_text_CreateFcn(hObject, ~, ~)
% hObject    handle to browse_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function browse_button_Callback(hObject, ~, handles)
% hObject    handle to browse_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log event
Event('Archive browse button selected');

% Warn the user that existing data will be deleted
if ~isfield(handles, 'plans') || ~isempty(handles.plans)

    % Ask user if they want to calculate dose
    choice = questdlg(['Existing plan data exists and will ', ...
        'be deleted. Continue?'], 'Confirm Erase', 'Yes', 'No', 'Yes');

    % If the user chose yes
    if strcmp(choice, 'Yes')
        
        % Execute clear function
        handles = clearData(handles);
        
        % Request the user to select the patient archive XML
        Event('UI window opened to select archive');
        [name, path] = uigetfile({'*_patient.xml', ...
            'Patient Archive (*.xml)'}, 'Select the Archive Patient XML', ...
            handles.path);
    else
        Event('User chose not to select new patient archive');
        name = 0;
    end
else
    % Request the user to select the patient archive XML
    Event('UI window opened to select archive');
    [name, path] = uigetfile({'*_patient.xml', 'Patient Archive (*.xml)'}, ...
        'Select the Archive Patient XML', handles.path);
end
    
% If the user selected a file
if ~isequal(name, 0)
    
    % Update default path
    handles.path = path;
    Event(['Default file path updated to ', path]);
    
    % Update browse text box
    set(handles.browse_text, 'String', fullfile(path, name));
        
    % Extract plan list
    handles.plans = FindPlans(path, name); 
    
    % If LoadDailyQA was successful
    if ~isempty(handles.plans)
        
        % If more than one plan was found
        if length(handles.plans) > 1
            
            % Log event
            Event(['Multiple plans found, opening listdlg to prompt user ', ...
                'to select which one to load']);

            % Otherwise, prompt the user to select from handles.plans
            [id, ok] = listdlg('Name', 'Plan Selection', ...
                'PromptString', ['Multiple approved plans were found. ', ...
                'Choose which one to load:'],...
                    'SelectionMode', 'single', 'ListSize', [500 300], ...
                    'ListString', handles.plans);

            % If the user selected cancel, throw an error
            if ok == 0
                Event('No plan was chosen');
                return;
            
            % Otherwise, set the UID to the selected one
            else
                Event(sprintf('User selected delivery plan UID %i', ...
                    handles.plans{id}));
                
                handles.planuid = handles.plans{id};
            end

            % Clear temporary variables
            clear ok id;
        
        % Otherwise, only one plan exists
        else
            handles.planuid = handles.plans{1};
        end
        
        % Initialize progress bar
        progress = waitbar(0.1, 'Loading plan from patient archive...');
        
        % Log start
        Event(['Loading plan, planning image, and reference dose for ', ...
            'selected plan']);
        
        % Load the plan
        handles.plan = LoadPlan(path, name, handles.planuid);
        
        % Populate and enable the image list
        set(handles.image_menu, 'String', {'Planning CT'});
        set(handles.image_menu, 'Value', 1);
        
        % Update progress bar
        waitbar(0.2, progress, 'Loading image sets...');
        
        % Load the planning CT
        handles.referenceImage = LoadImage(path, name, handles.planuid);

        % Add MVCT images
        %
        %
        %
        %
        %
        %  
        
        % Enable the image menu
        set(handles.image_menu, 'Enable', 'On');
        
        % Update progress bar
        waitbar(0.4, progress, 'Loading structure set...');
        
        % Load the structure set
        handles.referenceImage.structures = LoadStructures(path, name, ...
            handles.referenceImage, handles.atlas);
        
        % Initialize statistics table
        set(handles.struct_table, 'Data', InitializeStatistics(...
            handles.referenceImage.structures, handles.atlas));
        
        % Update progress bar
        waitbar(0.6, progress, 'Loading planned dose...');
        
        % Load the reference dose
        handles.referenceDose = LoadPlanDose(path, name, handles.planuid);
        
        % Update progress bar
        waitbar(0.8, progress, 'Updating dose display...');
        
        % Display the planning dose by initializing new figure objects
        set(handles.tcs_menu, 'Value', 1);
        handles.transverse = ImageViewer('axis', handles.trans_axes, ...
            'tcsview', 'T', 'background', handles.referenceImage, ...
            'overlay', handles.referenceDose, 'alpha', ...
            sscanf(get(handles.alpha, 'String'), '%f%%')/100, ...
            'structures', handles.referenceImage.structures, ...
            'structuresonoff', handles.struct_table, ...
            'slider', handles.trans_slider, 'cbar', 'off');
        handles.coronal = ImageViewer('axis', handles.cor_axes, ...
            'tcsview', 'C', 'background', handles.referenceImage, ...
            'overlay', handles.referenceDose, 'alpha', ...
            sscanf(get(handles.alpha, 'String'), '%f%%')/100, ...
            'structures', handles.referenceImage.structures, ...
            'structuresonoff', handles.struct_table, ...
            'slider', handles.cor_slider, 'cbar', 'off');
        handles.sagittal = ImageViewer('axis', handles.sag_axes, ...
            'tcsview', 'S', 'background', handles.referenceImage, ...
            'overlay', handles.referenceDose, 'alpha', ...
            sscanf(get(handles.alpha, 'String'), '%f%%')/100, ...
            'structures', handles.referenceImage.structures, ...
            'structuresonoff', handles.struct_table, ...
            'slider', handles.sag_slider, 'cbar', 'on');
        set(handles.alpha, 'visible', 'on');

        % Update DVH plot
        [handles.referenceDose.dvh] = ...
            UpdateDVH(handles.dvh_axes, get(handles.struct_table, 'Data'), ...
            handles.referenceImage, handles.referenceDose);
        
        % Update Dx/Vx statistics
        set(handles.struct_table, 'Data', UpdateDoseStatistics(...
            get(handles.struct_table, 'Data'), [], ...
            handles.referenceDose.dvh, []));
        
        % Enable the results and display tables
        set(handles.stats_table, 'enable', 'on');
        set(handles.struct_table, 'enable', 'on');
        
        % Enable the display options
        set(handles.tcs_menu, 'Enable', 'On');
        set(handles.line_menu, 'Enable', 'On');
        
        % Enable the calculation options
        set(handles.method_menu, 'Enable', 'On');
        set(handles.resolution_menu, 'Enable', 'On');
        set(handles.dose_button, 'Enable', 'on');
        
        % Close progress bar
        close(progress);
        
        % Log completion
        Event(['Archive load completed successfully. You may now select ', ...
            'options and recalculate dose']);
        
    % Otherwise, no eligible plans were found
    else
        
        % Warn user
        Event('No plans were found. Select a new patient archive', 'WARN');
        msgbox('No plans were found. Select a new patient archive', ...
            'Load Warning');
    end
    
% Otherwise the user did not select a file
else
    Event('No archive file was selected');
end

% Clear temporary variables
clear name path progress;

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function method_menu_Callback(hObject, eventdata, handles)
% hObject    handle to method_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns method_menu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from method_menu


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function method_menu_CreateFcn(hObject, ~, ~)
% hObject    handle to method_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Popupmenu controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function resolution_menu_Callback(hObject, eventdata, handles)
% hObject    handle to resolution_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns resolution_menu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from resolution_menu


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function resolution_menu_CreateFcn(hObject, ~, ~)
% hObject    handle to resolution_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Popupmenu controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function gamma_text_Callback(hObject, eventdata, handles)
% hObject    handle to gamma_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of gamma_text as text
%        str2double(get(hObject,'String')) returns contents of gamma_text as a double


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function gamma_text_CreateFcn(hObject, ~, ~)
% hObject    handle to gamma_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function local_menu_Callback(hObject, eventdata, handles)
% hObject    handle to local_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns local_menu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from local_menu


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function local_menu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to local_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dose_button_Callback(hObject, eventdata, handles)
% hObject    handle to dose_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function gamma_button_Callback(hObject, eventdata, handles)
% hObject    handle to gamma_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function trans_slider_Callback(hObject, ~, handles)
% hObject    handle to trans_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Update transverse plot
handles.transverse.Update('slice', round(get(hObject, 'Value')));

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function trans_slider_CreateFcn(hObject, ~, ~)
% hObject    handle to trans_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cor_slider_Callback(hObject, ~, handles)
% hObject    handle to cor_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Update coronal plot
handles.coronal.Update('slice', round(get(hObject, 'Value')));

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cor_slider_CreateFcn(hObject, ~, ~)
% hObject    handle to cor_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sag_slider_Callback(hObject, ~, handles)
% hObject    handle to sag_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Update sagittal plot
handles.sagittal.Update('slice', round(get(hObject, 'Value')));

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sag_slider_CreateFcn(hObject, ~, ~)
% hObject    handle to sag_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function alpha_Callback(hObject, ~, handles)
% hObject    handle to alpha (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% If the string contains a '%', parse the value
if ~isempty(strfind(get(hObject, 'String'), '%'))
    value = sscanf(get(hObject, 'String'), '%f%%');
    
% Otherwise, attempt to parse the response as a number
else
    value = str2double(get(hObject, 'String'));
end

% Bound value to [0 100]
value = max(0, min(100, value));

% Log event
Event(sprintf('Dose transparency set to %0.0f%%', value));

% Update string with formatted value
set(hObject, 'String', sprintf('%0.0f%%', value));

% Update plots
handles.transverse.Update('alpha', value/100);
handles.coronal.Update('alpha', value/100);
handles.sagittal.Update('alpha', value/100);
  
% Clear temporary variable
clear value;

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function alpha_CreateFcn(hObject, ~, ~)
% hObject    handle to alpha (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function line_slider_Callback(hObject, eventdata, handles)
% hObject    handle to line_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function line_slider_CreateFcn(hObject, ~, ~)
% hObject    handle to line_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function image_menu_Callback(hObject, eventdata, handles)
% hObject    handle to image_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns image_menu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from image_menu


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function image_menu_CreateFcn(hObject, ~, ~)
% hObject    handle to image_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Popupmenu controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function handles = clearData(handles)
% This function clears all data and resets all UI components. This function
% is also called during program initialization to set up the interface and
% all internal variables.

% Log action
Event('Resetting all variables and clearing display');

% Disable plots
if isfield(handles, 'transverse')
    delete(handles.transverse);
else
    set(allchild(handles.trans_axes), 'visible', 'off'); 
    set(handles.trans_axes, 'visible', 'off');
    set(handles.trans_slider, 'visible', 'off');
end
if isfield(handles, 'coronal')
    delete(handles.coronal);
else
    set(allchild(handles.cor_axes), 'visible', 'off'); 
    set(handles.cor_axes, 'visible', 'off');
    set(handles.cor_slider, 'visible', 'off');
end
if isfield(handles, 'sagittal')
    delete(handles.sagittal);
else
    set(allchild(handles.sag_axes), 'visible', 'off'); 
    set(handles.sag_axes, 'visible', 'off');
    set(handles.sag_slider, 'visible', 'off');
end
set(handles.line_axes, 'visible', 'off');
set(allchild(handles.line_axes), 'visible', 'off'); 
set(handles.dvh_axes, 'visible', 'off');
set(allchild(handles.dvh_axes), 'visible', 'off'); 

% Disable sliders/alpha
set(handles.line_slider, 'visible', 'off');
set(handles.alpha, 'visible', 'off');

% Disable tables and plot dropdowns
set(handles.stats_table, 'enable', 'off');
set(handles.struct_table, 'enable', 'off');
set(handles.method_menu, 'enable', 'off');
set(handles.resolution_menu, 'enable', 'off');
set(handles.line_menu, 'enable', 'off');
set(handles.tcs_menu, 'enable', 'off');
set(handles.image_menu, 'enable', 'off');
set(handles.image_menu, 'String', 'Planning CT');

% Disable calculation buttons
set(handles.dose_button, 'enable', 'off');
set(handles.gamma_button, 'enable', 'off');

% Initialize non-UI variables
handles.plans = [];
handles.plan = [];
handles.planuid = [];
handles.referenceImage = [];
handles.mergedImage = [];
handles.referenceDose = [];
handles.secondDose = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function struct_table_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to dvh_table (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty 
%       if Data was not changed
%	Error: error string when failed to convert EditData to appropriate 
%       value for Data
% handles    structure with handles and user data (see GUIDATA)

% Get current data
stats = get(hObject, 'Data');

% Verify edited Dx value is a number or empty
if eventdata.Indices(2) == 3 && isnan(str2double(...
        stats{eventdata.Indices(1), eventdata.Indices(2)})) && ...
        ~isempty(stats{eventdata.Indices(1), eventdata.Indices(2)})
    
    % Warn user
    Event(sprintf(['Dx value "%s" is not a number, reverting to previous ', ...
        'value'], stats{eventdata.Indices(1), eventdata.Indices(2)}), 'WARN');
    
    % Revert value to previous
    stats{eventdata.Indices(1), eventdata.Indices(2)} = ...
        eventdata.PreviousData;
    
% Otherwise, if Dx was changed
elseif eventdata.Indices(2) == 3
    
    % Update edited Dx/Vx statistic
    stats = UpdateDoseStatistics(stats, eventdata.Indices);
    
% Otherwise, if display value was changed
elseif eventdata.Indices(2) == 2

    % Update the image plots are displayed
    if strcmpi(get(handles.alpha, 'visible'), 'on')
        
        % Update plots
        handles.transverse.Update('structuresonoff', stats);
        handles.coronal.Update('structuresonoff', stats);
        handles.sagittal.Update('structuresonoff', stats);
    end

    % Update DVH plot if it is displayed
    if strcmp(get(handles.dvh_axes, 'visible'), 'on')
        
        % Update DVH plot
        UpdateDVH(stats); 
    end
end

% Set new table data
set(hObject, 'Data', stats);

% Clear temporary variable
clear stats;

% Update handles structure
guidata(hObject, handles);
