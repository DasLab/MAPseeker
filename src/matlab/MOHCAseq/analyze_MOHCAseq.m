function [Zscores_mask, Zscores_mask_err, D_sim, pdbstruct, D_combine, Zscores, Zscores_err] = analyze_MOHCAseq( D, D_err, D_raw, plot_heads, offset, tail_length, seqstart, pdb, sample_sel, source_locs, printfig )

%%%
%%%  INPUTS
%%%     D:              Cell array of reactivities, output by MAPseeker 
%%%     D_err:          Cell array of errors in reactivities, output by MAPseeker 
%%%     D_raw:          Cell array of raw counts, output by MAPseeker
%%%     plot_heads:     Headers for plots formatted as cell array of strings (e.g. {'MOHCA-Seq, P4P6modA, +ascorbate','MOHCA-Seq, P4P6modA, -ascorbate', ...}) 
%%%     offset:         Number of nucleotides before the 5' end of the RNA sequence of interest (e.g. length of 5'-buffer region and reference hairpin) 
%%%     tail_length:    Number of nucleotides after the 3' end of the RNA sequence of interest (e.g. length of 3'-buffer region, reference hairpin, and Tail2) 
%%%     seqstart:       Number of the 5' nucleotide in the .pdb file 
%%%   (OPTIONAL)
%%%     pdb:            Either a string name of a .pdb file or a structure array produced by the pdbread function 
%%%     sample_sel:     Indices of arrays in D from which Z-scores for coloring structures by data will be drawn 
%%%     source_locs:    Locations of interest for getting text files of Z-scores for color_by_data using PyMol 
%%%     printfig:       Determines whether figures will be saved to a folder called "Figures_Analysis" (0 for no, 1 for yes, default 1) 
%%%
%%%  OUTPUTS
%%%     Zscores_mask:        Z-scores of masked reactivities from input D (high-uncertainty reactivities masked before Z-score calculation) 
%%%     Zscores_mask_err:    Errors of Z-scores of masked reactivities, propagated from input D_err 
%%%     D_sim:               Data of simulated Z-scores of reactivities from input D
%%%     pdbstruct:           Either structure array from pdbread(pdb) or simply the input pdb 
%%%     D_combine:           Overlaid data of Zscores_mask and D_sim 
%%%     Zscores:             Z-scores of reactivities from input D (reactivities not masked before Z-score calculation) 
%%%     Zscores_err:         Errors of Z-scores of reactivities, propagated from input D_err
%%%
%%%
%%% 1. Get Z-scores w/propagated errors of unnormalized reactivities
%%% 2. Make figures for summarizing data and comparing Z-score calculation (w/ or w/o masked reactivities) 
%%% 3. Optional: Simulate MOHCA-Seq data from PDB file
%%% 4. Optional: Generate text files of data to be used for coloring .pdb structures by masked Z-scores 
%%%
%%%
%%% (C) Clarence Cheng, 2013



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 1. Get Z-scores w/propagated errors of unnormalized reactivities

fprintf('\nGenerating Z-scores...\n\n');

Zscores = cell(1,length(D));
Zscores_err = cell(1,length(D_err));

Zscores_mask = cell(1,length(D));
Zscores_mask_err = cell(1,length(D_err));

for n = 1:length(D)
    [Zscores{1,n}, Zscores_err{1,n}, Zscores_mask{1,n}, Zscores_mask_err{1,n}] = get_MOHCAseq_zscores(D{1,n}, D_err{1,n}, 1);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 2. Make figures for summarizing data and comparing Z-score calculation (w/ or w/o masked reactivities) 

if length(D) ~= length(plot_heads)
    fprintf('Warning! You must supply the same number of plot headers as the number of data arrays! \n');
    return;
end


set(gcf,'pointer','fullcross');

fprintf('Plotting Z-score and summary figures...\n\n');

for n = 1:length(D)

    figure(n); %clf reset;
    fig_MOHCAseq( Zscores_mask{1,n},      50, 1-gray(100), plot_heads(n), '2D Z-scores; mask reactivities',             offset, tail_length, seqstart, 2, 2, 1, 1 );
    fig_MOHCAseq( Zscores_mask_err{1,n},  25, jet,         plot_heads(n), '2D errors of Z-scores; mask reactivities',   offset, tail_length, seqstart, 2, 2, 3, 1 );
    fig_MOHCAseq( D_raw{1,n},         5, 1-gray(100), plot_heads(n), '2D raw counts',                              offset, tail_length, seqstart, 2, 2, 2, 1 );
    fig_MOHCAseq( D{1,n},            50, 1-gray(100), plot_heads(n), '2D reactivities',                            offset, tail_length, seqstart, 2, 2, 4, 1 );
    
    fignum = length(D)+n;
    figure(fignum); clf reset;
    fig_MOHCAseq( Zscores_mask{1,n}, 50, 1-gray(100), plot_heads(n), '2D Z-scores; mask reactivities', offset, tail_length, seqstart, 1, 1, 1, 0 );
    
end

% for n = 1:length(D)
%     fignum = length(D)+n;
%     figure(fignum); clf reset;
%     
%     fig_MOHCAseq( Zscores{1,n},           50, 1-gray(100), plot_heads(n), '2D Z-scores; no masking',                  offset, tail_length, seqstart, 2, 2, 1 );
%     fig_MOHCAseq( Zscores_err{1,n},       25, jet,         plot_heads(n), '2D errors of Z-scores; no masking',        offset, tail_length, seqstart, 2, 2, 3 );
%     fig_MOHCAseq( Zscores_mask{1,n},      50, 1-gray(100), plot_heads(n), '2D Z-scores; mask reactivities',           offset, tail_length, seqstart, 2, 2, 2 );
%     fig_MOHCAseq( Zscores_mask_err{1,n},  25, jet,         plot_heads(n), '2D errors of Z-scores; mask reactivities', offset, tail_length, seqstart, 2, 2, 4 );
%     
% end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 3. Optional: Simulate MOHCA-Seq data from PDB file



