function SAVE_RESULTS(folder, baseline, counterfactual, statistics, figures)
%SAVE_RESULTS Save figures and tables in separate folders for this experiment.
figure_folder = fullfile(folder,'Figures'); % Keep publication graphics together.
table_folder = fullfile(folder,'Tables'); % Keep all representations of the summary table together.
if ~isfolder(figure_folder), mkdir(figure_folder); end % Create the figure directory when needed.
if ~isfolder(table_folder), mkdir(table_folder); end % Create the table directory when needed.
STATUS(baseline.options,'Saving figures and tables to %s...',folder); % Report export activity.
writetable(statistics,fullfile(table_folder,'statistics.csv')); % Retain numeric values in a machine-readable table.
writetable(statistics,fullfile(table_folder,'statistics.xlsx'),'Sheet','Statistics','WriteMode','replacefile'); % Replace prior columns when switching to baseline-only mode.
WRITE_TABLE_TEX(fullfile(table_folder,'statistics.tex'),statistics); % Write a document-ready LaTeX table fragment.
save(fullfile(folder,'results.mat'),'baseline','counterfactual'); % Preserve complete inputs, profiles, and diagnostics.
for k = 1:numel(figures)
    name = sprintf('figure_%d',k); % Stable numbering follows RESULTS: height, floor-space rent, land rent.
    exportgraphics(figures(k),fullfile(figure_folder,[name '.png']),'Resolution',300); % Save a high-resolution raster image.
    exportgraphics(figures(k),fullfile(figure_folder,[name '.pdf']),'ContentType','vector'); % Preserve sharp text and lines in PDF.
end
[output_root,version] = fileparts(folder); % Recognize the named master-script output directories.
[~,root_name] = fileparts(output_root); % Restrict the latest-run mirror to the toolkit outputs folder.
if strcmpi(root_name,'outputs') && any(strcmp(version,{'Paper','Empirical'}))
    latest_tables=fullfile(output_root,'Tables'); latest_figures=fullfile(output_root,'Figures'); % Preserve the familiar top-level output locations.
    if ~isfolder(latest_tables), mkdir(latest_tables); end % Create the latest-run table directory if needed.
    if ~isfolder(latest_figures), mkdir(latest_figures); end % Create the latest-run figure directory if needed.
    for extension={'csv','xlsx','tex'}
        name=['statistics.' extension{1}]; copyfile(fullfile(table_folder,name),fullfile(latest_tables,name),'f'); % Mirror the exact exported table, including all scenario columns.
    end
    copyfile(fullfile(folder,'results.mat'),fullfile(output_root,'results.mat'),'f'); % Keep the latest saved model consistent with its tables.
    for k=1:numel(figures)
        for extension={'png','pdf'}
            name=sprintf('figure_%d.%s',k,extension{1}); copyfile(fullfile(figure_folder,name),fullfile(latest_figures,name),'f'); % Mirror each newly exported figure.
        end
    end
    STATUS(baseline.options,'Latest-run tables also available in %s (source: %s).',latest_tables,version); % Make the relationship between both output locations explicit.
end
STATUS(baseline.options,'Saved %d figures as PNG/PDF and the summary table as TEX/CSV/XLSX.',numel(figures)); % Confirm completed formats.
end
