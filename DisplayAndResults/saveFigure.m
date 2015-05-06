function saveFigure(paperPosition, resultsImgDir, fileName)

% saveFigure(paperPosition, resultsImgDir, fileName)
% Formats figure to publication quality and saves file.
% 
% paperPosition: Figure dimensions, in cm.
% resultsImgDir: Directory for figures to be saved in.
% fileName: Figure file name, without format suffix.

set(gcf,'PaperUnits','centimeters ')
set(gcf,'PaperPosition',paperPosition)
set(gcf,'PaperSize', paperPosition(3:4))
legend boxoff
set(gcf,'renderer','painters')
print('-dpdf', [resultsImgDir fileName '.pdf']);
print('-dpng', [resultsImgDir fileName '.png']);

end