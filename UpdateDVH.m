function varargout = UpdateDVH(varargin)
% UpdateDVH computes a Dose Volume Histogram (DVH) for reference and DQA 
% dose arrays given a structure set and plots it in a provided figure 
% handle.  It can be called repeatedly, either will a full dataset, new 
% dose, or just new statistics (such as when hiding/showing a
% structure).  As described below, either 1, 4, or 6 input arguments are
% required for execution.
%
% The dose volume histogram is plotted as a relative volume cumulative dose
% histogram, with each structure plotted as a solid line for the reference
% dose and dashed line for the DQA dose in the color specified in the
% structure array.  The stats cell array column 2 is used to determine
% whether a structure is displayed (true) or not (false).
%
% The following variables are required for proper execution: 
%   fig (optional): figure handle in which to display the DVH.  If not
%       provided, the figure handle from the previous call is used.
%   stats: cell array, with a logical value in column 2 for each structure
%       in referenceImage.structures to specify whether to display that DVH
%   referenceImage (optional): structure contianing structures, start,
%       data, and width fields. See LoadReferenceImage and
%       LoadReferenceStructures for more detail. If not provided, the
%       structure from the previous call is used.
%   referenceDose (optional): structure with the reference dose information
%       containing data, start, and width fields. See LoadReferenceDose
%       for more detail.  If not provided, the structure from the previous 
%       call is used.
%   newImage (optional): structure with the DQA dose information
%       containing structure, data, start, and width fields.  If not 
%       provided, the structure from the previous call is used (if
%       available) or the DQA DVH is not computed
%   newDose (optional): structure with the DQA dose information containing 
%       data, start, and width fields.  If not provided, the structure from 
%       the previous call is used (if available) or the DQA DVH is not 
%       computed
%
% The following variables are returned upon succesful completion:
%   referenceDVH: a 1001 by n+1 array of cumulative DVH values for n
%       structures where n+1 is the x-axis value (separated into 1001 bins)
%   newDVH (optional): a 1001 by n+1 array of cumulative DVH values for n
%       structures where n+1 is the x-axis value (separated into 1001 bins)
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
    
% Declare persistent variables to store data between UpdateDVH calls
persistent fig referenceImage referenceDose newImage newDose ...
    storedReferenceDVH storednewDVH maxdose;

% Declare the number of bins
nbins = 1000;

% Run in try-catch to log error via Event.m
try

% Log start of DVH computation and start timer
Event('Computing dose volume histograms');
tic;

%% Configure input variables
% If only one argument is provided, use stored DVH data and update plot
% based on new stats array
if nargin == 1
    stats = varargin{1};
    
    % If stored reference data exists
    if ~isempty(storedReferenceDVH)
        referenceDVH = storedReferenceDVH;
    end
    
    % If stored DQA data exosts
    if ~isempty(storednewDVH)
        newDVH = storednewDVH;
    end
    
% Otherwise, if four arguments are provided, compute just refernce data
elseif nargin == 4
    fig = varargin{1};
    stats = varargin{2};
    referenceImage = varargin{3};
    referenceDose = varargin{4};
    
% Otherwise, if six arguments are provided, compute both new reference and
% dqa DVHs
elseif nargin == 6
    fig = varargin{1};
    stats = varargin{2};
    referenceImage = varargin{3};
    referenceDose = varargin{4};
    newImage = varargin{5};
    newDose = varargin{6};

% Otherwise, an incorrect number of arguments were given, so throw an error
else
    Event('An incorrect number of arguments were passed to UpdateDVH', ...
        'ERROR');
end

