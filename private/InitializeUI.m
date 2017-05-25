function handles = InitializeUI(handles)
% InitializeUI is called by CheckTomo when the interface is opened to set
% all UI fields.
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

% Set version UI text
set(handles.version_text, 'String', ['Version ', handles.version]);

% Set default transparency
set(handles.alpha, 'String', handles.config.DEFAULT_TRANSPARENCY);

% Execute SetDoseCalcOptions to determine what calculation options to use
handles = SetDoseCalcOptions(handles);

% Set calculation options
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
set(handles.gamma_text, 'String', sprintf('%0.1f%%/%0.1f mm', ...
    str2double(handles.config.GAMMA_PERCENT), ...
    str2double(handles.config.GAMMA_DTA_MM)));
set(handles.gamma_text, 'enable', 'off');
set(handles.local_menu, 'String', {'Global', 'Local'});
set(handles.local_menu, 'Value', str2double(handles.config.GAMMA_LOCAL)+1);
set(handles.local_menu, 'enable', 'off');
if str2double(handles.config.GAMMA_LOCAL) == 0
    Event(sprintf('Gamma criteria set to %0.1f%%/%0.1f mm global', ...
        str2double(handles.config.GAMMA_PERCENT), ...
        str2double(handles.config.GAMMA_DTA_MM)));
else
    Event(sprintf('Gamma criteria set to %0.1f%%/%0.1f mm local', ...
        str2double(handles.config.GAMMA_PERCENT), ...
        str2double(handles.config.GAMMA_DTA_MM)));
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