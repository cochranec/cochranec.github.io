function [lower, mid, upper] = bootStrapGND(data)
% bootStrapGND Function
% Return a bootstrapped confidence interval on input data
% Adapted for use with the GND Code developed by Travis Skippon
% Written by Chris Cochrane (Mar. 20, 2018)
%
% Variables:
% alpha - Confidence interval is (100 - alpha)%

data=data(~isnan(data));
alpha=5;

nC = length(data);
if nC == 0
    upper = 0;
    mid = 0;
    lower = 0;
else
    nSelections = 1000;
    iterations = 1000;
    
    caseSampleIndices=randi([1 nC],nSelections,iterations);
    
    bootstrapVals = geomean(data(caseSampleIndices),1);
    upper=prctile(bootstrapVals, 100 - alpha / 2);
    lower= prctile(bootstrapVals, alpha / 2);
    mid=geomean(data);
end
end