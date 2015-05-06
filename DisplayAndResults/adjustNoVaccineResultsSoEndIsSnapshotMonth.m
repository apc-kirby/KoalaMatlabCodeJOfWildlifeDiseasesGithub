function adjustedRecords = adjustNoVaccineResultsSoEndIsSnapshotMonth(recordsEndMonthsUneven, snapshotMonths, yearsToTake)

% adjustedRecords = adjustNoVaccineResultsSoEndIsSnapshotMonth(recordsEndMonthsUneven, snapshotMonths, yearsToTake)
% 'No intervention' simulations do not necessarily run for
% identical times, but  we want to adjust the 'no intervention'
% results so that they all end evenly. This function does this.
%
% recordEndMonthsUneven: Final months of simulations.
% snapshotMonths: Months in which population snapshots were taken.
% yearsToTake: Number of simulated years that should be retained from results.
%
% adjustedRecords: Results with times adjusted appropriately.

monthsToTake = yearsToTake*12;
recordFields = fields(recordsEndMonthsUneven);
for indField = 1:length(recordFields)
    if ~isempty(recordsEndMonthsUneven.(recordFields{indField}))
        tempRecordEndMonthsUnevenMatrix = recordsEndMonthsUneven.(recordFields{indField});
        tempAdjustedRecordMatrix = zeros(length(snapshotMonths), monthsToTake+2);
        for indParam = 1:length(snapshotMonths)
            tempAdjustedRecordMatrix(indParam,1:2) = tempRecordEndMonthsUnevenMatrix(indParam,1:2);
            tempAdjustedRecordMatrix(indParam,3:end) = tempRecordEndMonthsUnevenMatrix(indParam, (snapshotMonths(indParam) - monthsToTake + 3):(2+snapshotMonths(indParam)));
        end
        adjustedRecords.(recordFields{indField}) = tempAdjustedRecordMatrix;
    end
end
end