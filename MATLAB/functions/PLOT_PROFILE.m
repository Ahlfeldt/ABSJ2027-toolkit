function fig = PLOT_PROFILE(baseline, counterfactual, fieldC, fieldR, heading, y_label)
%PLOT_PROFILE Compare saved radial profiles and show each land-use pattern.
fig = figure('Name',heading,'Color','w','Position',[100 100 1050 650]); % Create an independent, exportable figure.
layout = tiledlayout(fig,4,1,'TileSpacing','compact','Padding','compact'); % Reserve the lower quarter for land use.
ax = nexttile(layout,[3 1]); hold(ax,'on'); % Upper axes contain the economic profiles.
cities = {baseline}; styles = {'-'}; labels = {'Baseline'}; % Default to one solved city.
if ~isempty(counterfactual)
    cities{2} = counterfactual; styles{2} = '--'; labels{2} = 'Counterfactual'; % Distinguish scenarios by line style.
end
outer = max(cellfun(@(city) city.scalist.x1,cities)); % Choose a common range from both urban extents.
limits = cellfun(@(city) city.params.x1_max,cities); % Include nearby policy boundaries in the displayed range.
nearby = limits(isfinite(limits) & limits <= 1.5*outer); % Avoid a distant nonbinding boundary compressing the city.
if ~isempty(nearby), outer = max([outer,nearby]); end % Keep relevant policy lines visible.
xmax = min(max(baseline.fund.D),max(2,1.15*outer)); % Show a rural margin without changing model inputs.
colors = [213 94 0; 0 114 178]/255; % Okabe-Ito vermillion and blue distinguish sectors for colour-blind readers.
handles = gobjects(0); names = {}; % Build a legend from actual plotted lines.
for j = 1:numel(cities)
    city = cities{j}; distance = city.fund.D; % Use the saved radial coordinates.
    handles(end+1) = plot(ax,distance,city.varlist.(fieldC),'Color',colors(1,:),'LineStyle',styles{j},'LineWidth',1.8); % Commercial profile.
    names{end+1} = ['Commercial - ' labels{j}]; % Label both sector and scenario.
    handles(end+1) = plot(ax,distance,city.varlist.(fieldR),'Color',colors(2,:),'LineStyle',styles{j},'LineWidth',1.8); % Residential profile.
    names{end+1} = ['Residential - ' labels{j}]; % Label both sector and scenario.
    if strcmp(fieldC,'r_x_C')
        handles(end+1) = plot(ax,[0 xmax],[city.params.r_a city.params.r_a],'Color',[0.40 0.40 0.40],'LineStyle',styles{j},'LineWidth',1.2); % Agricultural bid rent remains present outside the city.
        names{end+1} = ['Agricultural - ' labels{j}]; % Distinguish agricultural-rent changes if requested.
    end
end
title(ax,heading,'FontWeight','normal','FontSize',17); % Readable figure title.
ylabel(ax,y_label); xlim(ax,[0 xmax]); ylim(ax,[0 Inf]); % Common distance domain and non-negative vertical scale.
set(ax,'FontName','Arial','FontSize',11,'Box','off','XGrid','on','YGrid','on','GridLineStyle',':','GridColor',[0.35 0.35 0.35],'GridAlpha',0.35); % Dotted major grids at both x and y ticks.
legend(ax,handles,names,'Location','northeast','Box','off','FontSize',10); % Explain sectors and scenarios.
land = nexttile(layout); hold(land,'on'); % Separate rows prevent ambiguous overlapping land-use shading.
zone_colors = [0.55*colors+0.45; 0.85 0.85 0.85]; % Match sector hues with lighter fills; agriculture uses neutral grey.
for j = 1:numel(cities)
    city = cities{j}; row = numel(cities)-j+1; % Baseline row appears above counterfactual row.
    edges = [0 city.scalist.x0 city.scalist.x1 xmax]; % Solved boundaries, not unconstrained bid-rent intersections.
    for zone = 1:3
        width = max(0,edges(zone+1)-edges(zone)); % Clip the displayed rural segment to the figure extent.
        if width > 0
            rectangle(land,'Position',[edges(zone),row-0.22,width,0.44],'FaceColor',zone_colors(zone,:),'EdgeColor','none'); % Display occupied zones.
        end
    end
    text(land,city.scalist.x0,row+0.28,sprintf('CBD %.2f',city.scalist.x0),'FontSize',8,'HorizontalAlignment','center'); % Label CBD boundary in km.
    text(land,city.scalist.x1,row+0.28,sprintf('Fringe %.2f',city.scalist.x1),'FontSize',8,'HorizontalAlignment','center'); % Label urban fringe in km.
    if isfinite(city.params.x1_max) && city.params.x1_max <= xmax
        plot(land,[city.params.x1_max city.params.x1_max],[row-0.28 row+0.25],'k:','LineWidth',1.8); % Show the user-set growth boundary.
    end
end
set(land,'YTick',1:numel(cities),'YTickLabel',fliplr(labels),'FontName','Arial','FontSize',10,'Box','off','XGrid','on','YGrid','on','GridLineStyle',':','GridColor',[0.35 0.35 0.35],'GridAlpha',0.35,'Layer','top'); % Dotted grids align distance ticks and scenario rows.
xlim(land,[0 xmax]); ylim(land,[0.5 numel(cities)+0.6]); % Fit the land-use strips and boundary annotations.
distance_unit = "model distance units"; % Paper parameters alone do not identify a physical distance scale.
if isfield(baseline,'reporting') && isfield(baseline.reporting,'distance'), distance_unit = baseline.reporting.distance; end % Use kilometres only after spatial calibration.
xlabel(land,'Distance from city center ('+distance_unit+')'); % Distances are radial, not two separate halves of the city.
linkaxes([ax land],'x'); % Keep zooming consistent across profiles and land use.
end

