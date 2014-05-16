function mohcaplot( D, seqpos, ligpos, titl, ticksize, save_path, pdb_path, contours )

% Plots 2D maps in MOHCA style
%
% INPUTS:
%       D       = matrix of data to be plotted
%       seqpos  = x-axis values, RT stop positions
%       ligpos  = y-axis values, ligation positions
%       titl    = desired plot title, string
%       ticksize  = font size of tick labels
%       save_path = path to save file (including filename)
%       pdb_path  = path of PDB file, provides axis limits for showing ROI only 
%       contours  = enter 1 if want to plot contours from pdb file; default does not plot contours 
%
% Clarence Cheng, 2014
%

if ~exist( 'ticksize', 'var' ); ticksize = 25; end
if ~exist( 'titl', 'var' ); titl = ''; end
% if ~exist( 'contours', 'var' ); contours = ''; end

% Make plot
figure;
set(gcf, 'PaperPositionMode','auto','color','white');
image( seqpos, ligpos, 50 * D' );
axis image;
colormap( jet );

% Label x and y axes
gp = find( mod(seqpos,10) == 0 );
set(gca,'xtick',seqpos(gp) )
gp = find( mod(ligpos,10) == 0 );
set(gca,'ytick',ligpos(gp) )
set(gca,'TickDir','out');
set(gca,'xgrid','on','ygrid','on','fonts',ticksize,'fontw','bold');
xlabel( 'Reverse transcription stop position [5'']','fontsize',25,'fontweight','bold' );
ylabel( 'Cleaved and ligated position [3'']','fontsize',25,'fontweight','bold' );
hold on;

% Add title
title( titl, 'fonts', 15, 'fontw', 'bold' );

if exist( 'pdb_path', 'var' )
    [D_sim, res_rad, res_hit, dist_matrix, pdbstruct] = get_simulated_data( pdb_path );

    if exist( 'contours', 'var' )
        % Define contour levels and colors
        contour_levels = [15,30];
        % colorcode = [1 0 1; 0.75 0.6 0.9];
        colorcode = [1 0 1; 1 0.8 1];

        % Add legends (NOTE: Å = char(197) for Ångstrom?)
        legends = {};
        if ~isempty( dist_matrix );
          dist_smooth = smooth2d( dist_matrix );
          for i = 1:length( contour_levels )
            [c,h]=contour(res_rad, res_hit, tril(dist_smooth), ...
                  contour_levels(i) * [1 1],...
                  'color',colorcode(i,:),...
                  'linewidth', 1.2 );
            legends{i} = sprintf( '%d Ångstrom', contour_levels(i) );
          end
        end
        if length( legends ) > 0; legend( legends ); end;
    end

    % Set axis limits (crop to ROI)
    axis( [min(res_rad)-0.5 max(res_rad)+0.5 min(res_hit)-0.5 max(res_hit)+0.5 ]);
else
    axis( [min(seqpos)-0.5 max(seqpos)+0.5 min(ligpos)-0.5 max(ligpos)+0.5 ]);
end    

% Rotate xticklabels and reposition
xticklabel = get(gca,'XTickLabel');
set(gca,'XTickLabel','');
hxLabel=get(gca,'XLabel');
set(hxLabel,'Units','data');
xLabelPosition=get(hxLabel,'Position');
y=xLabelPosition(2) - 7;
XTick=str2num(xticklabel)+1;
y=repmat(y,length(XTick),1);
fs = get(gca,'fonts');
hText=text(XTick,y,xticklabel,'fonts',ticksize,'fontw','bold');
set(hText,'Rotation',90,'HorizontalAlignment','right');
xlab=get(gca,'XLabel');
set(xlab,'Position',get(xlab,'Position') + [0 7 0]);

% Make colorbar legend
hc = colorbar('location','eastoutside');
hcm = max(get(hc,'YLim'));
set(hc,'YTick',[0.5 hcm-0.5]);
set(hc,'YTickLabel',{'0.0','1.0'});
hcp = get(hc,'pos');
pos = get(gca,'pos');
set(hc,'position',[hcp(1)*0.92 hcp(2) hcp(3)*0.5 pos(4)*0.25],'fonts',25,'fontw','bold');

% Save figure
if exist( 'save_path', 'var' )
    if ~isempty( save_path )
        print( '-depsc2', save_path);
    end
end