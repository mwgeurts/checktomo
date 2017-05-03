function Update(obj, varargin)
% Update updates an image viewer object to a new slice or transparency.  
% Execution assumes that any overlay image is already aligned, either 
% before object construction or using the Initialize function. Updated
% slice, transparency, or structure view values can be passed as name/value 
% pair inputs to this function.
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

% Apply variable input arguments
for i = 1:2:length(varargin)
    
    % If the slice or transparency arguments were passed
    if strcmpi(varargin{i}, 'slice')
        obj.slice = varargin{i+1};
    elseif strcmpi(varargin{i}, 'alpha')
        obj.alpha = varargin{i+1};
    elseif strcmpi(varargin{i}, 'structuresonoff')
        obj.structuresonoff = varargin{i+1};
    end
end

% If zoom is enabled and the display is on
if strcmpi(obj.zoom, 'on')

    % Store current zoom/pan settings
    xlim = obj.axis.XLim;
    ylim = obj.axis.YLim;
end

%% Extract 2D image planar data
% Set image plane extraction based on tcsview variable
switch obj.tcsview
    
% If orientation is Transverse
case 'T'

    % Set imageA data based on the obj.background IEC-x and IEC-z dimensions
    imageA = obj.background.data(:,:, obj.slice);
    
    % Set image widths
    width = [obj.background.width(1) obj.background.width(2)];
    
    % Set image start values
    start = [obj.background.start(1) obj.background.start(2)];
    
    % If obj.overlay data exists
    if isstruct(obj.overlay)
    
        % Set imageB data based on the obj.overlay IEC-x and IEC-z dimensions
        imageB = obj.overlay.data(:,:,obj.slice);
    end
    
% If orientation is Coronal
case 'C'

    % Set imageA data based on the obj.background IEC-x and IEC-y dimensions
    imageA = obj.background.data(:,obj.slice,:);
    
    % Set image widths
    width = [obj.background.width(1) obj.background.width(3)];
    
    % Set image start values
    start = [obj.background.start(1) obj.background.start(3)];
    
    % If obj.overlay data exists
    if isstruct(obj.overlay)
    
        % Set imageB data based on the obj.overlay IEC-x and IEC-y dimensions
        imageB = obj.overlay.data(:,obj.slice,:);
    end
    
% If orientation is Sagittal
case 'S'    

    % Set imageA data based on the obj.background IEC-y and IEC-z dimensions
    imageA = obj.background.data(obj.slice,:,:);
    
    % Set image widths
    width = [obj.background.width(2) obj.background.width(3)];
    
    % Set image start values
    start = [obj.background.start(2) obj.background.start(3)];
    
    % If obj.overlay data exists
    if isstruct(obj.overlay)
    
        % Set imageB data based on the obj.overlay IEC-y and IEC-z dimensions
        imageB = obj.overlay.data(obj.slice,:,:);
    end
end

% Remove the extra dimension for imageA
imageA = squeeze(imageA)';

