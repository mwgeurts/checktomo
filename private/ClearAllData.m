function handles = ClearAllData(handles)
% ClearAllData clears all data and resets all UI components in CheckTomo. 
% This function is also called during program initialization to set up the 
% interface and all internal variables.
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

% Log action
Event('Resetting all variables and clearing display');

% Clear/initialize non-UI variables
handles.plans = [];
handles.plan = [];
handles.planuid = [];
handles.referenceImage = [];
handles.mergedImage = [];
handles.referenceDose = [];
handles.secondDose = [];
handles.doseStats = [];
handles.gamma = [];

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
if isfield(handles, 'dvh')
    delete(handles.dvh);
else
    set(handles.struct_table, 'Data', cell(16,6));
    set(allchild(handles.dvh_axes), 'visible', 'off'); 
    set(handles.dvh_axes, 'visible', 'off');
end
set(handles.line_axes, 'visible', 'off');
set(allchild(handles.line_axes), 'visible', 'off'); 
legend(handles.line_axes, 'off');

% Disable sliders/alpha
set(handles.line_slider, 'visible', 'off');
set(handles.alpha, 'visible', 'off');

% Clear results table
set(handles.stats_table, 'Data', UpdateResults(handles));

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