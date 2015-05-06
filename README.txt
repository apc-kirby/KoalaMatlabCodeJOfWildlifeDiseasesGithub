README
Date: May 2015
Author: Andrew P. Craig
Contact: David P. Wilson dwilson@unsw.edu.au


===========
== SETUP ==
===========

The code assumes the existance of some directories. Say a parent directory [KOALAS] is created - then the following directories must also exist:

The results directory:
[KOALAS]\Results 23012015

The figures directory: 
[KOALAS]\Manuscript (culling)\Journal of Wildlife Diseases\Figures and tables 09042015

The code directory (the code subfolders should be within this directory):
[KOALAS]\KoalaMatlabCodeJOfWildlifeDiseasesGithub


=====================
== PARALLELIZATION == 
=====================

The code uses the Matlab Parallel Computing Toolbox so that multiple simulations can be run simulateously.
The number of computers you will be using and their names should be set in [KOALAS]\KoalaMatlabCodeJOfWildlifeDiseasesGithub\Launch\getBaseParamsAndSetPaths.m .
The instructions below for running the model assume that you will be using multiple computers. If not, read 'ALL computers' as 'ONE computer'.
If you do not have the Matlab Parallel Computing Toolbox, you may need to search the files for 'parfor' and replace it with 'for' for the code to run.


=======================
== RUNNING THE MODEL == 
=======================

Scripts to be run are all in [KOALAS]\KoalaMatlabCodeJOfWildlifeDiseasesGithub\Launch .
We recommend restarting Matlab between each step to make sure the memory has been fully cleared.

1.	Put files from Data directory into results directory.
2.	On ONE computer: run launchGenerateParams.m
3.	On ALL computers: run launchNoInfectionSims.m.
4.	On ONE computer: run combineNoInfectionResults.m.
5.	On ONE computer: run recalcLHSSamplesForInfectionParams.m 
6.	One ALL computers: run launchNoVaccineSims.m.
7.	On ONE computer: run combineNoVaccineResultsAndStartingPops.m.
8.	On ALL computers: run launchVaccineSims.m.
9.	On ONE computer: run createAllFigures.m


========================
== LIST OF CODE FILES ==
========================

DisplayAndResults\adjustNoVaccineResultsSoEndIsSnapshotMonth.m
DisplayAndResults\calculateReversalTimes.m
DisplayAndResults\calculateScenarioSuccesses.m
DisplayAndResults\calculationReversalProportions.m
DisplayAndResults\checkForDuplicateParamSets.m
DisplayAndResults\checkForProbablyReachedMaxPop.m
DisplayAndResults\createAgeSchematic.m
DisplayAndResults\createExampleTimeCoursesCulling.m
DisplayAndResults\displayUsedParamRanges
DisplayAndResults\dropExtraResults.m
DisplayAndResults\getReversalTimeForOneScenario.m
DisplayAndResults\getUsedNoVaccineResults.m
DisplayAndResults\plotBackProjection.m
DisplayAndResults\plotDataTimeCourse.m
DisplayAndResults\plotOneTimeCourse.m
DisplayAndResults\reportSummaryStatistics.m
DisplayAndResults\saveFigure.m

Launch\addPaths.m
Launch\combineNoInfectionResults.m
Launch\combineNoVaccineResultsAndStartingPops.m
Launch\combineVaccineResults.m
Launch\createAllFiguresCulling.m
Launch\getBaseParamsAndSetPaths.m
Launch\getBaseParamsForVisualisation.m
Launch\getResultsDir.m
Launch\launchGenerateParams.m
Launch\launchNoInfectionSims.m
Launch\launchNoVaccineSims.m
Launch\launchVaccineSims.m
Launch\recalcLHSSamplesForInfectionParams.m

Misc\addAvgEffToScenarioParamsMatrix
Misc\adjustDatesOfPopulationSnapshots.m
Misc\bool2str.m
Misc\confi.m
Misc\createReproductiveSuccessStruct.m
Misc\csvreadFromResultsDir.m
Misc\encodeKoalaStatus.m
Misc\getApproxCapturesPerYear.m
Misc\getAvgEff.m
Misc\getCleanScenarioLabels.m
Misc\getLifespanProbabilitiesMonthly
Misc\getMachineNumber.m
Misc\getNaturalLifespan.m
Misc\getNGoodParamsIndexesNoInfection.m
Misc\getOneMonthlyProbabilityOfConceivingIfMated.m
Misc\getParamIndices
Misc\getParamsWithoutRanges.m
Misc\getQuantileTimeCourseForThisScenario.m
Misc\getSuggestedParamSetsByMachine.m
Misc\importfile1.m
Misc\importParams.m
Misc\R.m
Misc\randpermArray.m

Models\modelMonthly.m

RunSims\runNoInfectionSims.m
RunSims\runNoVaccineSims.m
RunSims\runVaccineSims.m

Setup\determineOneRandomStartingPop.m
Setup\generateParamsMatrix.m
Setup\generateParamsStructBasics.m
Setup\getHalfLife.m
Setup\getInitialEfficacy.m
Setup\loadBodyScoreParams.m
Setup\loadKoalaCoastPops.m
Setup\setupBodyScoreParams.m
Setup\setupParamsAsArrays.m
Setup\setupScenarioParams23012015_23Culling.m
Setup\updateParamsMatrix.m



========================
== LIST OF DATA FILES ==
========================

parameterTable.xlsx
bodyScoreParams.xlsx
weightReprodSuccessWeights.xlsx
weightReprodSuccessReprodSuccess.xlsx
weightTrackParamsFile.xlsx
koalaCoastPop.csv