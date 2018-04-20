# MAPseeker, v2.0
(C) R. Das, 2013-2016; C. Cheng, 2014-2016;  J.P. Bida, 2012.

E-mail: rhiju [at] stanford.edu.

## LICENSE

This project can only be accessed and used in compliance with
the license, which can be viewed [here](LICENSE.md).

## General information

Multiplexed Accessibility Probing read out through next 
generation Sequencing (MAP-seq) leverages multiple chemical 
modification strategies to give information-rich structural 
data on pools of RNAs. 

A stable version of the experimental protocol is described
in a chapter of Methods in Molecular Biology, which is available 
on the Das lab website at:
http://daslab.stanford.edu/pdf/Seetin_MAPseq_MiMB2013.pdf

1. The MAPseeker executable.  

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

2. quick_look_MAPseeker()  

  A function in MATLAB which reads the output for MAPseeker 
  and makes summary plots for your notebook.

3. A collection of useful helper scripts  

  In Python, for pre-processing RNA fasta files if desired.
  In MATLAB, for converting counts to chemical reactivities, 
  subtracting backgrounds, outputting to RDAT text formats 
  for sharing.

4. RDATkit  

  Scripts needed to read/write in RDAT format.

## How to install

To compile the main MAPseeker executable, go to:

` src/cmake/ `

and follow instructions in the README there for compilation. 

## Tutorial I. Example run for 1D chemical mapping data

### 1. Converting FASTQs to meaningful structure mapping data

Some example data is included to test the scripts, involving MAP-seq data 
for 1M7 probing of a large set of RNAs including two 'control' constructs 
doped in at higher concentrations. Go to:

` example/ `

There are four files:

* **PhiX_S1_L001_R1_001.first100000.fastq** and **PhiX_S1_L001_R2_001.first100000.fastq**  

   First 100,000 lines of forward and reverse read files
   from a miseq run. The PhiX is a silly tag (most of the
   run is not the PhiX genome).

* **primers.fasta**  

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

* **RNA_sequences.fasta**  

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

` MAPseeker -1 PhiX_S1_L001_R1_001.first100000.fastq  -2 PhiX_S1_L001_R2_001.first100000.fastq  -l RNA_sequences.fasta  -p primers.fasta  -n 8 `

These are all the input files. The final argument "-n 8" 
specifies that the first 8 residues read by the reverse 
transcription primer should be used by MAPseeker to figure 
out the RNA's ID. It is assumed that your library has unique 
3' sequences just ahead of the reverse transcription binding site.

The output should include the following purification table:

>Purification table  
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

If the command is run by quick_look_mapseeker(), a MAPseeker_executable.log
file will be created that records the command line and purification table.


### 2. Visualizing & processing the run.

To view these files, you can use any plotting program (MATLAB, 
gnuplot, matplotlib in python). 

We use MATLAB scripts, available in 

`src/matlab/ `

Include this in your MATLAB path. And if you don't already
have the RDATkit scripts installed, get them at

https://github.com/ribokit/RDATKit

and make sure that RDATkit/MATLAB is in your MATLAB path.

Now run from within MATLAB:

`full_length_correction_factor = 0.5;`  
`quick_look_MAPseeker( 'RNA_sequences.fasta','primers.fasta','./',full_length_correction_factor)`

If you don't specify the arguments, that will actually work here, 
as the script will assume that the RNA library file, primer 
FASTA file, and working directory with stats_ID1.txt, etc. 
are the ones used above.

The 'full_length_correction_factor' provides a global estimate of
ligation bias for the fully extended cDNA compared to partially extended
cDNAs. In our hands, CircLigase gives a bias of ~0.5 even with
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

> R(site i) = F(site i)/[F(site 0) + F(site 1) + ... + F(site i) ]

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


### 3. Referencing

We typically include, in all our runs, the following sequence, which
is the P4-P6 domain of the Tetrahymena ribozyme with a GAGUA-capped hairpin 
prepended and appended in flanking sequences:

<pre>>  0    P4P6    REFERENCE    GAGUA
GGCCAAAGGCGUCGAGUAGACGCCAACAACGGAAUUGCGGGAAAGGGGUCAACAGCCGUUCAGUACCAAGUCUCA  
GGGGAAACUUUGAGAUGGCCUUGCAAAGGGUAUGGUAAUAAGCUGACGGACAUGGUCCUAACCACGCAGCCAAGU  
CCUAAGUCAACAGAUCUUCUGUUGAUAUGGAUGCAGUUCAAAACCAAACCGUCAGCGAGUAGCUGACAAAAAGAA  
ACAACAACAACAAC</pre>

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


