clear all;

%magnet on seconds
magnetOnSeconds = 3017173;

%magnet off coefficient results, U-D
magOffCoef = [-45.598899445752004,16.599707750871290,7.745976665731854e+05,52.184161735160600,2.207602916361266e+04]
magnetOffSeconds = 516044
magnetOffFactor = magnetOnSeconds/magnetOffSeconds;
magnetOffFunction =  @(t)magnetOffFactor*(magOffCoef(1) + magOffCoef(2).*exp(-magOffCoef(3).*t) + magOffCoef(4).*exp(-magOffCoef(5).*t));

%target out coefficient results
targetOutCoef = [-2.014032509166946e+02,37.405296389540430,1.248045285201873e+06,2.099350796768699e+02,-1.198516976954844e+04];
targetOutSeconds = 602777;
targetOutFactor = magnetOnSeconds/targetOutSeconds;
targetOutFunction =  @(t)targetOutFactor*(targetOutCoef(1) + targetOutCoef(2).*exp(-targetOutCoef(3).*t) + targetOutCoef(4).*exp(-targetOutCoef(5).*t));

%Step 1: read file
[ upEvents downEvents totalSeconds ] = readFile( 'full_magon.txt' );

%combine files
%{
[ upEvents1 downEvents1 totalSeconds ] = readFile( 'full_magoff.txt' );
[ upEvents2 downEvents2 totalSeconds ] = readFile( 'full_magoff.txt' );

largest = max(size(upEvents,1), size(upEvents1,1), size(upEvents2,1));
upEvents = cat(1,upEvents,zeros(largest-size(upEvents,1),1)).';

upEvents = upEvents + upEvents1 + upEvents2;
%}

totalSeconds
days = totalSeconds/60/60/24

%Step 2: Crop and bin data

for(startTDC=3:3)
    startTDC
    binFactor = 2
    
[ up down time ] = crop( upEvents, downEvents, startTDC, 300 );

largest = max(size(up,1), size(down,1));
up = cat(1,up,zeros(largest-size(up,1),1)).';
down = cat(1,down,zeros(largest-size(down,1),1)).';
time = time(1:largest).';

[up, down, time] = bin( up, down, time, binFactor );

indexOfFirstZero = min(find(up <= 1,1), find( down <= 1,1));
up = up(1:indexOfFirstZero-1);
down = down(1:indexOfFirstZero-1);
time = time(1:indexOfFirstZero-1);

time = time.*20e-9;% each time unit is 20 nanoseconds

difference = up-down;% combine up and down
both = up+down;% combine up and down

difference = difference - magnetOffFunction(time); %correct with magnet off
both = both - targetOutFunction(time); %correct with target out

quotient = difference./both;

sigmasUp = up.^(1/2);
sigmasDown = down.^(1/2);
sigmasSum = (sigmasUp.^2 + sigmasDown.^2).^(1/2);
sigmasQuotient = quotient.*(sigmasSum./both -sigmasSum./difference);

modelType = 'exponentialSum';

switch modelType
    case 'exponential'
    dataToFit = up;% fit to up, down, both, difference or quotient
    sigmas = sigmasUp;
    case 'exponentialSum'
    dataToFit = both;% fit to up, down, both, difference or quotient
    sigmas = sigmasSum;
    case 'difference'
    dataToFit = difference;% fit to up, down, both, difference or quotient
    sigmas = sigmasSum;
    case 'sinosodial'
    dataToFit = quotient;% fit to up, down, both, difference or quotient
    sigmas = sigmasQuotient;
end

%Step 3: fit and plot the data

weights = sigmas.^-2;
errorbar(time,dataToFit,sigmas,'.');

title('U-D / U+D, magnet on, corrected for background');

xlabel('Seconds');
ylabel('Events');
if strcmp(modelType,'sinosodial')
    ylabel('Event Ratio');
end

%only up + down has contribution from apparatus; only up + down needs to be
%corrected by target out data

%magnet off corrects up minus down

switch modelType
    case 'exponential'
    %model for single exponential
    modelFunction =  @(c,t)(c(1) + c(2).*exp(-c(3).*t));
    coeffGuesses = [30 100 0.03];
    [coeffEstimates,R,J,CovB,MSE,ErrorModelInfo] = nlinfit(time, dataToFit, modelFunction, coeffGuesses, 'Weights', weights);
    coeffUncertainties = diag(CovB).^(1/2);
    meanLifetime = 1/coeffEstimates(3)
    meanLifetime1Uncert = 1/coeffUncertainties(3)
    percentError = 100*(meanLifetime - 2.1969811e-6)/2.1969811e-6
    case 'exponentialSum'
    %model for the sum of two exponentials
    modelFunction =  @(c,t)(c(1) + c(2).*exp(-c(3).*t) + c(4).*exp(-c(5).*t));
    coeffGuesses = [30 100 5e-6 100 5e-6];
    %coeffGuesses = [-2.014032509166946e+02,37.405296389540430,1.248045285201873e+06,2.099350796768699e+02,-1.198516976954844e+04];
    [coeffEstimates,R,J,CovB,MSE,ErrorModelInfo] = nlinfit(time, dataToFit, modelFunction, coeffGuesses, 'Weights', weights);
    coeffUncertainties = diag(CovB).^(1/2);
    meanLifetime1 = 1/coeffEstimates(3)
    meanLifetime2 = 1/coeffEstimates(5)
    meanLifetime1Uncert = meanLifetime1 * coeffUncertainties(3)/coeffEstimates(3)
    meanLifetime2Uncert = meanLifetime2 * coeffUncertainties(5)/coeffEstimates(5)
    meanLifetime = max(meanLifetime1, meanLifetime2)
    percentError = 100*(meanLifetime - 2.1969811e-6)/2.1969811e-6
    case 'difference'
    %model for U-D
    modelFunction = @(c,t)((c(1)+c(2).*cos(c(4).*t)).*exp(-c(3).*t));
    coeffGuesses = [50,50,5e-6,2e10];
    [coeffEstimates,R,J,CovB,MSE,ErrorModelInfo] = nlinfit(time, dataToFit, modelFunction, coeffGuesses, 'Weights', weights);
    case 'sinosodial'
    %model for sinosodial
    modelFunction = @(c,t)( c(1)+c(2).*cos(c(3).*t + c(4)) );
    coeffGuesses = [0,1,2e3,0];
    coeffGuesses = [0,1,4e3,0];
    %coeffGuesses = [0,1,5e3,0];
    %coeffGuesses = [0.183563150604936,0.066145051561827,-2.910880313361027e+06,12.132158756833295]
    [coeffEstimates,R,J,CovB,MSE,ErrorModelInfo] = nlinfit(time, dataToFit, modelFunction, coeffGuesses, 'Weights', weights);
    coeffUncertainties = diag(CovB).^(1/2);
    BoverA = coeffEstimates(2)/coeffEstimates(1)
    omega = coeffEstimates(3)
    omegaUncert = coeffUncertainties(3)
    g = (omega/1e6)/(0.3716*3.84)
    gUncert = (omegaUncert/1e6)/(0.3716*3.84)
    gamma = (4e8)*g
    gammaUncert = (4e8)*gUncert
    mu = g*2.24e-26;
end

line(time, modelFunction(coeffEstimates, time), 'Color', 'r');
end