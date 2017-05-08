function table = UpdateResults(handles)
% UpdateResults is called by CheckTomo.m after new plan is loaded.  See 
% below for more information on the statistics computed.
%
% The following variables are required for proper execution: 
%   handles: structure containing the data variables used for statistics 
%       computation. This will typically be the guidata (or data structure,
%       in the case of PrintReport).
%
% The following variables are returned upon succesful completion:
%   table: cell array of table values, for use in updating a GUI table.
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
    
% Log start
Event('Updating results table');
tic;

% Initialize empty table
table = cell(1,2);

% Initialize row counter
c = 0;

% Patient name
c = c + 1;
table{c,1} = 'Patient Name';
if isfield(handles, 'plan') && isfield(handles.plan, 'patientName')   
    table{c,2} = handles.plan.patientName;
else
    table{c,2} = '';
end

% Patient ID
c = c + 1;
table{c,1} = 'Patient ID';
if isfield(handles, 'plan') && isfield(handles.plan, 'patientID')   
    table{c,2} = handles.plan.patientID;
else
    table{c,2} = '';
end

% Machine
c = c + 1;
table{c,1} = 'Machine';
if isfield(handles, 'plan') && isfield(handles.plan, 'machine')   
    table{c,2} = handles.plan.machine;
else
    table{c,2} = '';
end

% Plan name
c = c + 1;
table{c,1} = 'Plan Name';
if isfield(handles, 'plan') && isfield(handles.plan, 'planLabel')   
    table{c,2} = handles.plan.planLabel;
else
    table{c,2} = '';
end

% Prescription
c = c + 1;
table{c,1} = 'Prescription';
if isfield(handles, 'plan') && isfield(handles.plan, 'rxDose')   
    table{c,2} = sprintf('%0.1f%% to %0.1f Gy in %i fractions', ...
        handles.plan.rxVolume, handles.plan.rxDose, ...
        handles.plan.fractions);
else
    table{c,2} = '';
end

% Plan date
c = c + 1;
table{c,1} = 'Approved Date';
if isfield(handles, 'plan') && isfield(handles.plan, 'timestamp')   
    table{c,2} = datestr(handles.plan.timestamp, 'mmm dd, yyyy HH:MM:SS AM');
else
    table{c,2} = '';
end

% Position
c = c + 1;
table{c,1} = 'Patient Position';
if isfield(handles, 'referenceImage') && ...
        isfield(handles.referenceImage, 'position')   
    table{c,2} = handles.referenceImage.position;
else
    table{c,2} = '';
end


% Plan type
c = c + 1;
table{c,1} = 'Plan Type';
if isfield(handles, 'plan') && isfield(handles.plan, 'planType')   
    table{c,2} = handles.plan.planType;
else
    table{c,2} = '';
end

% Field width
c = c + 1;
table{c,1} = 'Field Width';
if isfield(handles, 'plan') && isfield(handles.plan, 'frontField')   
    table{c,2} = sprintf('%0.1f cm', sum(abs([handles.plan.frontField ...
        handles.plan.backField])));
else
    table{c,2} = '';
end

% Pitch
c = c + 1;
table{c,1} = 'Pitch';
if isfield(handles, 'plan') && isfield(handles.plan, 'pitch')   
    table{c,2} = sprintf('%0.3f', handles.plan.pitch);
else
    table{c,2} = '';
end

% Calculation Time
c = c + 1;
table{c,1} = 'Calculation Time';
if isfield(handles, 'doseStats') && isfield(handles.doseStats, 'calctime')   
    table{c,2} = sprintf('%i minutes, %0.1f seconds', ...
        floor(handles.doseStats.calctime/60), ...
        mod(handles.doseStats.calctime, 60));
else
    table{c,2} = '';
end

% Calculation Time
c = c + 1;
table{c,1} = 'Dose Grid';
if isfield(handles, 'doseStats') && isfield(handles.doseStats, 'gridSize')   
    table{c,2} = sprintf('%0.1f mm x %0.1f mm x %0.1f mm', ...
        handles.doseStats.gridSize * 10);
else
    table{c,2} = '';
end

% Mean Dose Difference
c = c + 1;
table{c,1} = sprintf('Mean Dose Difference (>%0.0f%%)', ...
    str2double(handles.config.DOSE_THRESHOLD) * 100);
if isfield(handles, 'doseStats') && isfield(handles.doseStats, 'meandiff')   
    table{c,2} = sprintf('%0.2f%%', handles.doseStats.meandiff * 100);
else
    table{c,2} = '';
end

% Gamma Pass Rate
c = c + 1;
table{c,1} = sprintf('Gamma Pass Rate (>%0.0f%%)', ...
    str2double(handles.config.GAMMA_THRESHOLD) * 100);
if isfield(handles, 'doseStats') && isfield(handles.doseStats, 'passgamma')   
    table{c,2} = sprintf('%0.1f%%', handles.doseStats.passgamma * 100);
else
    table{c,2} = '';
end

% Mean Gamma
c = c + 1;
table{c,1} = sprintf('Mean Gamma Index (>%0.0f%%)', ...
    str2double(handles.config.GAMMA_THRESHOLD) * 100);
if isfield(handles, 'doseStats') && isfield(handles.doseStats, 'meangamma')   
    table{c,2} = sprintf('%0.3f', handles.doseStats.meangamma);
else
    table{c,2} = '';
end

% Log completion
Event(sprintf(['Results table updated successfully in %0.3f', ...
    ' seconds'], toc));