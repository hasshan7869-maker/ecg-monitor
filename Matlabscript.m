%% Continuous ECG Live Plot with Real-Time BPM Counter
clear; clc; close all;

% 1. Port Configuration
COM_PORT = "COM3";     
BAUD     = 9600;       
WINDOW_SECONDS = 5;    
SAMPLE_RATE_HZ = 250;  % 250 samples per second (1 sample every 4ms)

% 2. BPM Tracking Variables
threshold = 750;       % ADJUST THIS: The line height a spike must cross to count as a beat
lastPeakIndex = 0;     % Stores the sample index of the last heartbeat
cooldownSamples = 50;  % Ignore new spikes for 50 samples (0.2 seconds) after a beat
currentBPM = 0;

%% 3. Set up serial connection
s = serialport(COM_PORT, BAUD);
configureTerminator(s, "CR/LF"); 
flush(s);

%% 4. Set up the continuous window plot
numPoints = WINDOW_SECONDS * SAMPLE_RATE_HZ;
fig = figure('Name', 'Continuous ECG Monitor with BPM', 'NumberTitle', 'off');
ax = axes(fig);

xData = 1:numPoints;
yData = NaN(1, numPoints); 
hPlot = plot(ax, xData, yData, 'r-', 'LineWidth', 1.5);

xlim(ax, [1 numPoints]);
ylim(ax, [0 1023]);   
xlabel(ax, 'Timeline Window');
ylabel(ax, 'ADC Value (0-1023)');
title(ax, 'Continuous Real-Time ECG Stream');
grid(ax, 'on');

% Add a dynamic text box to display the Heart Rate on the screen
bpmText = text(ax, 20, 950, 'BPM: --', 'FontSize', 20, 'FontWeight', 'bold', 'Color', [0 0.5 0]);

%% 5. Continuous Wrap & BPM Loop
sampleIndex = 0;
disp('Streaming continuously... Close the figure window to stop.');

while ishandle(fig)
    try
        line = readline(s);
        value = str2double(line);

        if ~isnan(value)
            sampleIndex = sampleIndex + 1;

            % --- HEART RATE CALCULATION ---
            % Check if the signal crossed the threshold AND we are out of the cool-down period
            if (value > threshold) && ((sampleIndex - lastPeakIndex) > cooldownSamples)

                % Calculate BPM if this isn't our very first heartbeat
                if lastPeakIndex > 0
                    samplesBetweenBeats = sampleIndex - lastPeakIndex;

                    % Formula: (60 seconds * 250 samples/sec) / samples counted
                    currentBPM = (60 * SAMPLE_RATE_HZ) / samplesBetweenBeats;

                    % Update the text box on the graph (rounded to a whole number)
                    set(bpmText, 'String', sprintf('BPM: %d', round(currentBPM)));
                end

                % Save this spike's index as the new marker
                lastPeakIndex = sampleIndex;
            end
            % -------------------------------

            % Update the wrap-around screen coordinates
            screenX = mod(sampleIndex - 1, numPoints) + 1;
            yData(screenX) = value;

            % Create a blank gap right ahead of the drawing "wipe" line 
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

%% 6. Cleanup
clear s;
disp('Serial connection safely closed.');
