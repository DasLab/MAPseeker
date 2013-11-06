function [Q, rad_res, D_out] = get_Qpred( pdb, epsilon_file, HRF_file );
% Q = get_Qpred( pdb, epsilon_file, HRF_file );
%
%
%pdb = '../P4P6/combined_analysis/1GIDA.pdb';

Q = [];
rad_res = [];
D_out = [];

clf;
D_sim_in = []; D_sim_comp = [];
%rad_atoms = {'C5''', 'O2'''};
rad_atoms = {'O2'''};
hit_atoms = {'C3''','C5''','C4'''};

MAX_D = (1 / 8.0);
for j = 1:length( rad_atoms )
  for i = 1:length( hit_atoms )
    [D_sim_comp, rad_res, hit_res, dist_matrix, pdb] = get_simulated_data( pdb, rad_atoms{j}, hit_atoms{i} );  
    if length( rad_res ) == 0; return; end;
    
    D_sim_comp = min( D_sim_comp, MAX_D );
    %D_sim_comp =  min( (1./dist_matrix).*exp( - dist_matrix./30.0), 1/10.0);
    
    if isempty( D_sim_in ) D_sim_in = D_sim_comp; 
    else D_sim_in = D_sim_in + D_sim_comp; end;
  
  end
end

D_sim_a = D_sim_in/( length(hit_atoms)*length(rad_atoms));
D_sim_a = D_sim_a * 2;
%D_sim_a = min(D_sim_a,1.0);

%D_sim_a = D_sim_in;
%D_sim_a = min( D_sim_in, 1/7.0 ); % cap due to tether length at 10 A.
%D_sim_a =  min( (1./dist_matrix).*exp( - dist_matrix./30.0), 1/10.0);
%D_sim_a = 0.1 * exp( -0.5 * (( dist_matrix - 15.0 )/10.0).^2 );

N = size( D_sim_a, 2 );
% initialize as uniform profile
epsilon_profile = ones(1,N)/10;
if exist( 'epsilon_file', 'var' ) & ischar( epsilon_file ) & length( epsilon_file ) > 0
  if exist( epsilon_file,'file' )
    epsilon = load( 'epsilon.txt' );
    epsilon_profile = zeros(1,N);
    for m=1:length(epsilon)
      epsilon_profile( rad_res == epsilon(m,1) ) = epsilon(m,2);
    end
    epsilon_profile = epsilon_profile/max( epsilon_profile );
  elseif length(epsilon_file) == 1
    epsilon_nt = epsilon_file;
    % pull out sequence
    resSeq = -999; sequence = '';
    for i = 1:length( pdb.Model.Atom )
      if ( pdb.Model.Atom(i).resSeq ~= resSeq )
	resSeq = pdb.Model.Atom(i).resSeq;
	sequence = [sequence, pdb.Model.Atom(i).resName ];
      end
    end
    epsilon_profile = zeros(1,length(sequence));
    epsilon_profile( strfind( sequence, epsilon_nt ) ) = 1.0;
    epsilon_profile = epsilon_profile/4;
  end  
end

HRF_profile = ones(N,1);
if exist( 'HRF_file' )
  HRF = load( HRF_file );
  HRF_smooth = HRF(:,2);
  HRF_smooth = smooth( HRF(:,2),20 );
  for m = 1:length(HRF)
    HRF_profile( rad_res == HRF(m,1) ) = HRF_smooth(m) ;
  end
end

[HRF_i, HRF_j ] = meshgrid( HRF_profile, HRF_profile );
D_sim_HRF = D_sim_a;
%D_sim_HRF = D_sim_a .* HRF_i .* HRF_j;

%subplot(2,1,1);
D_sim_convolve_epsilon_profile = D_sim_HRF * 0;
for i = 1:N
  D_sim_convolve_epsilon_profile(i,:) = D_sim_HRF(i,:) * epsilon_profile(i);
end
D_out = zeros(N,N);
for i = 1:N
  for j = i:N
    D_out(i,j) = D_sim_convolve_epsilon_profile(i,j);
  end
end
image( rad_res, hit_res, D_out' * 5000);
title( 'predicted hits [1/distance]' );
xlabel( 'source')
ylabel( 'cleavage')

hold on
contour_levels = [15,30];
colorcode = [1 0 1; 0 0 1];
dist_matrix_smooth = smooth2d( dist_matrix );
for i = 1:length( contour_levels )
%  [c,h]=contour(rad_res, hit_res, tril(dist_matrix_smooth), ...
%		contour_levels(i) * [1 1],...
%		'color',colorcode(i,:),...
%		'linewidth',0.5 );
end


%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%
Q = zeros( N, N );

D_stop = D_sim_HRF;
for i = 1:N; D_stop(i,i) = max( D_stop(i,i), 1.0) ; end;
D_cleave = D_sim_HRF;

subplot(1,1,1);
for i = 1:N % lig pos
  for j = i:N % cleave pos

    % sources
    %gp = [1:N]; % ordinary
    gp = [1:i, j:N]; %'external' sources only, which will not block RT.
    Q(i,j) = sum( D_stop(i,gp) .* D_cleave(gp,j)' .* epsilon_profile(gp)  * HRF_profile(j));

    % Following converts to approximate 'reactivities'. The denominator is "B", 
    % the 1D cleavage rate.
    %Q(i,j) = Q(i,j) / sum( D_sim_HRF(gp,j)' .* epsilon_profile(gp ) ) / 3;
  
  end
end
Q = max(Q,0);

Z_Q = get_MOHCAseq_zscores( Q, 0*Q, 0.0 );

%image( rad_res, hit_res, Z_Q' * 32 );

image( rad_res, hit_res, (Q-mean(mean(Q')))' * 40 /mean(mean(Q')) );

%title( 'predicted Q = correlation function' );
ylabel( 'stop' );
xlabel( 'cleavage')
gp = find( mod(rad_res, 10 ) == 0 );
set(gca,'xgrid','on','ygrid','on','xtick',rad_res(gp),'ytick',rad_res(gp));

hold on
 
colormap( 1 - gray(100))

for i = 1:length( contour_levels )
  [c,h]=contour(rad_res, hit_res, tril(dist_matrix_smooth), ...
		contour_levels(i) * [1 1],...
		'color',colorcode(i,:),...
		'linewidth',0.5 );
end

drawnow;