%% Continuous ECG Live Plot — Wrap-Around Monitor Style
clear; clc; close all;

% 1. Port Configuration
COM_PORT = "COM3";     % <-- Ensure this matches your active port
BAUD     = 9600;       
WINDOW_SECONDS = 5;    
SAMPLE_RATE_HZ = 250;  

%% 2. Set up serial connection
s = serialport(COM_PORT, BAUD);
configureTerminator(s, "CR/LF"); 
flush(s);

%% 3. Set up the continuous window plot
numPoints = WINDOW_SECONDS * SAMPLE_RATE_HZ;
fig = figure('Name', 'Continuous ECG Monitor', 'NumberTitle', 'off');
ax = axes(fig);

% Track data points in a fixed array buffer for smooth rendering
xData = 1:numPoints;
yData = NaN(1, numPoints); % Initialize with NaN so empty points don't draw
hPlot = plot(ax, xData, yData, 'r-', 'LineWidth', 1.5);

xlim(ax, [1 numPoints]);
ylim(ax, [0 1023]);   
xlabel(ax, 'Timeline Window');
ylabel(ax, 'ADC Value (0-1023)');
title(ax, 'Continuous Real-Time ECG Stream');
grid(ax, 'on');

%% 4. Continuous Wrap Loop
sampleIndex = 0;
disp('Streaming continuously... Close the figure window to stop.');

while ishandle(fig)
    try
        line = readline(s);
        value = str2double(line);

        if ~isnan(value)
            sampleIndex = sampleIndex + 1;
            
            % Use modulo to find the wrapping screen coordinate (1 to numPoints)
            screenX = mod(sampleIndex - 1, numPoints) + 1;
            
            % Update the specific data point in our fixed-size window
            yData(screenX) = value;
            
            % Optional: Create a blank gap right ahead of the drawing "wipe" line 
            % so you can easily see where the new data is overwriting the old data
            gapSize = 10; 
            for g = 1:gapSize
                gapIndex = mod(screenX + g - 1, numPoints) + 1;
                yData(gapIndex) = NaN;
            end
            
            % Update the plot object instantly
            set(hPlot, 'YData', yData);
            drawnow limitrate;
        end
    catch
        break; 
    end
end

%% 5. Cleanup
clear s;
disp('Serial connection safely closed.');
