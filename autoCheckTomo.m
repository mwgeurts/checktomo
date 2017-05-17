function autoCheckTomo()
% autoCheckTomo scans for patient archives in a preset directory 
% (given by the variable AUTO_INPUT_DIR below) and runs a secondary calc 
% using the defined method as detailed in the CheckTomo application for 
% each plan found. A line containing the high level results is appended 
% to the .csv file specified in the variable AUTO_RESULTS_CSV, with the
% DVHs saved to the directory specified in the variable AUTO_DVH_DIR.
%
% If an entry already exists for the patient archive (determined by SHA1
% signature), calc method, and plan (determined by UID), the workflow will 
% be skipped. In this manner, autoCheckTomo can be run multiple times to  
% analyze a large directory of archives.
%
% The AUTO_RESULTS_CSV file contains the following columns:
%   {1}: Full path to patient archive _patient.xml.  However, if 
%       the config option AUTO_ANON_RESULTS is set to 1, will be empty.
%   {2}: SHA1 signature of _patient.xml file
%   {3}: Plan UID
%	{4}: Plan Name
%   {5}: Atlas category (HN, Brain, Thorax, Abdomen, Pelvis)
%   {6}: Number of structures loaded (helpful when loading DVH .csv files)
%   {7}: Field width (cm)
%   {8}: Calculation method
%   {9}: Time to perform calculation (sec)
%   {10}: Dose grid resolution in axial plane (mm)
%   {11}: Mean dose difference above threshold (%)
%   {12}: Gamma pass rate above threshold (%)
%   {13}: Mean Gamma index above threshold (%)
%   {14}: Version number of autoCheckTomo when plan was run
%
% The AUTO_DVH_DIR contains a .csv file for each reference and second plan 
% dose in the following format. The name for each .csv file follows the
% convention 'planuid_calc.csv', where planuid is the Plan UID and calc is
% either 'REFERENCE' or the calculation method. The first row contains the 
% file name, the second row contains column headers for each structure set 
% (including the volume in cc in parentheses), with each subsequent row 
% containing the percent volume of each structure at or above the dose 
% specified in the first column (in Gy).  The resolution is determined by 
% dividing the maximum dose by 1001.
%
% The AUTO_DICOM_DIR contains a folder for each plan (using the plan UID)
% and contains a full set of DICOM CT images, RT structure set, reference
% RT Plan and Dose files, and an RT Plan and Dose file for each calculation
% using the naming format RTPlan_calc.dcm and RTDose_calc.dcm, either 
% 'REFERENCE' or the calculation method. DICOM export can be disabled by 
% setting AUTO_SAVE_DICOM to 0 in the config.txt file.
%
% The calculation method, resolution, and analysis parameters (Gamma
% criteria, dose threshold, etc.) are also read from the config.txt file.
%
% Author: Mark Geurts, mark.w.geurts@gmail.com
% Copyright (C) 2017 University of Wisconsin Board of Regents
%
% This program is free software: you can redistribute it and/or modify it 
% under the terms of the GNU General Public License as published by the  
% Free Software Foundation, either version 3 of the License, or (at your 
% option) any later version.
%
% This program is distributed in the hope that it will be useful, but 
% WITHOUT ANY WARRANTY; without even the implied warranty of 
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General 
% Public License for more details.
% 
% You should have received a copy of the GNU General Public License along 
% with this program. If not, see http://www.gnu.org/licenses/.

%% Set runtime variables
% Turn off MATLAB warnings
warning('off','all');

% Set version handle
version = '1.0.4';

% Determine path of current application
[path, ~, ~] = fileparts(mfilename('fullpath'));

% Set current directory to location of this application
cd(path);

% Clear temporary variable
clear path;

%% Initialize Log
% Set version information.  See LoadVersionInfo for more details.
versionInfo = LoadVersionInfo;

