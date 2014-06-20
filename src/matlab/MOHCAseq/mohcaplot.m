function mohcaplot( D, seqpos, ligpos, titl, ticksize, subplt, save_path, secstr, pdb, contours, c, c2 )

% Plots 2D maps in MOHCA style
%
% INPUTS:
%       D         req  = matrix of data to be plotted
%       seqpos    opt  = x-axis values, RT stop positions (enter '' for default, 1 to length of x-axis data in D)
%       ligpos    opt  = y-axis values, ligation positions (enter '' for default, 1 to length of x-axis data in D)
%       titl      opt  = desired plot title, string (enter '' for default, no title)
%       ticksize  opt  = font size of tick labels (default 25, enter '' for default)
%       subplt    opt  = option to make plots as subplots in a single figure (default is to make a new figure) 
%       save_path opt  = path to save file (including filename) (if none, enter '')
%       secstr    opt  = cell array with {sequence, secstr, offset, data_types, numlanes}
%       pdb       opt  = path of PDB file or pdbstruct from pdbread, provides axis limits for showing ROI only
%       contours  opt  = enter 1 if want to plot contours from pdb file; default does not plot contours
%       c         opt  = colorcode background (1 for jet, 2 for gray)
%       c2        opt  = colorcode foreground ([0 0 1; 1 0 1] 'm' default)
%
% Clarence Cheng, 2014
%

if ~exist( 'seqpos', 'var' ) || isempty( seqpos ); seqpos = 1:size(D,2); end;
if ~exist( 'ligpos', 'var' ) || isempty( ligpos ); ligpos = 1:size(D,1); end;
if ~exist( 'ticksize', 'var' ) || isempty( ticksize ); ticksize = 15; end;
if ~exist( 'titl', 'var' ); titl = ''; end;
if ~exist( 'contours', 'var' ) || isempty( contours ); contours = 0; end;
if ~exist( 'c', 'var' ) || isempty( c ); c = 1; end;
if ~exist( 'c2','var' ) || isempty( c2 ); c2 = [0 0 1; 1 0 1]; end;
if ~exist( 'subplt', 'var' ) || isempty( subplt ); newfig = 1; else newfig = 0; end
% c2 = [1 0 1; 0.75 0.6 0.9];

% Transpose matrix for plotting
D = D';

% Make plot
if newfig; figure; elseif ~newfig; subplot(subplt(1),subplt(2),subplt(3)); end
set(gcf, 'PaperPositionMode', 'Manual','PaperOrientation', 'Landscape','PaperPosition', [-0.65 0.15 12 8],'color','white','Position', [0 0 800 600]);
image( seqpos, ligpos, 50 * D );
hold on; axis image;
if c == 1; colormap( jet); else colormap( 1-gray ); end;

% Label x and y axes
gp = find( mod(seqpos,10) == 0 );
set(gca,'xtick',seqpos(gp) )
gp = find( mod(ligpos,10) == 0 );
set(gca,'ytick',ligpos(gp) )
set(gca,'TickDir','out');
set(gca,'xgrid','on','ygrid','on','fonts',ticksize);
xlabel( 'Reverse transcription stop position [5´]','fontsize',ticksize+5,'fontweight','bold' );
ylabel( 'Cleaved and ligated position [3´]','fontsize',ticksize+5,'fontweight','bold' );
hold on;

% Add title
title( titl, 'fonts', ticksize+5, 'fontw', 'bold','interp','none' );

% Rotate xticklabels and reposition
%xticklabel_rotate;
xticklabel = get(gca,'XTickLabel');
set(gca,'XTickLabel','');
hxLabel = get(gca,'XLabel');
set(hxLabel,'Units','data');
xLabelPosition = get(hxLabel,'Position');
y = xLabelPosition(2) - 7;
XTick = str2num(xticklabel)+1;
y = repmat(y,length(XTick),1);
hText = text(XTick,y,xticklabel,'fonts',ticksize);
set(hText,'Rotation',90,'HorizontalAlignment','right');
xlab = get(gca,'XLabel');
set(xlab,'Position',get(xlab,'Position') + [0 7 0]);

% Make colorbar legend
hc = colorbar('location','eastoutside');
hcm = max(get(hc,'YLim'));
set(hc,'YTick',[0.5 hcm-0.5]);
set(hc,'YTickLabel',{'0.0','1.0'});
%  hcp = get(hc,'pos');
%  pos = get(gca,'pos');
%  set(hc,'position',[hcp(1)*0.92 hcp(2) hcp(3)*0.5 pos(4)*0.25],'fonts',25,'fontw','bold');

% Overlay secondary structure
if exist( 'secstr', 'var' ) && ~isempty( secstr );
    seq = secstr{1};
    str = secstr{2};
    for i = 1:length(secstr{1})
        data_types{i} = num2str(i);
    end
    area_pred = generate_area_pred(seq, str, 0, data_types, length(secstr{1}));
    % in future, use sequence and secstruct from rdat and crop to correct size
    [x_pred, y_pred] = find(area_pred);
    x_pred = x_pred - 1 + seqpos(1);
    y_pred = y_pred - 1 + ligpos(1);
    plot(x_pred, y_pred, '.', 'color', [1 0 1]); hold on;
end

% Overlay tertiary structure contours
if exist( 'pdb', 'var' ) && ~isempty( pdb ) && contours == 1;
    [D_sim, res_rad, res_hit, dist_matrix, pdbstruct] = get_simulated_data( pdb );
    
    if exist( 'contours', 'var' )
        % Define contour levels and colors
        contour_levels = [15,30];
        
        % Add legends (NOTE: Å = char(197) for Ångstrom?)
        legends = cell(1, length(contour_levels));
        
        if max(res_rad)-min(res_rad) == max(seqpos)-min(seqpos) && ...
                max(res_hit)-min(res_hit) == max(ligpos)-min(ligpos);
            res_rad = seqpos;
            res_hit = ligpos;
        end;
        if ~isempty( dist_matrix );
            dist_smooth = smooth2d( dist_matrix );
            for i = 1:length( contour_levels )
                contour(res_rad, res_hit, dist_smooth, ...
                    contour_levels(i) * [1 1],...
                    'color',c2(i,:),...
                    'linewidth', 1 );
                legends{i} = [num2str(contour_levels(i)),' Ångstrom'];
                hold on;
            end
        end
        if ~isempty( legends ); legend( legends ); end;
    end
    
    % Set axis limits (crop to ROI)
    axis( [min(res_rad)-0.5 max(res_rad)+0.5 min(res_hit)-0.5 max(res_hit)+0.5 ]);
else
    axis( [min(seqpos)-0.5 max(seqpos)+0.5 min(ligpos)-0.5 max(ligpos)+0.5 ]);
end;

% Save figure
if exist( 'save_path', 'var' ) && ~isempty( save_path );
    print( gcf, '-depsc2', '-loose', '-r300', save_path);
    fprintf( ['Created: ', save_path, '\n'] );
end;