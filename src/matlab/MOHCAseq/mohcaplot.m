function mohcaplot( R, csts, secstr, pdb, save_path, titl, seqpos, ligpos, ticksize, c, c2 )

% Plots 2D maps in MOHCA style
%
% INPUTS:
%       R         req  = matrix of data to be plotted or RDAT filename 
%       csts      opt  = Plots contours around locations of previously selected constraint pairs.
%                           Input should be in following form: {{csts},style} 
%                               csts  = Constraint pairs, input as cell array of one or two constraint pair matrices 
%                                       (input two matrices if one set each of strong and weaker csts). For each matrix, 
%                                       column 1 should be RT stop position and column 2 should be cleaved position. 
%                               style = '.' for dots at constraint positions or '|' for contour outlines around 
%                                       constraint pair positions. Default = '.' 
%       secstr    opt  = Plots secondary structure over data.
%                           Input as cell array with {sequence, secstr, offset}. 
%       pdb       opt  = Provides axis limits for showing ROI only (excluding data for any flanking sequences).
%                           Input should be in following form: {pdb,contours} 
%                               pdb      = Path to PDB file as string or structure array from pdbread. 
%                               contours = '1' to plot contours, '0' to not plot contours (15Å and 30Å contours).
%                                          Default = '1'.
%       save_path opt  = Path to save file (including filename) (if none, enter '')
%       titl      opt  = Desired plot title, string (enter '' for default, no title)
%       seqpos    opt  = X-axis values, RT stop positions (enter '' for default, 1 to length of x-axis data in D)
%       ligpos    opt  = Y-axis values, ligation positions (enter '' for default, 1 to length of x-axis data in D)
%       ticksize  opt  = Font size of tick labels (default 15, enter '' for default)
%       c         opt  = Colorcode background for proximity map; default 1 for gray, input other for jet
%       c2        opt  = Colorcode foreground for contours
%
% Clarence Cheng, 2014-2015
%

if ischar( R );
    r = read_rdat_file( R );
    D_plot = prepdata(r.reactivity, r.reactivity_error, 2);
    D_plot = D_plot';   % Transpose matrix for plotting
    seqpos = r.seqpos;
    ligpos = get_ligpos(r);
else
    D_plot = R';        % Transpose matrix for plotting
end
if ~exist( 'seqpos', 'var' ) || isempty( seqpos ); seqpos = 1:size(D_plot,2); end;
if ~exist( 'ligpos', 'var' ) || isempty( ligpos ); ligpos = 1:size(D_plot,1); end;
if ~exist( 'ticksize', 'var' ) || isempty( ticksize ); ticksize = 15; end;
if ~exist( 'titl', 'var' ); titl = ''; end;
if ~exist( 'c', 'var' ) || isempty( c ); c = 1; end;
if ~exist( 'c2','var' ) || isempty( c2 ); c2 = [.5 0 .5; 0.3 0.5 1]; end;

% Make plot
figure;
set(gcf, 'PaperPositionMode', 'Manual','PaperOrientation', 'Landscape','PaperPosition', [-0.65 0.15 12 8],'color','white','Position', [0 0 800 600]);
D_plot( find(D_plot < 0) ) = 0;
image( seqpos, ligpos, 50 * D_plot );
hold on; axis image;
if c == 1; colormap( 1-gray ); else colormap( jet ); c2 = [1 0 1; 1 1 1]; end;

% Label x and y axes
gp = find( mod(seqpos,10) == 0 );
set(gca,'xtick',seqpos(gp), 'fontsize',ticksize )
gp = find( mod(ligpos,10) == 0 );
set(gca,'ytick',ligpos(gp), 'fontsize',ticksize )
set(gca,'TickDir','out');
% set(gca,'xgrid','on','ygrid','on','fonts',ticksize);
xlabel( 'Reverse transcription stop position [5´]','fontsize',ticksize+5,'fontweight','bold' );
ylabel( 'Cleaved and ligated position [3´]','fontsize',ticksize+5,'fontweight','bold' );
hold on;

% Add title
title( titl, 'fontsize', ticksize+5, 'fontw', 'bold','interp','none' );