%% Compute reference DVH
% If a new reference image was passed, resample to image dimensions
if nargin >= 4
    
    % If the referenceDose variable contains a valid data array
    if isfield(referenceDose, 'data') && size(referenceDose.data, 1) > 0
        
        % If the image size, pixel size, or start differs between datasets
        if size(referenceDose.data,1) ~= size(referenceImage.data,1) ...
                || size(referenceDose.data,2) ~= size(referenceImage.data,2) ...
                || size(referenceDose.data,3) ~= size(referenceImage.data,3) ...
                || isequal(referenceDose.width, referenceImage.width) == 0 ...
                || isequal(referenceDose.start, referenceImage.start) == 0
            
            % Create 3D mesh for reference image
            [refX, refY, refZ] = meshgrid(referenceImage.start(2) + ...
                referenceImage.width(2) * size(referenceImage.data, 2):...
                -referenceImage.width(2):referenceImage.start(2), ...
                referenceImage.start(1):referenceImage.width(1):...
                referenceImage.start(1) + referenceImage.width(1) * ...
                size(referenceImage.data,1), referenceImage.start(3):...
                referenceImage.width(3):referenceImage.start(3) + ...
                referenceImage.width(3) * size(referenceImage.data, 3));

            % Create GPU 3D mesh for secondary dataset
            [secX, secY, secZ] = meshgrid(referenceDose.start(2) + ...
                referenceDose.width(2) * size(referenceDose.data, 2):...
                -referenceDose.width(2):referenceDose.start(2), ...
                referenceDose.start(1):referenceDose.width(1):...
                referenceDose.start(1) + referenceDose.width(1) * ...
                size(referenceDose.data, 1), referenceDose.start(3):...
                referenceDose.width(3):referenceDose.start(3) + ...
                referenceDose.width(3) * size(referenceDose.data, 3));
            
            % Attempt to use GPU to interpolate dose to image/structure
            % coordinate system.  If a GPU compatible device is not
            % available, any errors will be caught and CPU interpolation
            % will be used instead.
            try
                % Initialize and clear GPU memory
                gpuDevice(1);

                % Interpolate the dose to the reference coordinates using
                % GPU linear interpolation, and store back to 
                % referenceDose.data
                referenceDose.data = gather(interp3(gpuArray(secX), ...
                    gpuArray(secY), gpuArray(secZ), ...
                    gpuArray(referenceDose.data), gpuArray(refX), ...
                    gpuArray(refY), gpuArray(refZ), 'linear', 0));
                
                % Clear GPU memory
                gpuDevice(1);
                
            % Catch any errors that occured and attempt CPU interpolation
            % instead
            catch
                % Interpolate the dose to the reference coordinates using
                % linear interpolation, and store back to referenceDose.data
                referenceDose.data = interp3(secX, secY, secZ, ...
                    referenceDose.data, refX, refY, refZ, '*linear', 0);
            end
            
            % Clear temporary variables
            clear refX refY refZ secX secY secZ;
        end
        
        % Store the maximum value in the reference dose
        maxdose = max(max(max(referenceDose.data)));
    
        % Initialize array for reference DVH values with 1001 bins
        referenceDVH = zeros(nbins + 1, ...
            length(referenceImage.structures) + 1);
        
        % Defined the last column to be the x-axis, ranging from 0 to the
        % maximum dose
        referenceDVH(:, length(referenceImage.structures) + 1) = ...
            0:maxdose/nbins:maxdose;

        % Loop through each reference structure
        for i = 1:length(referenceImage.structures)
            
            % If valid reference dose data was passed
            if isfield(referenceDose, 'data') && ...
                    size(referenceDose.data,1) > 0
                
                % Multiply the dose by the structure mask and reshape into
                % a vector (adding 1e-6 is necessary to retain zero dose
                % values inside the structure mask)
                data = reshape((referenceDose.data + 1e-6) .* ...
                    referenceImage.structures{i}.mask, 1, []);
                
                % Remove all zero values (basically, voxels outside of the
                % structure mask
                data(data==0) = [];

                % Compute cumulative histogram
                referenceDVH(1:nbins,i) = 1 - histcounts(data, ...
                    referenceDVH(:, length(referenceImage.structures) + 1), ...
                    'Normalization', 'cdf')';
                
                % Normalize histogram to relative volume
                referenceDVH(:,i) = referenceDVH(:,i) / ...
                    max(referenceDVH(:,i)) * 100;
                
                % Clear temporary variable
                clear data;
            end
        end
        
        % Save reference DVH as persistent variable
        storedReferenceDVH = referenceDVH;
        
        % Return DVH data
        varargout{1} = referenceDVH;
        
        % Clear temporary variable
        clear maxdose;
    end
end

%% Compute DQA DVH
% If new DQA dose data was passed
if nargin >= 6
    
    % If the newDose variable contains a valid data array
    if isfield(newDose, 'data') && size(newDose.data,1) > 0
        
        % If the image size, pixel size, or start differs between datasets, 
        % or a registration adjustment exists
        if size(newDose.data,1) ~= size(newImage.data,1) ...
                || size(newDose.data,2) ~= size(newImage.data,2) ...
                || size(newDose.data,3) ~= size(newImage.data,3) ...
                || isequal(newDose.width, newImage.width) == 0 ...
                || isequal(newDose.start, newImage.start) == 0

            % Create 3D mesh for DQA image
            [refX, refY, refZ] = meshgrid(newImage.start(2) + ...
                newImage.width(2) * size(newImage.data, 2):...
                -newImage.width(2):newImage.start(2), ...
                newImage.start(1):newImage.width(1):...
                newImage.start(1) + newImage.width(1) * ...
                size(newImage.data,1), newImage.start(3):...
                newImage.width(3):newImage.start(3) + ...
                newImage.width(3) * size(newImage.data, 3));

            % Create GPU 3D mesh for secondary dataset
            [secX, secY, secZ] = meshgrid(newDose.start(2) + ...
                newDose.width(2) * size(newDose.data, 2):...
                -newDose.width(2):newDose.start(2), ...
                newDose.start(1):newDose.width(1):...
                newDose.start(1) + newDose.width(1) * ...
                size(newDose.data, 1), newDose.start(3):...
                newDose.width(3):newDose.start(3) + ...
                newDose.width(3) * size(newDose.data, 3));
            
            % Attempt to use GPU to interpolate dose to image/structure
            % coordinate system.  If a GPU compatible device is not
            % available, any errors will be caught and CPU interpolation
            % will be used instead.
            try
                % Initialize and clear GPU memory
                gpuDevice(1);

                % Interpolate the dose to the reference coordinates using
                % GPU linear interpolation, and store back to 
                % newDose.data
                newDose.data = gather(interp3(gpuArray(secX), ...
                    gpuArray(secY), gpuArray(secZ), ...
                    gpuArray(newDose.data), gpuArray(refX), ...
                    gpuArray(refY), gpuArray(refZ), 'linear', 0));
                
                % Clear GPU memory
                gpuDevice(1);
                
            % Catch any errors that occured and attempt CPU interpolation
            % instead
            catch
                % Interpolate the dose to the reference coordinates using
                % linear interpolation, and store back to newDose.data
                newDose.data = interp3(secX, secY, secZ, ...
                    newDose.data, refX, refY, refZ, '*linear', 0);

            end
        end
        
        % Store the maximum value in the DQA dose
        maxdose = max(max(max(newDose.data)));

        % Initialize array for DQA DVH values with 1001 bins
        newDVH = zeros(nbins + 1, length(newImage.structures) + 1);
        
        % Defined the last column to be the x-axis, ranging from 0 to the
        % maximum dose
        newDVH(:, length(newImage.structures) + 1) = ...
            0:maxdose/nbins:maxdose;

        % Loop through each DQA structure
        for i = 1:length(newImage.structures) 
            
            % If valid DQA dose data was passed
            if isfield(newDose, 'data') && size(newDose.data, 1) > 0
                
                % Multiply the dose by the structure mask and reshape into
                % a vector (adding 1e-6 is necessary to retain zero dose
                % values inside the structure mask)
                data = reshape((newDose.data + 1e-6) .* ...
                    newImage.structures{i}.mask, 1, []);
                
                % Remove all zero values (basically, voxels outside of the
                % structure mask
                data(data==0) = [];
                
                % Compute cumulative histogram
                newDVH(1:nbins,i) = 1 - histcounts(data, ...
                    newDVH(:, length(newImage.structures) + 1), ...
                    'Normalization', 'cdf')';
                
                % Normalize histogram to relative volume
                newDVH(:,i) = newDVH(:,i) / ...
                    max(newDVH(:,i)) * 100;
                
                % Clear temporary variable
                clear data;
            end 
        end
        
        % Save DQA DVH as persistent variable
        storednewDVH = newDVH;
        
        % Return DVH
        varargout{2} = newDVH;
        
        % Clear temporary variable
        clear maxdose;
    end
end

%% Plot DVH
% Select image handle
axes(fig)

% Initialize flag to indicate when the first line is plotted
first = true;

% Loop through each structure 
for i = 1:length(referenceImage.structures)  
    
    % If the statistics display column is true/checked, plot the DVH
    if stats{i,2}
        
        % If the reference DVH contains a non-zero value
        if exist('referenceDVH', 'var') && max(referenceDVH(:,i)) > 0
            
            % Plot the reference dose as a solid line in the color
            % specified in the structures cell array
            plot(referenceDVH(:, length(referenceImage.structures) + 1), ...
                referenceDVH(:,i), '-', 'Color', ...
                referenceImage.structures{i}.color / 255);
           
            % If this was the first contour plotted
            if first
                
                % Disable the first flag
                first = false;
                
                % Hold the axes to allow overlapping plots
                hold on;
            end
        end
        
        % If the DQA DVH contains a non-zero value
        if exist('newDVH', 'var') && max(newDVH(:,i)) > 0  
            
            % Plot the reference dose as a solid line in the color
            % specified in the structures cell array
            plot(newDVH(:, length(newImage.structures) + 1), ...
                newDVH(:,i), '--', 'Color', ...
                newImage.structures{i}.color / 255);
        end
    end
end

% Clear temporary variables
clear first;

% Stop holding the plot
hold off;

% Turn on major gridlines
grid on;

% Set the y-axis limit between 0% and 100%
ylim([0 100]);

% Set x-axis label
xlabel('Dose (Gy)');

% Set y-axis label
ylabel('Cumulative Volume (%)');

% Log completion of function
Event(sprintf(['Dose volume histograms completed successfully in ', ...
    '%0.3f seconds'], toc));

% Catch errors, log, and rethrow
catch err
    Event(getReport(err, 'extended', 'hyperlinks', 'off'), 'ERROR');
end