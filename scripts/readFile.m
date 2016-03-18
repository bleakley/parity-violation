function [ upEvents downEvents totalSeconds ] = readFile( file_name )
%READ_FILE Summary of this function goes here
%   Detailed explanation goes here
fid = fopen(file_name, 'r');

values = textscan(fid, '%d%d%d%f%d');
upEvents = values{4}(values{1}==6);
downEvents = values{4}(values{1}==7);
timeStamps = values{5};
eventNumbers = values{3};
fclose(fid);

totalSeconds = 0;
for t=2:size(timeStamps,1)
    delay = timeStamps(t)-timeStamps(t-1);
    if eventNumbers(t) ~= 1
        totalSeconds = totalSeconds + delay;
    end
end

end
