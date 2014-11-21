<h1>MAPseeker, v1.0</h1>
(C) R. Das, 2013-2014; C. Cheng, 2014;  J.P. Bida, R. Das, 2012.

E-mail: rhiju [at] stanford.edu.

<h2>LICENSE</h2>

This project can only be accessed and used in compliance with
the license, which can be viewed [here](LICENSE.txt).

<h2>General information</h2>

Multiplexed Accessibility Probing read out through next 
generation Sequencing (MAP-seq) leverages multiple chemical 
modification strategies to give information-rich structural 
data on pools of RNAs. 

A stable version of the experimental protocol is described
in a chapter of Methods in Molecular Biology, which is available 
on the Das lab website at:
http://daslab.stanford.edu/pdf/Seetin_MAPseq_MiMB2013.pdf

(1) The MAPseeker executable.  
  Takes as input your FASTQ files from an Illumina run, 
sequences of the RNAs probed, and sequences of the reverse 
transcription primers. Outputs text files with raw counts of 
how many reads corresponded to each reverse transcription 
stop for each RNA probed -- one file for each primer used. 
Written in C++ for speed, leveraging the excellent
SEQAN library. This software was developed 
because of artefacts and severe slowdowns that we 
encountered with Bowtie (used by Lucks & colleagues, 2011) 
and BWA.

(2) quick_look_MAPseeker() 
  A function in MATLAB which reads the output for MAPseeker 
  and makes summary plots for your notebook.

(3) A collection of useful helper scripts
  In Python, for pre-processing RNA fasta files if desired.
  In MATLAB, for converting counts to chemical reactivities, 
  subtracting backgrounds, outputting to RDAT text formats 
  for sharing.

(4) RDATkit
  Scripts needed to read/write in RDAT format.

<h2>How to install</h2>

To compile the main MAPseeker executable,  go to 

  src/cmake/

and follow instructions in the README there for compilation. 

<h2>Example run</h2>

<h3>1. Converting FASTQs to meaningful structure mapping data</h3>

Some example data is included to test the scripts, involving MAP-seq data 
for 1M7 probing of a large set of RNAs including two 'control' constructs 
doped in at higher concentrations.

Go to example/

