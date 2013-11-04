function [D_sim_a, rad_res, hit_res, dist_matrix, pdbstruct] = get_simulated_data( pdb, rad_atom, hit_atom );
%%% [D_sim_a, rad_res, hit_res, dist_matrix, pdbstruct] = get_simulated_data( pdb );
%%%
%%% Script for simulating MOHCA contact maps (O2' to C4'), with vectorized distance 
%%%     computation 
%%%
%%%  INPUT
%%%     pdb      : PDB file name or pdbstruct object from pdbread.
%%%
%%%  OUTPUTS
%%%     D_sim_a:       Data of simulated contact probabilities
%%%     rad_res:       Residue numbers corresponding to radical source positions [5' stops]
%%%     hit_res:       Residue numbers corresponding to ligation positions [3' ends + 1,
%%%                        i.e., the sites actually hit by radicals.]
%%%     dist_matrix:   Matrix of O2' (rad_res) to C4' (hit_res) distances.
%%%     pdbstruct:     Object form pdbread
%%%
%%%
%%% (C) Clarence Cheng, R. Das, 2013


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 1. Read in PDB file (or copy to variable)

if ischar(pdb)
    %fprintf('Input is .pdb file... reading in .pdb file... \n\n');
    pdbstruct = pdbread(pdb);
    pdbname = pdb;
elseif isstruct(pdb)
    %fprintf('Input is structure array... reading in structure array... \n\n');
    pdbstruct = pdb;
end
D_sim_a = []; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 2. Figure out atoms.
if ~exist( 'rad_atom' ) rad_atom = 'O2'''; end;
if ~exist( 'hit_atom' ) hit_atom = 'C4'''; end;
[rad_atom, hit_atom] = figure_out_atoms( pdbstruct, rad_atom, hit_atom );
[rad_x, rad_y, rad_z, rad_pos, rad_res ] = get_atoms( pdbstruct, rad_atom );
[hit_x, hit_y, hit_z, hit_pos, hit_res ] = get_atoms( pdbstruct, hit_atom );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 3. Calculate pairwise distances between 2'-OH of 'source position' and 
%%%     C4' of 'hit position'. Vectorized for speed.

dist_matrix_raw = sqrt( d2_matrix( rad_x, hit_x ) + d2_matrix( rad_y, hit_y )  + d2_matrix( rad_z, hit_z ) );
dist_matrix( rad_pos, hit_pos )  = dist_matrix_raw;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 4. Convert distances to hit probability
D_sim_a( rad_pos, hit_pos ) = 1 ./ dist_matrix_raw;


%%% 5. Detect whether there were any gaps in the pdb sequence and fill them
%%% in if so - prevents a dimension mismatch during smoothMOHCA
test = max(rad_res) - min(rad_res);
if test > length(rad_res)
    rad_res1 = rad_res;
    rad_res = min(rad_res):max(rad_res);
    hit_res1 = hit_res;
    hit_res = min(hit_res):max(hit_res);
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [xi,yi,zi,pos,res_seq] = get_atoms( pdbstruct, rad_atom );

seqstart = pdbstruct.Model.Atom(1,1).resSeq;

count = 0;
for i = 1:length(pdbstruct.Model.Atom)
  if strcmp(pdbstruct.Model.Atom(1,i).AtomName, rad_atom)
    count = count + 1;
    xi( count ) = pdbstruct.Model.Atom(1,i).X;
    yi( count ) = pdbstruct.Model.Atom(1,i).Y;
    zi( count ) = pdbstruct.Model.Atom(1,i).Z;
    pos( count ) = pdbstruct.Model.Atom(1,i).resSeq - seqstart + 1;
    res_seq( count ) = pdbstruct.Model.Atom(1,i).resSeq;
  end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dist2 = d2_matrix( rad_x, hit_x )

[rad_grid, hit_grid ] = meshgrid( rad_x, hit_x );
dist2 = ( rad_grid - hit_grid ).^2;
dist2 = dist2'; % some silly meshgrid thing.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [rad_atom, hit_atom] = figure_out_atoms( pdbstruct, rad_atom, hit_atom );

for i = 1:20
  if strcmp(pdbstruct.Model.Atom(1,i).AtomName, rad_atom)
    atomname = 1;
  elseif strcmp(pdbstruct.Model.Atom(1,i).AtomName, strrep( rad_atom, '''', '*' ) );
    atomname = 2;
  end
end

if atomname == 2;
  rad_atom = strrep( rad_atom, '''', '*' );
  hit_atom = strrep( hit_atom, '''', '*' );
  %fprintf('2''-OH atom name: %s\n\n', 'O2*');
end

if ~exist('atomname')
  fprintf('Warning! Unable to detect a 2''-OH atom name...\n\n');
  return
end