### 4. What to do next
Done! You can now share the RDAT file, which is a human-readable text format that
lets you save and revisit the data and additional information on your experiment.  


For example, you can open it in excel (it's a tab-delimitted text file). Or you
can use MATLAB or python scripts in the RDATkit to view.  


You can carry out chemical-mapping-guided structure prediction on the on-line server  

http://rmdb.stanford.edu/structureserver/  

Just upload the file!  

We are also creating a set of tools for data exploration, including
sequence and structure viewing, and 'BLASTing' the sequence and data 
against the full RMDB, and hope to have those available at the RMDB by 2014.  

Because your file has estimated errors, it will be useful for the community. 
We urge you to share it in the RNA Mapping Database:  

http://rmdb.stanford.edu/  

and an entry will also automatically be generated at the awesome SNRNASM database:  

http://snrnasm.bio.unc.edu/


### 5. Further processing (if desired)

To further process these data for useful output, you 
can take the output of quick_look_MAPseeker with 
the following command:

`[ D, D_err, RNA_info, primer_info, D_raw, D_ref, D_ref_err, RNA_info_ref ] = quick_look_MAPseeker( library_file, primer_file, inpath, full_length_correction_factor );`

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





## Tutorial II. Example run for MOHCA-seq data

In MOHCA-seq experiments, a hydroxyl radical source (a Fe•EDTA complex) is covalently tethered to the backbone of the RNA. Activation of the Fenton reaction generates localized hydroxyl radicals, which produce spatially correlated oxidative damage events in the RNA that are read out by reverse transcription and sequencing. The experimental protocol is published online at: http://elifesciences.org/content/4/e07600/. 

There are a few major steps to analyzing MOHCA-seq data in MAPseeker:

1. Quantify sequencing reads from FASTQs.
2. (Optional) If size-selection was performed during library preparation to enhance signal for longer RNA fragments, rebalance the size-selected and non-size-selected data to correct for length bias in size-selected samples. This is useful for RNAs above ~150 nt in length. See the published article for more details on size-selection.
3. Analyze quantified raw counts for correlated signal.
4. Sharing and visualizing the final data.

### 1. Quantify sequencing reads from FASTQs.

Example MOHCA-seq data for testing the scripts is provided in

`example/MOHCAseq/`

There are four folders:

* **1_NoSizeSelect**
* **2_SizeSelect**
* **Rebalance**
* **FinalAnalysis**
* **PDB**

Within each of **1_NoSizeSelect** and **2_SizeSelect**, there are four files:

* **Read1** and **Read2** FASTQ files

   Sequencing data for ligand-bound state of the _ydaO_ cyclic-di-AMP riboswitch from _T. tengcongensis_. The non-size-selected FASTQ files contain 1/11 of the reads from the original FASTQs, and the size-selected FASTQ files contain 1/5 of the reads from the original FASTQs.

* **primers.fasta**  

   Primers used in the run, in FASTA format. 

   The headers describe the conditions used in the experiments probed by each primer (the first one is a control where the radical source was not activated, the next three were exposed to localized hydroxyl radical damage by incubation with ascorbate to activate the Fenton reaction). 
   
   Use the 'chemical:' and 'temperature:' tags to specify the conditions of your experiment. These annotations will carry through to the final RDAT-formatted dataset.

* **MOHCA.fasta**  

   This file provides the RNA sequence in FASTA format.

   If a MOHCA.fasta file is provided in the directory where
   quick_look_MAPseeker is run, MAPseeker will automatically
   generate the RNA_sequences.fasta file that is used for
   alignment with the sequencing data.

**First, we will align the reads to the RNA sequence to generate RDAT files with raw counts, which will then be further analyzed.**

It is best to use MATLAB for MOHCA-seq data analysis, because the analysis steps after alignment and quantification of raw counts can only performed in MATLAB at present.

Go to the **1_NoSizeSelect** folder and run the command:

`quick_look_MAPseeker;`

The MAPseeker executable command line and the output of the analysis are printed to screen and recorded in the MAPseeker_executable.log file. The output should include the following purification table:

>Purification table  
450617 total  
120341 found primer binding site  
120141 found expt ID site  
120141 found match in RNA sequence (read 1)  
86673 found match in RNA sequence (read 2)  
50495 found strict match in RNA sequence (read 2)  

For this example dataset, the run should take less than 2 minutes; for a real dataset, it may take up to around 5-10 minutes. The 

As for MAP-seq analysis, a stats_ID text file with a matrix of numbers is generated for each primer. For this example dataset, there should be stats_ID1.txt through stats_ID4.txt. Each row of the matrix represents a different cleavage position in the RNA, and each column of the matrix is a reverse transcription stop site.

To facilitate downstream analysis of MOHCA-seq data, MAPseeker generates RDAT files containing these raw aligned data, without correction for reverse transcription attenuation, when the MOHCA.fasta file is provided instead of RNA_sequences.fasta. In this example, the files are named 1_NoSizeSelect.RAW.1.rdat and 1_NoSizeSelect.RAW.2.rdat.

To visualize the data, the same plots that are automatically generated for MAP-seq analysis will also be generated for MOHCA-seq analysis, including:
* **Figure 1.** A histogram of counts per primer
* **Figures 2 and 3.** Raw counts and attenuation-corrected reactivities for the four most highly represented RNAs
* **Figures 4 and 5.** 2D representations of the raw counts and reactivities of the full dataset. Figures 4 and 5 are useful as initial visualizations of the two-dimensional MOHCA-seq data.
* **Figure 7.** Additionally, for MOHCA-seq data analysis, 1D projections of the 2D data along the columns and rows of the stats_ID matrices (giving profiles of cleavage and reverse transcription stops, respectively) are calculated and plotted in Figure 7.

The text output of these analyses is recorded in MAPseeker_results.txt.

**If size-selection was performed during library preparation,** go to the **2_SizeSelect** folder and run `quick_look_MAPseeker` as above to generate the raw counts for the size-selected dataset as well, then proceed to step 2 to rebalance and combine the size-selected and non-size-selected data.

**If size-selection was not performed during library preparation,** skip step 2 and perform step 3 to analyze the data for correlated signal.



### 2. (OPTIONAL) Rebalance and combine size-selected and non-size-selected data.

If size-selection was performed to enhance signal for longer-distance reads, we must correct for the attenuation of signal for short RNA fragments by rebalancing the size-selected data using the non-size-selected data. This is performed in MAPseeker by the `rebalance.m` script.

Go to the **Rebalance** folder and run the command:

```
rebalance( '/path/to/1_NoSizeSelect/1_NoSizeSelect.RAW.2.rdat', ...
           '/path/to/2_SizeSelect/2_SizeSelect.RAW.2.rdat', ...
           'rebalance.rdat' );
```

The rebalancing script reads the two input RAW RDAT files and calculates the mean signal at each sequence separation (along the diagonals of the 2D data) for each dataset, bins and averages the mean signals based on sequence separation, and calculates the ratio of the size-selected data to the non-size-selected data at each sequence separation.

To rebalance the size-selected data, the signal at each sequence separation is multiplied by the maximum ratio of size-selected/non-size-selected signal and then divided by the ratio at that sequence separation. Finally, the rebalanced size-selected dataset is combined with the non-size-selected dataset by taking the mean (weighted by the inverse error squared) between the data sets.

The output of rebalancing is an RDAT file named using the third input to `rebalance.m`, and a folder titled **Rebalance_plots** containing plots of the size-selected, non-size-selected, and rebalanced datasets, and an overlay of the ratios of the mean signal at each sequence separation between the size-selected and non-size-selected data.



### 3. Analyze quantified raw counts for correlated signal.

The final step in MAPseeker analysis of MOHCA-seq data is to perform Closure-based •OH COrrelation Analysis (COHCOA).

COHCOA performs iterative fitting to determine a two-point correlation function underlying the quantified (and rebalanced, if applicable) aligned data, correcting for uncorrelated cleavage events and reverse transcription stops that appear as vertical and horizontal striations in the raw data, as well as reverse transcription attenuation. A full description of the COHCOA analysis is available in the published article.

Copy the RDAT file to be analyzed with COHCOA into the **FinalAnalysis** folder. In this example, because rebalancing was performed, copy the **rebalance.rdat** file. If rebalancing was not performed, copy the **1_NoSizeSelect.RAW.2.rdat** file.

Go to the **FinalAnalysis** folder and run the command:

`smoothMOHCA( 'rebalance.rdat' );`

The `smoothMOHCA.m` script calls the commands for running the COHCOA analysis, which is performed in the script `cohcoa_classic.m`, and generates output folders with plots and RDAT files from the analysis. The `smoothMOHCA.m` script also supports analysis of multiple raw datasets at once, in cases where multiple sequencing runs have been performed for a single RNA and condition, if the raw RDAT files are input into `smoothMOHCA.m` as a cell array of strings.

The outputs of `smoothMOHCA` include:

* The final analyzed dataset, called **COMBINED.COHCOA.SQR.rdat** and located in the **FinalAnalysis** folder; it is the weighted mean of the COHCOA-analyzed data for all input RDATs.
* A folder titled **Figures**, which contains the proximity map (2D plot of the COHCOA-analyzed data) for **COMBINED.COHCOA.SQR.rdat** in .EPS, .PDF, and MATLAB figure formats.
* A folder titled **COHCOA**, which includes, for each input RDAT file, [1] a figure showing the striated background calculated by COHCOA ('F_plaid') and the final two-point correlation function, referred to as 'Q', with the suffix '__.COHCOA.rdat.eps' and [2] an RDAT containing Q, with the suffix '__.COHCOA.rdat'.
* A folder titled **Analyzed_rdats**, which includes, for each input RDAT file, the RDATs from the **COHCOA** folder with the dataset cropped to be square, removing extraneous columns generated by prior analysis steps, with the suffix '__.COHCOA.SQR.rdat'.



### 4. Sharing and visualizing the final data.

#### Sharing the data

Done! The RDAT file is in a human-readable, tab-delimitted format that records the data and experimental conditions of your experiment.

Because your file has estimated errors, it will be useful for the community. We urge you to share it in the RNA Mapping Database:  

http://rmdb.stanford.edu/  

and an entry will also automatically be generated at the awesome SNRNASM database:  

http://snrnasm.bio.unc.edu/

#### Visualizing the data as a proximity map; assessing secondary structures and 3D models

MAPseeker includes a function, called `mohcaplot.m`, for making and saving proximity maps of MOHCA-seq data and plotting secondary structures and 3D models on the data for model assessment.

To plot the proximity map, go to the **FinalAnalysis** folder and run the command:

`mohcaplot( 'COMBINED.COHCOA.SQR.rdat' );`

You can also specify the x- and y-axis limits, title, font size, and path to save the file.

**To overlay a secondary structure model on the proximity map,** generate a variable containing the sequence, structure, and offset between the sequences and input to `mohcaplot.m`:

```
sequence =  'GGAUCGCUGAACCCGAAAGGGGCGGGGGACCCAGAAAUGGGGCGAAUCUCUUCCGAAAGGAAGAGUAGGGUUACUCCUUCGACCCGAGCCCGUCAGCUAACCUCGCAAGCGUCCGAAGGAGAAUC';
structure = '....((((...(((....)))((((((....(......(((((....(((((((....)))))))..(((((.[[[[[[[)))))..))))..).)....)))))).))))...]]]]]]]....';
offset = 0;
secstr = { sequence, structure, offset };
mohcaplot( 'COMBINED.COHCOA.SQR.rdat', secstr );
```

**To compare a MOHCA-seq proximity map to a 3D model,** input the path to a PDB file to `mohcaplot.m`; for this example, a crystal structure of the riboswitch is in the **PDB** folder:

```
pdb = '/path/to/PDB/4QK8.pdb';
mohcaplot( 'COMBINED.COHCOA.SQR.rdat', '', pdb );
```

Finally, **MOHCA-seq proximity maps can provide pairwise constraints for RNA 3D modeling** in the Rosetta modeling software (https://www.rosettacommons.org/), as described in the published article. The current method for generating a list of constraint pairs is to plot a secondary structure, e.g. derived from mutate-and-map experiments [see Kladwang et al. (2011) _Nat Chem_], on the proximity map and manually select pairs of residues at the peaks of punctate signals, avoiding signals that overlap with secondary structure. In the future, an automated peak-picking function will be available.