There are four files:

 PhiX_S1_L001_R1_001.first100000.fastq
 PhiX_S1_L001_R2_001.first100000.fastq
   First 100,000 lines of forward and reverse read files
   from a miseq run. The PhiX is a silly tag (most of the
   run is not the PhiX genome).

 primers.fasta
   Primers used in the run in FASTA format. 
   The headers describe the conditions used in the experiments
   probed by each primer (the first two use the 1M7 
   2'-OH acylating reagent, three used a mock treatment.) 

   Primers that are 'mock' or control measurements should
   include a tab-delimited field 'no mod', which will
   allow their recognition by scripts below.

   In this example, two in vitro transcribed RNA libraries 
   were tested (one that involved a PAGE purification 
   at an early DNA preparation step, and one that did not.)

 RNA_sequences.fasta
   Two of the ~4000 sequences tested in this run. 
   In FASTA format.
 
   If you have included a sequence with
   reference segments as an 'internal standard',
   that is wonderful and can really help the
   analysis. See below ('Referencing').

If you are using MATLAB, you can skip ahead to the next section, and
the command will be run for you by quick_look_mapseeker() if it sees two FASTQ files
and no files like stats_ID1.txt.

Run the command:

MAPseeker -1 PhiX_S1_L001_R1_001.first100000.fastq  -2 PhiX_S1_L001_R2_001.first100000.fastq  -l RNA_sequences.fasta  -p primers.fasta  -n 8

These are all the input files. The final argument "-n 8" 
specifies that the first 8 residues read by the reverse 
transcription primer should be used by MAPseeker to figure 
out the RNA's ID. It is assumed that your library has unique 
3' sequences just ahead of the reverse transcription binding site.

The output should include the following purification table:

Purification table
25000 total
11594 found primer binding site
10641 found expt ID site
10641 found match in RNA sequence (read 1)
1339 found match in RNA sequence (read 2)

The loss of signal in the last step is due to the fact that only 
about 10% of the library are the two doped in sequences specified in 
RNA_sequences.fasta. [We could get most of the rest of the reads 
if we specify the other sequences, which we're not doing here for simplicity.]
This example run should take less than 1 second; for a real data 
set, this can take minutes or longer.

There are five outputted text files, stats_ID1.txt through stats_ID5.txt. 

They correspond to the 5 primers used. Each is a matrix of numbers. 
(They are not integers because MAPseeker spreads out counts to 
multiple stop sites if they are all equally consistent with a read.) 
Each row of the matrix is a different RNA. Each column of the matrix 
is a stop site. In particular, the first stop site corresponds 
to fully extended product ('site 0'); the second number corresponds 
to the product that stopped right before residue 1 ('site 1'), 
etc. There are N+1 columns, where N is the number of residues 
in the longest RNA probed.


<h3>2. Visualizing & processing the run.</h3>

To view these files, you can use any plotting program (MATLAB, 
gnuplot, matplotlib in python). 

We use MATLAB scripts, available in 

src/matlab/ 

Include this in your MATLAB path. And if you don't already
have the RDATkit scripts installed, its bundled with map_seeker, 
so you just need to also add to your MATLAB path :

xternal/rdatkit/matlab_scripts/

Now run from within MATLAB:

full_length_correction_factor = 0.5;
quick_look_MAPseeker( 'RNA_sequences.fasta','primers.fasta','./',full_length_correction_factor)

If you don't specify the arguments, that will actually work here, 
as the script will assume that the RNA library file, primer 
FASTA file, and working directory with stats_ID1.txt, etc. 
are the ones used above.

The 'full_length_correction_factor' provides a global estimate of
ligation bias for the fully extended cDNA compared to partially extended
cDNAs. In our hands, circLigase gives a bias of ~0.5 even with
optimized solution conditions (e.g., PEG). If you included
an internal standard RNA in your run (see below 'Referencing'),
then don't specify full_length_correction_factor  and it will
automatically be figured out. That's the best practice here.
Otherwise, the factor will be assumed to be ~0.5.

This gives a histogram of counts per primer, and counts per 
RNA (Figure 1); visualization of the counts (with estimated errors) 
for the four most highly represented RNAs (in this case two); 
and 'reactivities', corrected for reverse transcriptase 
attenuation as follows:

  R(site i) = F(site i)/[F(site 0) + F(site 1) + ... + F(site i) ]

Both 1D profiles are shown (Figures 2 and 3), as well 
as 2D representations of the entire data set (Figures 4 
and 5). 

If at least one of the primers corresponds to 
a control reaction without modification ('no mod'), 
background subtraction will also be carried out
automatically (Figure 6), and the 'no mod' data will be 0.

All figures are also automatically saved to disk as EPS files,
which you can print for your notebook.

The text output is also saved to disk as MAPseeker_results.txt, which
you keep in your notebook as a record of the run statistics, 
background subtraction, etc.

Finally, the data will be available in RDAT format (here, 'example.rdat'),
which is a compact human-readable format for sharing
your information (see below, 'What to do next'). It includes
information on signal-to-noise ('weak' in this case since
we used a subset of the data), data processing steps 
(overmodificationCorrectionExact),
estimated errors, etc.


<h3>3. Referencing</h3>

We typically include, in all our runs, the following sequence, which
is the P4-P6 domain of the Tetrahymena ribozyme with a GAGUA-capped hairpin 
prepended and appended in flanking sequences:

> 0	P4P6	REFERENCE	GAGUA
GGCCAAAGGCGUCGAGUAGACGCCAACAACGGAAUUGCGGGAAAGGGGUCAACAGCCGUUCAGUACCAAGUCUCAGGGGAAACUUUGAGAUGGCCUUGCAAAGGGUAUGGUAAUAAGCUGACGGACAUGGUCCUAACCACGCAGCCAAGUCCUAAGUCAACAGAUCUUCUGUUGAUAUGGAUGCAGUUCAAAACCAAACCGUCAGCGAGUAGCUGACAAAAAGAAACAACAACAACAAC

This allows 'in situ' determination of any ligation bias 
('full_length_correction_factor'), by comparison of the
reactivities of the GAGUA pentaloops at the 5' and 3' ends. 
If you have more than one modifier in use, the ligation bias 
will be estimated from each case and averaged.

The reactivities will also be normalized to the average
reactivity in the GAGUA region.

If you have another reference construct, include it
in your RNA library FASTA, including the fields 'REFERENCE'
and 'GAGUA' as tab delimited fields.

<h3>4. What to do next</h3>
Done! You can now share the RDAT file, which is a human-readable text format that
lets you save and revisit the data and additional information on your experiment.

For example, you can open it in excel (its a tab-delimitted text file). Or you
can use MATLAB or python scripts in the RDATkit to view.

You can carry out chemical-mapping-guided structure prediction on the on-line server

http://rmdb.stanford.edu/structureserver/

Just upload the file! 

We are also creating a set of tools for data exploration, including
sequence and structure viewing, and 'BLASTing' the sequence and data 
against the full RMDB, and hope to have 
those available at the RMDB by 2014.

Because your file has estimated errors, it will be useful for the community. 
We urge you to share it in the RNA Mapping Database:

http://rmdb.stanford.edu/

and an entry will also automatically be generated at the awesome SNRNASM database:

http://snrnasm.bio.unc.edu/


<h3>5. Further processing (if desired)</h3>

To further process these data for useful output, you 
can take the output of quick_look_MAPseeker with 
the following command:

 [ D, D_err, RNA_info, primer_info, D_raw, D_ref, D_ref_err, RNA_info_ref ] = quick_look_MAPseeker( library_file, primer_file, inpath, full_length_correction_factor );

D and D_err have the reactivities and their estimated errors.
The errors are based on Poisson statistics (note: sites 
with zero counts are given 'placeholder' errors of +/-1 ).
They are cells with one matrix for each primer. 

The first position of these matrices corresponds to site 1, i.e.
a reverse transcription stop right before full cDNA extension.

If one of the primers was described as 'no mod' then these
data matrices have been background subtracted. (So
one of the matrices in each cell will actually be zero.)

RNA_info has information on the sequences and descriptions 
of the RNA library. 

D_raw contains the raw counts in the stats_ID1.txt, etc. files.
Note that its first index corresponds to site 0 (full extension),
unlike D and D_err.

Last, D_ref and D_ref_err contain information on any REFERENCE constructs
which act as internal standards for MAP-seq ligation bias estimation
and normalization. 

MATLAB functions subtract_data() and average_data() are provided
to help compare data sets.













