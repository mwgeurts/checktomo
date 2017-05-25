function handles = SetDoseCalcOptions(handles)
% SetDoseCalcOptions is executed by CheckTomo to determine what calculation
% options are available. This tool will default to MATLAB commands only.
% However, if the corresponding GPU configuration options are set, and the
% tool can find a valid standalone calculation executable (either locally
% or on a remote server), the tool will add GPU options.
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

% Set initial dose calculation options (only MATLAB)
handles.methods = {
    'MATLAB Dose Calculator (no supersampling)'
    'MATLAB Dose Calculator (supersampling)'
};

% Test for connection to Standalone calculator
handles.gpudose = 0;

% Declare path to beam model folder (if not specified in config file, use
% default path of ./GPU)
if isfield(handles.config, 'MODEL_PATH')
    handles.modeldir = handles.config.MODEL_PATH;
else
    handles.modeldir = './model';
end

% Check for beam model files
if exist(fullfile(handles.modeldir, 'dcom.header'), 'file') == 2 && ...
        exist(fullfile(handles.modeldir, 'fat.img'), 'file') == 2 && ...
        exist(fullfile(handles.modeldir, 'kernel.img'), 'file') == 2 && ...
        exist(fullfile(handles.modeldir, 'lft.img'), 'file') == 2 && ...
        exist(fullfile(handles.modeldir, 'penumbra.img'), 'file') == 2

    % Log name
    Event('Beam model files verified for standalone calculator');
    
    % Check for presence of dose calculator
    handles.gpudose = CalcDose();
    
    % If calc dose was successful
    if handles.gpudose == 1

        % Log dose calculation status
        Event('Standalone GPU Dose calculation available');

        % Add GPU options
        handles.methods{length(handles.methods)+1} = ...
            'Standalone GPU Dose Calculator (fast)';
        handles.methods{length(handles.methods)+1} = ...
            'Standalone GPU Dose Calculator (full)';
        handles.methods{length(handles.methods)+1} = ...
            'Standalone CPU Dose Calculator';

    % Otherwise, calc dose was not successful
    else

        % Log dose calculation status
        Event('Standalone dose calculation engine not available', 'WARN');
        
        % Store status
        handles.gpudose = 0;
    end
else

    % Store status
    handles.gpudose = 0;

    % Throw a warning
    Event(sprintf(['Standalone dose calculation disabled, beam model ', ...
        'not found. Verify that %s exists and contains the necessary ', ...
        'model files'], handles.modeldir), 'WARN');
end