% Pad the image and calculate the start offsets
s = max(size(imageA') .* width);
offset = ((size(imageA') .* width) - s) / 2;

% Interpolate to center imageA, padding with zeros
imageA = interp2(imageA, (width(1):width(1):s) / width(1) + ((size(imageA,2) ...
    * width(1)) - s) / (2 * width(1)), (width(2):width(2):s)' / width(2) + ...
    ((size(imageA,1) * width(2)) - s) / (2 * width(2)), 'nearest', 0);

% If obj.overlay data exists
if isstruct(obj.overlay)

    % Remove the extra dimension for imageB
    imageB = squeeze(imageB)';
    
    % Interpolate to center imageA, padding with zeros
    imageB = interp2(imageB, (width(1):width(1):s) / width(1) + ((size(imageB,2) ...
        * width(1)) - s) / (2 * width(1)), (width(2):width(2):s)' / width(2) + ...
        ((size(imageB,1) * width(2)) - s) / (2 * width(2)), 'nearest', 0);
end

%% Plot 2D image data
% Select image handle
axes(obj.axis)

% Create reference object based on the start and width inputs (used for POI
% reporting)
switch obj.tcsview
case 'T'
    reference = imref2d(size(imageA), [start(1) + offset(1) start(1) + ...
        offset(1) + size(imageA,2) * width(1)], [-(start(2) - offset(2) + ...
        size(imageA,1) * width(2)) -start(2) + offset(2)]);
case 'C'
    reference = imref2d(size(imageA), [start(1) + offset(1) start(1) + ...
        offset(1) + size(imageA,2) * width(1)], [start(2) + offset(2) ...
        start(2) + offset(2) + size(imageA,1) * width(2)]);
case 'S'
    reference = imref2d(size(imageA), [-(start(1) + offset(1) + ...
        size(imageA,2) * width(1)) -start(1) - offset(1)], [start(2) + ...
        offset(2) start(2) + offset(2) + size(imageA,1) * width(2)]);
end

% If a secondary dataset was provided
if isstruct(obj.overlay)

    % If the image is an MR
    if isfield(obj.background, 'type') && strcmpi(obj.background.type, 'MR')
    
        % For two datasets, the reference image is converted to an RGB 
        % image prior to display. This will allow a non-grayscale colormap 
        % for the secondary dataset while leaving the underlying CT image 
        % grayscale. 
        imshow(ind2rgb(gray2ind((imageA) / obj.backgroundrange(2), 64), ...
            colormap('gray')), reference);
    
    % Otherwise, if CT, or no image type is provided
    else
    
        % For two datasets, the reference image is converted to an RGB 
        % image prior to display. This will allow a non-grayscale colormap 
        % for the secondary dataset while leaving the underlying CT image 
        % grayscale. The image is divided by 2048 to set the grayscale
        % window from -1024 to +1024.
        imshow(ind2rgb(gray2ind((imageA) / 2048, 64), colormap('gray')), ...
            reference);
       
    end
    
    % Hold the axes to allow an overlapping plot
    hold on;
    
    % If the secondary dataset is intensity based, use a colormap
    if size(size(obj.overlay.data),2) == 3
        
        % If the image is flat, slightly increase the maxval to prevent an
        % error from occurring when calling DisplayRange
        if obj.overlayrange(2) == obj.overlayrange(1)
            obj.overlayrange(2) = obj.overlayrange(1) + 1e-6; 
        end
        
        % Plot the secondary dataset over the reference dataset, using the
        % display range [minval maxval] and a jet colormap.  The secondary
        % image handle is stored to the variable handle.
        handle = imshow(imageB, reference, 'DisplayRange', ...
            [obj.overlayrange(1) obj.overlayrange(2)], ...
            'ColorMap', colormap('jet'));
        
    % Otherwise, the secondary dataset is RGB
    else
    
        % Plot the secondary dataset over the reference dataset
        handle = imshow(imageB, reference);
    end
    
    % Unhold axes generation
    hold off;
    
    % Set the transparency of the secondary dataset handle based on the
    % transparency input
    set(handle, 'AlphaData', obj.alpha);
    
% Otherwise, only a primary dataset was provided
else

    % If the image is an MR
    if isfield(obj.background, 'type') && strcmpi(obj.background.type, 'MR')
        
        % Cast the imageA data as 16-bit unsigned integer
        imageA = int16(imageA);
    
        % Display the reference image using a gray colormap with the range 
        % set between the minimum and maximum values in the image
        imshow(imageA, reference, 'DisplayRange', [obj.backgroundrange(1) ...
            obj.backgroundrange(2)], 'ColorMap', colormap('gray'));
    
    % Otherwise, if CT, or no image type is provided
    else
    
        % Cast the imageA data as 16-bit unsigned integer
        imageA = int16(imageA);
    
        % Display the reference image in HU (subtracting 1024), using a
        % gray colormap with the range set from -1024 to +1024
        imshow(imageA - 1024, reference, 'DisplayRange', [-1024 1024], ...
            'ColorMap', colormap('gray'));
        
    end
end

% Hold the axes to allow overlapping contours
hold on;

%% Add image contours
% Display structures using obj.background data, if present
if iscell(obj.structures)
    
    % Loop through each structure
    for i = 1:length(obj.structures)
        
        % If the statistics display column for this structure is set to
        % true (checked)
        if ~iscell(obj.structuresonoff) || obj.structuresonoff{i,2}
            
            % Extract structure mask based on T/C/S setting
            switch obj.tcsview
                
                % If orientation is Transverse
                case 'T'
                
                    % Use bwboundaries to generate X/Y contour points based
                    % on structure mask
                    B = bwboundaries(squeeze(...
                        obj.structures{i}.mask(:, :, obj.slice))');
                    
                % If orientation is Coronal
                case 'C'
                
                    % Use bwboundaries to generate X/Y contour points based
                    % on structure mask
                    B = bwboundaries(squeeze(...
                        obj.structures{i}.mask(:, obj.slice, :))');
                    
                % If orientation is Sagittal
                case 'S'
                
                    % Use bwboundaries to generate X/Y contour points based
                    % on structure mask
                    B = bwboundaries(squeeze(...
                        obj.structures{i}.mask(obj.slice, :, :))');
            end
            
            % Loop through each contour set (typically this is one)
            for k = 1:length(B)
                
                % Extract structure mask based on T/C/S setting
                switch obj.tcsview
                    
                    % If orientation is Transverse
                    case 'T'
                    
                        % Plot the contour points given the structure color
                        plot((B{k}(:,2) - 1) * obj.background.width(1) + ...
                            obj.background.start(1), (B{k}(:,1) - 1) * ...
                            obj.background.width(2) - (start(2) + size(imageA,1) * ...
                            obj.background.width(2)), 'Color', ...
                            obj.structures{i}.color/255, ...
                            'LineWidth', 2);
                       
                    % If orientation is Coronal
                    case 'C'
                    
                        % Plot the contour points given the structure color
                        plot((B{k}(:,2) - 1) * obj.background.width(1) + ...
                            obj.background.start(1), (B{k}(:,1) - 1) * ...
                            obj.background.width(3) + obj.background.start(3), ...
                           'Color', obj.structures{i}.color/255, ...
                           'LineWidth', 2);
                       
                    % If orientation is Sagittal
                    case 'S'
                    
                        % Plot the contour points given the structure color
                        plot((B{k}(:,2) - 1) * obj.background.width(2) ...
                            - (obj.background.start(2) + size(imageA,2) * ...
                            obj.background.width(2)), (B{k}(:,1) - 1) * ...
                            obj.background.width(3) + obj.background.start(3), ...
                           'Color', obj.structures{i}.color/255, ...
                           'LineWidth', 2);
                end
            end
            
            % Clear temporary variable
            clear B;
        end
    end
end

% Unhold axes generation
hold off;

%% Finalize figure
% Hide the x/y axis on the images
axis off

% If zoom is enabled
if strcmpi(obj.zoom, 'on')
    
    % Enable zoom
    zoom on

    % Reset zoom and pan, if real values existed previously
    if ~isequal(xlim, [0 1])
        obj.axis.XLim = xlim;
        obj.axis.YLim = ylim;
    end
end

% If pixelval is enabled
if strcmpi(obj.pixelval, 'on')
    
    % Start the POI tool, which automatically diplays the x/y coordinates
    % (based on imref2d above) and the current mouseover location
    impixelinfo
end

% If the colorbar is enabled
if strcmpi(obj.cbar, 'on')
    colorbar(obj.axis);
end

% If a slider exists
if ~isempty(obj.slider) && ishandle(obj.slider)
    
    % Display it
    set(obj.slider, 'visible', 'on');
end

% Clear temporary variables
clear i image width start xlim ylim;
