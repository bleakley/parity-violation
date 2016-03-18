function [ binnedData, binnedData2, binnedTime ] = bin( dataArray, dataArray2, timeArray, binFactor )
%BIN Summary of this function goes here
%   Detailed explanation goes here

binnedData = [];
binnedData2 = [];
binnedTime = [];
size(dataArray,2);
newLength = floor(size(dataArray,2)/binFactor);

for t=1:newLength
    
    nthTime = timeArray(t);
   
    lowBound=binFactor*(t-1)+nthTime;
    highBound=binFactor*t+nthTime-1;
    
    lowIndex = find( timeArray == lowBound );
    highIndex = find( timeArray == highBound );
    
    midBound=(lowBound+highBound)/2;
    binnedData(t) = sum(dataArray(lowIndex:highIndex));
    binnedData2(t) = sum(dataArray2(lowIndex:highIndex));
    binnedTime(t) = midBound;
end

badIndices = find(binnedTime >= 30 & binnedTime <= 37);
lowestBadIndex=badIndices(1);
highestBadIndex=badIndices(end);

binnedTime = cat(2, binnedTime(1:lowestBadIndex-1), binnedTime(highestBadIndex+1:end));
binnedData = cat(2, binnedData(1:lowestBadIndex-1), binnedData(highestBadIndex+1:end));
binnedData2 = cat(2, binnedData2(1:lowestBadIndex-1), binnedData2(highestBadIndex+1:end));

end