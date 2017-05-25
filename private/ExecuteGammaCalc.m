function handles = ExecuteGammaCalc(handles)
% ExecuteGammaCalc is called by CheckTomo when the user clicks the 
% Calculate Gamma button. It retrieves the Gamma criteria from the UI and
% executes the CalcGamma submodule function.
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

% Update progress bar
progress = waitbar(0.1, 'Calculating Gamma...');

% Retrieve Gamma criteria
c = textscan(get(handles.gamma_text, 'String'), '%f%%/%f mm');

% Execute CalcGamma using restricted 3D search
handles.gamma = CalcGamma(handles.referenceDose, ...
    handles.secondDose, c{1}, c{2}, ...
    'local', str2double(get(handles.local_menu, 'Value'))-1, 'refval', ...
    max(max(max(handles.referenceDose.data))), 'restrict', 1);

% Crop Gamma indices where second calc is zero
handles.gamma(handles.secondDose.data == 0) = 0;

% Eliminate gamma values below dose threshold
handles.gamma = handles.gamma .* ...
    (handles.referenceDose.data > str2double(handles.config.GAMMA_THRESHOLD) * ...
    max(max(max(handles.referenceDose.data))));

% Store mean gamma 
handles.doseStats.meangamma = sum(reshape(handles.gamma, 1, [])) / ...
    sum(reshape(handles.referenceDose.data > ...
    str2double(handles.config.GAMMA_THRESHOLD) * ...
    max(max(max(handles.referenceDose.data))), 1, []));

% Store pass rate
handles.doseStats.passgamma = 1 - sum(reshape(handles.gamma, 1, []) > 1) / ...
    sum(reshape(handles.referenceDose.data > ...
    str2double(handles.config.GAMMA_THRESHOLD) * ...
    max(max(max(handles.referenceDose.data))), 1, []));

% Update progress bar
waitbar(0.9, progress, 'Updating statistics...');

% Execute UpdateTCSDisplay to update plots with gamma index
set(handles.tcs_menu, 'Value', 5);
handles = UpdateTCSDisplay(handles);

% Update results statistics
set(handles.stats_table, 'Data', UpdateResults(handles));

% Update struct table with Gamma pass rates
handles.dvh.UpdateTable('gamma', handles.gamma);

% Update line plot
handles = UpdateLineDisplay(handles, '0');

% Close progress bar
close(progress);

% Clear temporary variables
clear c;