% Store program and MATLAB/etc version information as a string cell array
string = {'TomoTherapy Second Dose Calculation autoCheck Tool'
    sprintf('Version: %s (%s)', version, versionInfo{6});
    sprintf('Author: Mark Geurts <mark.w.geurts@gmail.com>');
    sprintf('MATLAB Version: %s', versionInfo{2});
    sprintf('MATLAB License Number: %s', versionInfo{3});
    sprintf('Operating System: %s', versionInfo{1});
    sprintf('CUDA: %s', versionInfo{4});
    sprintf('Java Version: %s', versionInfo{5})
};

% Add dashed line separators      
separator = repmat('-', 1,  size(char(string), 2));
string = sprintf('%s\n', separator, string{:}, separator);

% Log information
Event(string, 'INIT');

% Clear temporary variables
clear string separator versionInfo;

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

% Check if MATLAB can find LoadAtlas
if exist('LoadAtlas', 'file') ~= 2
    
    % If not, throw an error
    Event(['The Structure Atlas submodule does not exist in the ', ...
        'search path. Use git clone --recursive or git submodule init ', ...
        'followed by git submodule update to fetch all submodules'], ...
        'ERROR');
end

% Add dicom_tools submodule to search path
addpath('./dicom_tools');

% Check if MATLAB can find WriteDVH
if exist('WriteDVH', 'file') ~= 2
    
    % If not, throw an error
    Event(['The DICOM Tools submodule does not exist in the ', ...
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
    config.(strtrim(c{1}{i})) = strtrim(c{1}{i+1});
end

% Clear temporary variables
clear c i fid;

% Log completion
Event('Loaded config.txt parameters');

%% Load Results .csv
% Open file handle to current results .csv set
fid = fopen(config.AUTO_RESULTS_CSV, 'r');

% If a valid file handle was returned
if fid > 0
    
    % Log loading of existing results
    Event('Found results file');
    
    % Scan results .csv file for the following format of columns (see
    % documentation above for the results file format)
    results = textscan(fid, '%s %s %s %s %s %s %s %s %s %s %s %s %s %s', ...
        'Delimiter', {','}, 'commentStyle', '#');
    
    % Close the file handle
    fclose(fid);
    
    % Log completion
    Event(sprintf('%i results loaded from %s', size(results{1}, 1) - 1, ...
        config.AUTO_RESULTS_CSV));

% Otherwise, create new results file, saving column headers
else
    
    % Log generation of new file
    Event(['Generating new results file ', config.AUTO_RESULTS_CSV]);
    
    % Open write file handle to current results set
    fid = fopen(config.AUTO_RESULTS_CSV, 'w');
    
    % Print version information
    fprintf(fid, '# TomoTherapy Second Dose Calculation autoCheckTomo Tool\n');
    fprintf(fid, '# Author: Mark Geurts <mark.w.geurts@gmail.com>\n');
    fprintf(fid, ['# See autoCheckTomo.m and README.md for ', ...
        'more information on the format of this results file\n']);
    
    % Print column headers
    fprintf(fid, 'Archive,');
    fprintf(fid, 'SHA1,');
    fprintf(fid, 'Plan UID,');
    fprintf(fid, 'Plan Name,');
    fprintf(fid, 'Plan Type,');
    fprintf(fid, 'Structures,');
    fprintf(fid, 'Field Width,');
    fprintf(fid, 'Calculation,');
    fprintf(fid, 'Time,');
    fprintf(fid, 'Resolution,');
    fprintf(fid, 'Mean Difference,');
    fprintf(fid, 'Gamma Pass Rate,');
    fprintf(fid, 'Mean Gamma,');
    fprintf(fid, 'Version\n');

    % Close the file handle
    fclose(fid);
end

% Clear file hande
clear fid;

% Set initial dose calculation options (only MATLAB)
methods = {
    'MATLAB'
    'MATLAB_supersample'
};

% Test for connection to Standalone calculator
gpudose = 0; %#ok<NASGU>

% Declare path to beam model folder (if not specified in config file, use
% default path of ./GPU)
if isfield(config, 'MODEL_PATH')
    modeldir = config.MODEL_PATH;
else
    modeldir = './model';
end

% Check for beam model files
if exist(fullfile(modeldir, 'dcom.header'), 'file') == 2 && ...
        exist(fullfile(modeldir, 'fat.img'), 'file') == 2 && ...
        exist(fullfile(modeldir, 'kernel.img'), 'file') == 2 && ...
        exist(fullfile(modeldir, 'lft.img'), 'file') == 2 && ...
        exist(fullfile(modeldir, 'penumbra.img'), 'file') == 2

    % Log name
    Event('Beam model files verified for standalone calculator');
    
    % Check for presence of dose calculator
    gpudose = CalcDose();
    
    % If calc dose was successful
    if gpudose == 1

        % Log dose calculation status
        Event('Standalone GPU Dose calculation available');

        % Add GPU options
        methods{length(methods)+1} = ...
            'GPUSADOSE';
        methods{length(methods)+1} = ...
            'GPUSADOSE_full';
        methods{length(methods)+1} = ...
            'SADOSE';

    % Otherwise, calc dose was not successful
    else

        % Log dose calculation status
        Event('Standalone dose calculation engine not available', 'WARN');
        
        % Store status
        gpudose = 0;
    end
else

    % Store status
    gpudose = 0;

    % Throw a warning
    Event(sprintf(['Standalone dose calculation disabled, beam model ', ...
        'not found. Verify that %s exists and contains the necessary ', ...
        'model files'], modeldir), 'WARN');
end

% Store method
method = methods{str2double(config.DEFAULT_CALC_METHOD)};

% If GPU was selected and gpudose failed, throw an error
if ~strcmpi(method(1:6), 'MATLAB') ...
        && gpudose == 0
    Event(['You have selected a standalone method but either the ', ...
        'executable or beam model files are not available'], 'ERROR');
end

% Clear temporary variables
clear methods gpudose;

% Set downsample options
resolutions = [1 2 4 8];

% Attempt to load the atlas
atlas = LoadAtlas(config.ATLAS_FILE);

%% Start scanning for archives
% Note beginning execution
Event(['autoCheckTomo beginning search of ', config.AUTO_INPUT_DIR, ...
    ' for patient archives']);

% Retrieve folder contents of input directory
folderList = dir(config.AUTO_INPUT_DIR);

% Shuffle random number generator seed
rng shuffle;

% Randomize order of folder list
folderList = folderList(randperm(size(folderList, 1)), :);

% Initialize folder counter
i = 0;

% Initialize plan counter
count = 0;

% Start AutoSystematicError timer
totalTimer = tic;

% Start recursive loop through each folder, subfolder
while i < size(folderList, 1)
    
    % Increment current folder being analyzed
    i = i + 1;
    
    % If the folder content is . or .., skip to next folder in list
    if strcmp(folderList(i).name, '.') || strcmp(folderList(i).name, '..')
        continue
        
    % Otherwise, if the folder content is a subfolder    
    elseif folderList(i).isdir == 1
        
        % Retrieve the subfolder contents
        subFolderList = dir(fullfile(config.AUTO_INPUT_DIR, ...
            folderList(i).name));
        
        % Randomize order of subfolder list
        subFolderList = subFolderList(randperm(size(subFolderList, 1)), :);
        
        % Look through the subfolder contents
        for j = 1:size(subFolderList, 1)
            
            % If the subfolder content is . or .., skip to next subfolder 
            if strcmp(subFolderList(j).name, '.') || ...
                    strcmp(subFolderList(j).name, '..')
                continue
            else
                
                % Otherwise, replace the subfolder name with its full
                % reference
                subFolderList(j).name = fullfile(folderList(i).name, ...
                    subFolderList(j).name);
            end
        end
        
        % Append the subfolder contents to the main folder list
        folderList = vertcat(folderList, subFolderList); %#ok<AGROW>
        
        % Clear temporary variable
        clear subFolderList;
        
    % Otherwise, if the folder content is a patient archive
    elseif size(strfind(folderList(i).name, '_patient.xml'), 1) > 0
        
        % Generate a SHA1 signature for the archive patient XML file using
        % the shasum system command on Unix/Mac, or sha1sum on Windows
        % (provided as part of this repository)
        if ispc
            [~, cmdout] = system(['sha1sum "', ...
                fullfile(config.AUTO_INPUT_DIR, folderList(i).name), '"']);
        else
            [~, cmdout] = system(['shasum "', ...
                fullfile(config.AUTO_INPUT_DIR, folderList(i).name), '"']);
        end
        
        % Save just the 40-character signature
        sha = cmdout(1:40);
        
        % Log patient XML and SHA1 signature
        Event(['Found patient archive ', folderList(i).name, ...
            ' with SHA1 signature ', sha]);
        
        % Clear temporary variable
        clear cmdout;

        % Generate separate path and names for XML
        [path, name, ext] = ...
            fileparts(fullfile(config.AUTO_INPUT_DIR, folderList(i).name));
        name = strcat(name, ext);
        
        % Clear temporary variable
        clear ext;
        
        % Search for and load all approvedPlans in the archive
        approvedPlans = FindPlans(path, name, 'Helical');
        
        % Loop through each plan
        Event('Looping through each approved plan');
        for j = 1:size(approvedPlans, 1)
            
            % Initialize flag to indicate whether the current plan
            % already contains contents in AUTO_RESULTS_CSV
            found = false;
            
            % If the results .csv exists and was loaded above
            if exist('results', 'var')
                
                % Loop through each result
                for k = 2:size(results{1},1)
                    
                    % If the XML SHA1 signature, plan UID, calc method, & 
                    % versions match
                    if strcmp(results{2}{k}, sha) && ...
                            strcmp(results{3}{k}, approvedPlans{j,1}) && ...
                            strcmp(results{4}{k}, ...
                            methods{config.DEFAULT_CALC_METHOD}) && ...
                            strcmp(results{14}{k}, version)
                        
                        % Set the flag to true, since a match was found
                        found = true;
                        
                        % Break the loop to stop searching
                        break;
                    end
                end
                
                % Clear temporary variable
                clear k;
            end
            
            % If results do not exist for this daily image
            if ~found

                % Attempt to run second dose calculation
                try 
                    % Log start
                    Event(sprintf(['Executing CheckTomo workflow', ...
                        ' on plan UID %s'], approvedPlans{j,1}));
                    
                    %% Load Reference Data
                    % Load the plan
                    refPlan = LoadPlan(path, name, approvedPlans{j,1});
                    
                    % Load the planning CT
                    refImage = LoadImage(path, name, approvedPlans{j,1});
                    
                    % Load the structure set
                    refImage.structures = LoadStructures(path, name, ...
                        refImage, atlas);
                    
                    % Find structure category
                    category = FindCategory(refImage.structures, atlas);
                    
                    % Load the reference dose
                    refDose = LoadPlanDose(path, name, approvedPlans{j,1});
                    
                    % Write reference DVH to .csv file
                    WriteDVH(refImage, refDose, fullfile(...
                        config.AUTO_DVH_DIR, strcat(approvedPlans{j,1}, ...
                        '_REFERENCE.csv')));
                    
                    % If DICOM flag is set, save DICOM images
                    if str2double(config.AUTO_SAVE_DICOM) == 1

                        % Make CT folder unless it already exists
                        if ~isdir(fullfile(config.AUTO_DICOM_DIR, ...
                                approvedPlans{j,1}))
                            mkdir(fullfile(config.AUTO_DICOM_DIR, ...
                                approvedPlans{j,1}));
                        end 
                        
                        % If anon is TRUE, alter the patient's identifying
                        % fields
                        if str2double(config.AUTO_ANON_RESULTS) == 1
                            refPlan.patientName = ...
                                ['ANON', sprintf('%i', floor(rand()*100000))];
                            refPlan.patientID = ...
                                sprintf('%i', floor(rand()*100000000));
                            refPlan.patientBirthDate = '';
                            refPlan.patientSex = '';
                            refPlan.patientAge = '';
                        end
                        
                        % Store series and study descriptions
                        refPlan.seriesDescription = 'reference';
                        refPlan.studyDescription = refPlan.planLabel;

                        % Store patient position from image
                        refPlan.position = refImage.position;

                        % Generate study and series UIDs
                        refPlan.studyUID = dicomuid;
                        refPlan.seriesUID = dicomuid;

                        % Generate unique FOR instance UID
                        refPlan.frameRefUID = dicomuid; 

                        % Write images to file, storing image UIDs
                        refPlan.instanceUIDs = WriteDICOMImage(refImage, ...
                            fullfile(config.AUTO_DICOM_DIR, ...
                            approvedPlans{j,1}, 'CT'), refPlan);
                        
                        % Write structure set to file, storing UID
                        refPlan.structureSetUID = WriteDICOMStructures(...
                            refImage.structures, fullfile(...
                            config.AUTO_DICOM_DIR, ...
                            approvedPlans{j,1}, 'RTStruct.dcm'), refPlan);
                        
                        % Write RT plan to file, storing UID
                        refPlan.planUID = WriteDICOMTomoPlan(refPlan, ...
                            fullfile(config.AUTO_DICOM_DIR, ...
                            approvedPlans{j,1}, 'RTPlan_REFERENCE.dcm'));
                        
                        % Write dose to file
                        WriteDICOMDose(refDose, fullfile(...
                            config.AUTO_DICOM_DIR, approvedPlans{j,1}, ...
                            'RTDose_REFERENCE.dcm'), refPlan);
                    end
                    
                    %% Calculate Dose
                    % Get the downsampling option
                    downsample = ...
                        resolutions(str2double(config.DEFAULT_RESOLUTION));
                    
                    % If the user chose to use MATLAB
                    if strcmpi(method(1:6), 'MATLAB')
                        
                        % Parse out the supersampling option
                        if length(method) > 10 && ...
                                strcmp(method(end-10:end), 'supersample')
                            supersample = 3;
                        else
                            supersample = 1;
                        end
                    
                        % Set reference dose rate option (default to 8.5 
                        % Gy/min if not present)
                        if isfield(config, 'MATLAB_DOSE_RATE')
                            doserate = ...
                                str2double(config.MATLAB_DOSE_RATE);
                        else
                            doserate = 8.5;
                        end   
                        
                        % Start calculation pool, if configured
                        try
                            if isfield(config, 'MATLAB_POOL') && ...
                                    isempty(gcp('nocreate'))

                                % Start calculation pool
                                pool = ...
                                    parpool(str2double(config.MATLAB_POOL));
                            else

                                % Store current value
                                pool = gcp;
                            end

                        % If the parallel processing toolbox is not 
                        % present, the above code will fail
                        catch
                            pool = [];
                        end
                        
                        % Start timer
                        calcTimer = tic;

                        % Execute dose calculation
                        secDose = CheckTomoDose(refImage, refPlan, pool, ...
                            'downsample', downsample, 'reference_doserate', ...
                            doserate, 'num_of_subprojections', ...
                            supersample, 'outside_body', ...
                            str2double(config.MATLAB_OUTSIDE_BODY), ...
                            'density_threshold', ...
                            str2double(config.MATLAB_DENSITY_THRESH), 'mask', ...
                            refDose.data > ...
                            (str2double(config.DOSE_THRESHOLD) - 0.05) * ...
                            max(max(max(refDose.data))));
                        
                    % Otherwise, if the user chose GPUSADOSE/SADOSE
                    elseif strcmpi(method(1:9), 'GPUSADOSE') ...
                            || strcmpi(method(1:6), 'SADOSE')

                        % Parse out the GPU/CPU options
                        c = regexp(method, 'GPU');

                        % Set parameters for GPU fast option
                        if ~isempty(c) && ~strcmpi(method(end-3:end), 'full')
                            supersample = 0;
                            azimuths = 4;
                            raysteps = 1;
                            sadose = 0;

                        % Set parameters for GPU full option
                        elseif ~isempty(c)
                            supersample = 1;
                            azimuths = 16;
                            raysteps = 1.5;
                            sadose = 0;

                        % Set parameters for CPU fast option
                        else
                            supersample = 0;
                            azimuths = 4;
                            raysteps = 1;
                            sadose = 1;
                        end
                        
                        % Start timer
                        calcTimer = tic;

                        % Execute dose calculation
                        secDose = CalcDose(refImage, refPlan, 'downsample', ...
                            downsample, 'supersample', supersample, ...
                            'azimuths', azimuths, 'sadose', sadose, ...
                            'raysteps', raysteps, 'modelfolder', ...
                            config.MODEL_PATH);
 
                    % Otherwise, an unknown method was passed
                    else
                        Event(['An unknown dose calculation option ', ...
                            'was chosen'], 'ERROR');
                    end
                    
                    % Stop timer and store computation time
                    calcTime = toc(calcTimer);
                    
                    % Write modified DVH to .csv file
                    WriteDVH(refImage, secDose, fullfile(config.AUTO_DVH_DIR, ...
                        strcat(approvedPlans{j,1}, '_', method, '.csv')));

                    % If DICOM flag is set, save DICOM images
                    if str2double(config.AUTO_SAVE_DICOM) == 1

                        % Copy plan
                        secPlan = refPlan;
                        
                        % Store series and study descriptions
                        secPlan.seriesDescription = method;
                        secPlan.studyDescription = refPlan.planLabel;

                        % Store patient position from image
                        secPlan.position = refPlan.position;

                        % USe same study and series UIDs
                        secPlan.studyUID = refPlan.studyUID;
                        secPlan.seriesUID = refPlan.seriesUID;

                        % Use same FOR instance UID
                        secPlan.frameRefUID = refPlan.frameRefUID;

                        % Store image UIDs from refPlan
                        secPlan.instanceUIDs = refPlan.instanceUIDs;

                        % Store structure set UID from refPlan
                        secPlan.structureSetUID = ...
                            refPlan.structureSetUID;

                        % Write RT plan to file, storing UID
                        secPlan.planUID = WriteDICOMTomoPlan(secPlan, ...
                            fullfile(config.AUTO_DICOM_DIR, approvedPlans{j,1}, ...
                            ['RTPlan_', method, '.dcm']));

                        % Write dose to file
                        WriteDICOMDose(secDose, fullfile(config.AUTO_DICOM_DIR, ...
                            approvedPlans{j,1}, ['RTDose_', method, '.dcm']), secPlan);
                    end
                    
                    % Store dose difference
                    diff = secDose.data - refDose.data;

                    % Crop differences where second calc is zero
                    diff(secDose.data == 0) = 0;

                    % Compute local or global relative difference based on 
                    % local Gamma setting
                    if str2double(config.GAMMA_LOCAL) == 0
                        diff = diff / max(max(max(refDose.data)));
                    else
                        diff = diff ./ refDose.data;
                    end

                    % Apply threshold and store mean difference 
                    meandiff = sum(diff(refDose.data > ...
                        str2double(config.DOSE_THRESHOLD) * ...
                        max(max(max(refDose.data))))) / ...
                        sum(reshape(refDose.data > ...
                        str2double(config.DOSE_THRESHOLD) * ...
                        max(max(max(refDose.data))), 1, []));
                    
                    %% Calculate Gamma
                    % Execute CalcGamma using restricted 3D search
                    gamma = CalcGamma(refDose, ...
                        secDose, str2double(config.GAMMA_PERCENT), ...
                        str2double(config.GAMMA_DTA_MM), ...
                        'local', str2double(config.GAMMA_LOCAL), 'refval', ...
                        max(max(max(refDose.data))), 'restrict', 1);

                    % Crop Gamma indices where second calc is zero
                    gamma(secDose.data == 0) = 0;

                    % Eliminate gamma values below dose threshold
                    gamma = gamma .* ...
                        (refDose.data > str2double(config.GAMMA_THRESHOLD) * ...
                        max(max(max(refDose.data))));

                    % Store mean gamma 
                    meangamma = sum(reshape(gamma, 1, [])) / ...
                        sum(reshape(refDose.data > ...
                        str2double(config.GAMMA_THRESHOLD) * ...
                        max(max(max(refDose.data))), 1, []));

                    % Store pass rate
                    passgamma = 1 - sum(reshape(gamma, 1, []) > 1) / ...
                        sum(reshape(refDose.data > ...
                        str2double(config.GAMMA_THRESHOLD) * ...
                        max(max(max(refDose.data))), 1, []));

                    %% Append Results
                    % Open append file handle to results .csv
                    fid = fopen(config.AUTO_RESULTS_CSV, 'a');

                    % If anon is TRUE, do not store the XML name and 
                    % location in column 1
                    if str2double(config.AUTO_ANON_RESULTS) == 1
                        
                        % Instead, replace with 'ANON'
                        fprintf(fid,'ANON,'); %#ok<*UNRCH>
                    else
                        
                        % Otherwise, write relative path location 
                        fprintf(fid, '%s,', ...
                            strrep(folderList(i).name, ',', ''));
                    end
                    
                    % Write XML SHA1 signature in column 2
                    fprintf(fid, '%s,', sha);
                    
                    % Write plan UID in column 3
                    fprintf(fid, '%s,', approvedPlans{j,1});
                    
                    % Write plan name in column 4
                    fprintf(fid, '%s,', strrep(refPlan.planLabel, ',', ' '));
                    
                    % Write plan category in column 5.  See FindCategory
                    fprintf(fid, '%s,', category);
                    
                    % Write the number of structures in column 6
                    fprintf(fid, '%i,', ...
                        size(refImage.structures, 2));
                    
                    % Write field width in column 7
                    fprintf(fid, '%0.1f,', sum(abs([refPlan.frontField ...
                        refPlan.backField])));
                    
                    % Write calculation method in column 8
                    fprintf(fid, '%s,', method);
                        
                    % Write calculation time in column 9
                    fprintf(fid, '%f,', calcTime);
                    
                    % Write dose grid resolution in column 10
                    fprintf(fid, '%f,', refImage.width(1) * downsample);
                    
                    % Write mean dose difference in column 11
                    fprintf(fid, '%f,', meandiff);
                    
                    % Write Gamma pass rate in column 12
                    fprintf(fid, '%f,', passgamma);
                    
                    % Write mean Gamma index in column 13
                    fprintf(fid, '%f,', meangamma);
                    
                    % Write version in column 14
                    fprintf(fid, '%s\n', version);
                    
                    % Close file handle
                    fclose(fid);
                    
                    % Clear temporary variables
                    clear fid calcTime calcTimer category diff doserate ...
                        downsample found gamma meandiff meangamma ...
                        passgamma refDose refImage refPlan secDose ...
                        secPlan supersample azimuths raysteps sadose;
                    
                    % Increment the count of processed images
                    count = count + 1;
                    
                % If an error is thrown, catch
                catch exception
                    
                    % Report exception to error log
                    Event(getReport(exception, 'extended', 'hyperlinks', ...
                        'off'), 'CATCH');
                   
                    % Continue to next image set
                    continue;
                end
            else
                
                % Otherwise, matching data was found in AUTO_RESULTS_CSV
                Event(['UID ', approvedPlans{j,1}, ...
                    ' skipped as results were found in ', ...
                    config.AUTO_RESULTS_CSV]);
            end
        end
        
        % Clear temporary variables
        clear path name approvedPlans sha;
    end 
end

% Log completion of script
Event(sprintf(['autoCheckTomo completed in %0.0f minutes, ', ...
    'processing %i plans'], toc(totalTimer)/60, count));

% Clear temporary variables
clear i j totalTimer count;