if ~exist('pdb')
    fprintf('No PDB file or structure array detected...\n\n');
else
    fprintf('PDB file or structure array detected... Generating simulated and overlaid contact maps...\n\n');
    fignum_start = 2*length(D)+1;
    pdbname = inputname(8);
    [D_sim, pdbstruct, D_combine] = sim_MOHCAseq( pdb, pdbname, offset, tail_length, fignum_start, plot_heads, Zscores_mask, 1 );
end






%%% Save figures as .fig and .eps files

if ~exist( 'printfig' ); printfig = 1; end
if printfig == 1
    tag = pwd;
    if tag(end) == '/'; tag = tag(1:end-1); end; % get rid of final slash
    %  just get the last directory name.
    tags = split_string( tag, '/' );
    tag = tags{ end };    
    for n = 1:length(D)
        print_save_figure(figure(n), [tag,'_',num2str(n),'_DataAnalysis'], 'Figures_Analysis', 1);
        print_save_figure(figure(length(D)+n), [tag,'_',num2str(n),'_Zscores'], 'Figures_Analysis', 1);
%         print_save_figure(figure(length(D)+n), [tag,'_',num2str(n),'_CompareMasking'], 'Figures_Analysis', 1);
    end
else
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 4. Optional: Generate text files of data to be used for coloring .pdb structures by masked Z-scores 

%%% IF NO SOURCE_LOCS, tile in 3x3 squares and find points where maximum value is in center, then use the sequence positions of those points to get data for 3d color?
%%% IF SOURCE_LOCS provided, use source_locs to generate data for 3d color.  


if ~exist( 'sample_sel' );

else
    if ~exist( 'source_locs' );
        fprintf( 'Z-scores for coloring structures by data will be drawn from data for primer %1.0f \n', sample_sel );
        fprintf( 'Creating text files to color structures by data...radical source locations will be automatically detected... \n' );
        fprintf( 'This is still under development....' );

    
    elseif exist( 'source_locs' );
        fprintf( 'Z-scores for coloring structures by data will be drawn from data for primer %1.0f \n', sample_sel );
        fprintf( 'Creating text files to color structures by data...radical source locations from user input... \n' );
        fprintf( 'Radical source locations: %4.0f \n', source_locs );
    
        seqrange = (offset+2):(length(D{1,1})-tail_length);
    
        source = [];
        source2 = [];
    
        for m = 1:length(sample_sel)
            sourceN = [];
            filenames = {};
            for n = 1:length(source_locs)
                sourceN = [sourceN; Zscores{1,sample_sel(m)}(source_locs(n),:)];
                source = [source; sourceN];
                filenames{n} = strcat('pr',num2str(sample_sel(m)),'-pos',num2str(source_locs(n)),'-nt',num2str(seqstart + source_locs(n) - (offset+2)));
            end
            sourceN = transpose(sourceN);
            %fprintf( 'Enter conditions for primer %1.0f: \n', sample_sel(m) );
            data_for_3d_color(sourceN, seqrange, seqstart, filenames);
            source2 = [source2 sourceN];
        end
    
    end

end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% fig_MOHCAseq: helper function to make figures

function fig_MOHCAseq( D, scale, colmap, head, head2, offset, tail_length, seqstart, plotsubx, plotsuby, plotsubn, shiftx )     %plotsubs are the x, y, and n values that determine which subplot the image is plotted in

subplot(plotsubx, plotsuby, plotsubn);

image(transpose(D)*scale);
axis image; colormap(colmap);
title([head, head2]);

set(gca,'Xtick',0:10:length(D));
set(gca,'Ytick',0:10:length(D));
set(gca,'Xticklabel',{seqstart - (offset+2) : 10 : seqstart + length(D) - (offset+2)});
set(gca,'Yticklabel',{seqstart - (offset+2) + 1 : 10 : seqstart + length(D) - (offset+2) + 1});     % Add 1 to y-axis (hit position) tick labels b/c hit position detected is 1 nt 5' of actual hit position (hit causes loss of the nt at the true hit position)
xlabel('Radical source position');
ylabel('Pairwise hit position');
xticklabel_rotate; freezeColors;

make_lines(offset + 1,'m',0.5);                                   % Offset is the number of nucleotides in the probed sequence before the first nucleotide in the xtal structure
make_lines_horizontal(offset,'m',0.5);                            % Don't add 1 to offset because detected hit position is 1 nt 5' of true hit position
make_lines(length(D) - tail_length,'g',0.5);
make_lines_horizontal(length(D) - (tail_length + 1),'g',0.5);       % Add an extra 1 to tail_length because detected hit position is 1 nt 5' of true hit position

if shiftx == 1
    get(get(gca,'Xlabel'),'Position');
    set(get(gca,'Xlabel'),'Position',get(get(gca,'Xlabel'),'Position')+[0 0.07 0]);
else
    get(get(gca,'Xlabel'),'Position');
    set(get(gca,'Xlabel'),'Position',get(get(gca,'Xlabel'),'Position')+[0 0.02 0]);    
end
% ylab = get(gca,'Ylabel');
% set(ylab,'Position',get(ylab,'Position')+[0.07 0 0]);