% Overlay constraints
if exist( 'csts', 'var' ) && ~isempty( csts );
    cstslist = csts{1}; style = csts{2};

    if style == '.'
        for i = 1:length(cstslist)
            hold on;
            if i == 1
                scatter(cstslist{i}(:,1),cstslist{i}(:,2),'m','filled');
            elseif i >= 2
                scatter(cstslist{i}(:,1),cstslist{i}(:,2),'m');
            end
        end
    elseif style == '|'
        if length(cstslist) > 1
            allcsts = [cstslist{1};cstslist{2}];
        else
            allcsts = cstslist{1};
        end

        D_temp = D_plot';
        diagnal = diag(D_temp(allcsts(:,1),allcsts(:,2)));
        diagmax = max(diagnal);
        D_temp = D_plot*0;

        for j = 1:size(allcsts,1)
            xrng = max(allcsts(j,1)-2,1):min(allcsts(j,1)+2,seqpos(end));
            yrng = max(allcsts(j,2)-2,1):min(allcsts(j,2)+2,seqpos(end));
            D_temp(yrng,xrng) = D_plot(yrng,xrng)*diagmax/diagnal(j);
        end

        hold on; contour(seqpos,ligpos,tril(D_temp),[1 1],'color',[1 0 1],'linewidth',1.5);
    end
    
end

% Overlay secondary structure
if exist( 'secstr', 'var' ) && iscell(secstr) && length( secstr )>1;
    seq = secstr{1};
    str = secstr{2};
    offset = secstr{3};
    for i = 1:length(secstr{1})
        data_types{i} = num2str(i);
    end
    area_pred = generate_area_pred(seq, str, 0, data_types, length(secstr{1}));
    % in future, use sequence and secstruct from rdat and crop to correct size
    [x_pred, y_pred] = find(area_pred);
    x_pred = x_pred + offset;
    y_pred = y_pred + offset;
    plot(x_pred, y_pred, '.', 'color', [1 0 1]); hold on;
end

% Overlay tertiary structure contours
if exist( 'pdb', 'var' ) && ~isempty( pdb )
    contours = 1;
    if iscell( pdb ) 
        pdbvar = pdb{1};
        if length( pdb ) > 1; contours = pdb{2}; end;
    else
        assert( ischar(pdb) );
        pdbvar = pdb;
    end
    [D_sim, res_rad, res_hit, dist_matrix, pdbstruct] = get_simulated_data( pdbvar );
    
    if contours ~= 0
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
                contour(res_rad, res_hit, tril(dist_smooth), ...
                    contour_levels(i) * [1 1],...
                    'color',c2(i,:),...
                    'linewidth', 1.5 );
                legends{i} = [num2str(contour_levels(i)),' Ångstrom'];
                hold on;
            end
        end
        if ~isempty( legends ); legend( legends, 'location', 'BestOutside' ); end;
    end
    % Set axis limits (crop to ROI)
    axis( [min(res_rad)-0.5 max(res_rad)+0.5 min(res_hit)-0.5 max(res_hit)+0.5 ]);
else
    axis( [min(seqpos)-0.5 max(seqpos)+0.5 min(ligpos)-0.5 max(ligpos)+0.5 ]);
end;

% Rotate xticklabels and reposition
xticklabel = get(gca,'XTickLabel');
set(gca,'XTickLabel','');
hxLabel = get(gca,'XLabel');
set(hxLabel,'Units','data');
xLabelPosition = get(hxLabel,'Position');
y = xLabelPosition(2)-2;
XTick = str2num(str2mat(xticklabel))+1;
y = repmat(y,length(XTick),1);
hText = text(XTick,y,xticklabel,'fontsize',ticksize);
set(hText,'Rotation',90,'HorizontalAlignment','right');
xlab = get(gca,'XLabel');
set(xlab,'Position',get(xlab,'Position') + [0 6 0]);


% Save figure
if exist( 'save_path', 'var' ) && ~isempty( save_path );
    print( gcf, '-depsc2', '-loose', '-r300', save_path);
    fprintf( ['Created: ', save_path, '\n'] );
    hgsave( save_path );
end;