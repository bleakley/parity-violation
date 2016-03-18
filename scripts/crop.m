function [ up down time ] = crop( upEvents, downEvents, minTime, maxTime )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

firstBadDataPoint = 30;
lastBadDataPoint = 37;

upEvents(upEvents > maxTime) = [];
downEvents(downEvents > maxTime) = [];
upEvents(upEvents<1)=1;
downEvents(downEvents<1)=1;



up = accumarray(upEvents,1);
down = accumarray(downEvents,1);
time = 1:maxTime;
time = time.';

up = up((minTime+1):end);
down = down((minTime+1):end);
time = time((minTime+1):end);

end

