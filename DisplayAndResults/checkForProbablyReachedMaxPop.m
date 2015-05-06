function [monthReachedMaxPop, monthFellByOverThreshold, filterReachedMaxPop2ndLastMonth] = checkForProbablyReachedMaxPop(recordMatrix)

% [monthReachedMaxPop, monthFellByOverThreshold, filterReachedMaxPop2ndLastMonth] = checkForProbablyReachedMaxPop(recordMatrix)
% There is a maximum allowed population in the simulations. This function
% checks simulation results to see if this maximum might have been exceeded.
%
% recordMatrix: Simulation results.
%
% monthReachedMaxPop: Months in which the maximum was reached.
% monthFllByOverThreshold: Months in which population fell by at least a
% specified amount in a single month (indicative of the simulation suddenly
% halting).
% filterReachedMaxPop2ndLastMonth: Mask of simulations in which the maximum
% was reached in the second last month.

baseParams = getBaseParamsAndSetPath()
doubleRecordMatrix = double(recordMatrix);
maxPop = baseParams.maxAllowedPop;
dropThreshold = 500;
nSimsReachedMaxPop = 0;
nSimsWithAtLeastOneDropOverThreshold = 0;
disp(['Checking whether tracked value in records fell by at least ' num2str(dropThreshold) ' in a single timestep, '])
disp(['and whether tracked value in records reached at least ' num2str(maxPop) '.'])
monthReachedMaxPop = [doubleRecordMatrix(:,1:2) Inf(size(doubleRecordMatrix,1),1)];
monthFellByOverThreshold = [doubleRecordMatrix(:,1:2) Inf(size(doubleRecordMatrix,1),1)];
filterReachedMaxPop2ndLastMonth = false(size(doubleRecordMatrix,1),1);
indexOfSecondLastMonth = size(doubleRecordMatrix(:, 3:end-1),2);
for indRow = 1:size(doubleRecordMatrix,1)
    if mod(indRow, 100000) == 0
        disp(['Checking row ' num2str(indRow) ' of ' num2str(size(doubleRecordMatrix,1)) '...'])
    end
    indexOfFirstReachedMaxPop = find(doubleRecordMatrix(indRow, 3:end-1) >= maxPop, 1, 'first');
    if ~isempty(indexOfFirstReachedMaxPop)
        monthReachedMaxPop(indRow, 3) = indexOfFirstReachedMaxPop;
        nSimsReachedMaxPop = nSimsReachedMaxPop + 1;
        if indexOfFirstReachedMaxPop == indexOfSecondLastMonth
            filterReachedMaxPop2ndLastMonth(indRow) = true;
        end
    end
    indexOfFirstDropOverThreshold = find(diff(doubleRecordMatrix(indRow, 3:end-1)) <= -1*dropThreshold, 1, 'first');
    if ~isempty(indexOfFirstDropOverThreshold)
        monthFellByOverThreshold(indRow, 3) = indexOfFirstDropOverThreshold;
        nSimsWithAtLeastOneDropOverThreshold = nSimsWithAtLeastOneDropOverThreshold + 1;
    end
end
disp(['Found ' num2str(nSimsReachedMaxPop) ' sims that reached ' num2str(maxPop) '.'])
disp(['Earliest year in which this occurred was ' num2str(min(monthReachedMaxPop(:,3))/12) '.'])
disp(['In ' num2str(sum(filterReachedMaxPop2ndLastMonth)) ' cases, this maximum was reached in the second-last month and therefore would not be counted as having a drop over the threshold.'])
disp(['Found ' num2str(nSimsWithAtLeastOneDropOverThreshold) ' sims with at least one drop of over ' num2str(dropThreshold) ' in a single timestep.'])
disp(['Earliest year in which this occurred was ' num2str(min(monthFellByOverThreshold(:,3))/12) '.'])
disp([num2str(nSimsWithAtLeastOneDropOverThreshold) ' + ' num2str(sum(filterReachedMaxPop2ndLastMonth)) ' = ' num2str(nSimsReachedMaxPop) ])
disp(['Last month is NOT included in checks, because it always has zero pop.'])

end