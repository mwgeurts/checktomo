function handles = ParseGammaCriteria(handles, string)
% ParseGammaCriteria is called by CheckTomo when the user edits the Gamma
% criteria input box. It determines whether or not it can parse the new
% value, reformatting it upon success and reverting to the default values
% on failure.
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

% Retrieve Gamma criteria
c = strsplit(string, '/');

% If the user didn't include a /
if length(c) < 2

    % Throw a warning
    Event(['When entering Gamma criteria, you must provide the ', ...
        'form ##%/## mm'], 'WARN');
    
    % Display a message box
    msgbox(['When entering Gamma criteria, you must provide the ', ...
        'form ##%/## mm']);
    
    % Reset the gammav
    set(handles.gamma_text, 'String', sprintf('%0.1f%%/%0.1f mm', ...
        str2double(handles.config.GAMMA_PERCENT), ...
        str2double(handles.config.GAMMA_DTA_MM)));

% Otherwise two values were found
else
    
    % Parse values
    set(handles.gamma_text, 'String', sprintf('%0.1f%%/%0.1f mm', ...
        str2double(regexprep(c{1}, '[^\d\.]', '')), ...
        str2double(regexprep(c{2}, '[^\d\.]', ''))));
    
    % Log change
    Event(['Gamma criteria set to ', get(handles.gamma_text, 'String')]);
end

% Clear temporary variables
clear c;