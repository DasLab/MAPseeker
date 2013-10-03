#define SEQAN_PROFILE // enable time measurements
#include <apps/MAPseeker.h>
#include <seqan/misc/misc_cmdparser.h>
#include <tr1/unordered_map>
#include <seqan/file.h>
#include <iostream>
#include <sstream>
#include <string>
#include <stdio.h>



//cseq is the constant region between the experimental id and the sequence id
//in the Das lab this is the tail2 sequence AAAGAAACAACAACAACAAC
std::string const daslab_tail2_sequence("AAAGAAACAACAACAACAAC");
// a.k.a. TruSeq Universal Adapter -- gets added to one end of many illumina preps. Should be shared 5' end of all primers.
std::string const universal_adapter_sequence( "AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATCT");
std::string const universal_adapter_sequence2("AGATCGGAAGAGC"); // reverse complement of AadaptBp or truseq 'adapter' sequence


//Versioning information
inline void
_addVersion(CommandLineParser& parser) {
    ::std::string rev = "$Revision: 0075 $";
    addVersionLine(parser, "Version 1.2 (30 September 2013) Revision: " + rev.substr(11, 4) + "");
}

int main(int argc, const char *argv[]) {

  //All command line arguments are parsed using SeqAn's command line parser
    CommandLineParser parser;
    _addVersion(parser);

    addTitleLine(parser, "                                                 ");
    addTitleLine(parser, "*************************************************");
    addTitleLine(parser, "* MAP-Seeker                                    *");
    addTitleLine(parser, "* (c) Copyright 2012, JP Bida, R. Das           *");
    addTitleLine(parser, "* (c) Copyright 2013, R. Das                    *");
    addTitleLine(parser, "*************************************************");
    addTitleLine(parser, "                                                 ");

    addUsageLine(parser, " -1 <miseq fastq1> -2 <miseq fastq2> -l <RNA library fasta> -p <primers fasta> -n <sequence id length>");

    addSection(parser, "Main Options:");

    addOption(parser, addArgumentText(CommandLineOption("1", "miseq1", "miseq output [read 1] containing primer ids",OptionType::String), "<FASTAQ FILE>"));
    addOption(parser, addArgumentText(CommandLineOption("2", "miseq2", "miseq output [read 2] containing 3' ends",OptionType::String), "<FASTAQ FILE>"));
    addOption(parser, addArgumentText(CommandLineOption("l", "library", "library of sequences to align against", OptionType::String),"<FASTA FILE>"));
    addOption(parser, addArgumentText(CommandLineOption("p", "primers", "fasta file containing experimental primers", OptionType::String,""), "<FASTA FILE>"));
    addOption(parser, addArgumentText(CommandLineOption("n", "sid_length", "sequence id length (nts 3' of shared primer binding site)", OptionType::Int, 0), "<int>"));

    addOption(parser, addArgumentText(CommandLineOption("O", "outpath", "output path for stats files", OptionType::String, ""), "<out path>"));
    addOption(parser, addArgumentText(CommandLineOption("N", "start_at_read","align reads starting at this number, going from 0 (e.g., N = job ID)", OptionType::Int, 0), "<int>"));
    addOption(parser, addArgumentText(CommandLineOption("j", "increment_between_reads", "align reads separated by this increment (e.g., j = total # jobs)", OptionType::Int, 1), "<int>"));

    addOption(parser, addArgumentText(CommandLineOption("b", "barcodes", "fasta file containing experimental barcodes", OptionType::String,""), "<FASTA FILE>"));
    addOption(parser, addArgumentText(CommandLineOption("c", "cseq", "Constant sequence", OptionType::String,""), "<DNA sequence>"));
    addOption(parser, addArgumentText(CommandLineOption("x", "match_single_nt_variants", "check off-by-one to match sequence ID in read 1", OptionType::Bool, false), ""));
    addOption(parser, addArgumentText(CommandLineOption("D", "match_DP", "use dynamic programming to match sequence ID in read 2 (allow in/del)", OptionType::Bool, false), ""));
    addOption(parser, addArgumentText(CommandLineOption("A", "align_all", "try to align short reads, even if ambiguous [useful for MOHCA]", OptionType::Bool, false), ""));
    addOption(parser, addArgumentText(CommandLineOption("s", "strict", "Enforce read 2 to have zero mismatches (default: up to 2 mismatches)", OptionType::Bool, false), ""));
    addOption(parser, addArgumentText(CommandLineOption("0", "align_null","go ahead and align null ligations too!", OptionType::Bool, false), ""));
    addOption(parser, addArgumentText(CommandLineOption("a", "adapter", "Illumina Adapter sequence = 5' DNA sequence shared by all primers", OptionType::String,""), "<DNA sequence>"));
    addOption(parser, addArgumentText(CommandLineOption("z", "adapter2", "Illumina Adapter sequence = 3' DNA sequence shared by all fragments, introduced by ligation", OptionType::String,""), "<DNA sequence>"));

    if (argc == 1) {
      shortHelp(parser, std::cerr);	// print short help and exit
      return 0;
    }

    if (!parse(parser, argc, argv, std::cerr)) exit( 0 );
    if (isSetLong(parser, "help") || isSetLong(parser, "version")) return 0;	// print help or version and exit

    //This isn't required but shows you how long the processing took
    SEQAN_PROTIMESTART(loadTime);
    unsigned seqid_length( 0 ), increment_between_reads( 0 ), start_at_read( 0 );
    std::string file1,file2,file_library,file_expt_id,file_primers,outfile,outpath;
    String<char> cseq,adapterSequence,adapterSequence2;
    getOptionValueLong(parser, "cseq",cseq);
    getOptionValueLong(parser, "adapter",adapterSequence);
    getOptionValueLong(parser, "adapter2",adapterSequence2);
    getOptionValueLong(parser, "miseq1",file1);
    getOptionValueLong(parser, "miseq2",file2);
    getOptionValueLong(parser, "library",file_library);
    getOptionValueLong(parser, "barcodes",file_expt_id);
    getOptionValueLong(parser, "primers",file_primers);
    getOptionValueLong(parser, "outpath",outpath);
    if ( outpath.size() > 0 && outpath[ outpath.size()-1 ] != '/' ) outpath += '/';
    bool match_single_nt_variants = isSetLong( parser, "match_single_nt_variants" );
    bool match_DP = isSetLong( parser, "match_DP" );
    bool align_all = isSetLong( parser, "align_all" );
    bool align_null = isSetLong( parser, "align_null" );
    bool strict = isSetLong( parser, "strict" );
    if ( align_null && !align_all ) { std::cout << "WARNING: Setting align_all to be true since align_null is true." << std::endl; align_all = true; }
    getOptionValueLong(parser,"sid_length",seqid_length);
    getOptionValueLong(parser,"increment_between_reads", increment_between_reads); // for job splitting
    getOptionValueLong(parser,"start_at_read",start_at_read); // for job splitting

    ////////////////////////////////////////////////////////////////////
    // Read in Illumina fastq files
    ////////////////////////////////////////////////////////////////////
    MultiSeqFile multiSeqFile1, multiSeqFile2, multiSeqFile_library;
    AutoSeqFormat format1, format2, format_library;
    unsigned seqCount1, seqCount2, seqCount_library;
    read_in_fastq( multiSeqFile1, format1, file1, seqCount1 );
    read_in_fastq( multiSeqFile2, format2, file2, seqCount2 );
    read_in_fastq( multiSeqFile_library, format_library, file_library, seqCount_library );

    if(seqCount1 != seqCount2 ){
        std::cout << "MiSeq input files contain different number of sequences" << std::endl;
        return 1;
    } else {
        std::cout << "Total Pairs: " << length(multiSeqFile1) << ":" << length(multiSeqFile2) << std::endl;
    }

    // following would be way more memory efficient -- a stream.
    // however, RecordReader no longer seems to exist in seqan library !?

    // std::ifstream fastq1(file1.c_str(), std::ios_base::in | std::ios_base::binary);
    // if (!fastq1.good())  return 1;
    // RecordReader<std::ifstream, SinglePass<> > reader1(fastq1);
    // if (!checkStreamFormat(reader1, format1))  return 1;

    // std::ifstream fastq1(file2.c_str(), std::ios_base::in | std::ios_base::binary);
    // if (!fastq2.good())  return 1;
    // RecordReader<std::ifstream, SinglePass<> > reader2(fastq2);
    // if (!checkStreamFormat(reader2, format2))  return 1;


    //////////////////////////////////////////////
    // Build up library of RNA sequences
    //////////////////////////////////////////////
    // FRAGMENT(read_sequences)
    String<char> seq1,seq1id,seq2,seq_from_library,seq_from_libraryid,seq_expt_id,qual1,qual2,id1,id2;
    THaystacks haystacks_rna_library, haystacks_expt_ids;
    std::vector< String<char> > rna_library_vector_RC; //will be used for checking common sequences in the library and seqid_length
    std::vector< String<char> > short_expt_ids;

    // Get all RNA sequences from RNA library, convert to DNA.
    // Check for sequences with star ('*'), which signifies places where there can
    //  be extra junk nucleotides.
    std::vector< CharString > RNA_sequences, sequences_before_star, sequences_after_star;
    std::vector< unsigned > star_sequence_ids;

    for(unsigned j=0; j< seqCount_library; j++) {
      assignSeq(seq_from_library, multiSeqFile_library[j], format_library);    // read sequence
      check_for_star_sequence( seq_from_library, sequences_before_star, sequences_after_star, star_sequence_ids, j );
      RNA2DNA( seq_from_library );
      RNA_sequences.push_back( seq_from_library );
    }

    // Index library sequences for alignment
    unsigned max_rna_len( 0 );
    std::cout << "Indexing Sequences(N=" << seqCount_library << ")..";
    for(unsigned j=0; j< seqCount_library; j++) {
      CharString seq_from_library = RNA_sequences[ j ];
       appendValue(haystacks_rna_library, seq_from_library);
      if ( max_rna_len < length( seq_from_library ) ) max_rna_len = length( seq_from_library );

      CharString seq_from_library_RC( seq_from_library );
      reverseComplement( seq_from_library_RC );
      rna_library_vector_RC.push_back( seq_from_library_RC );
    }
    Finder<Index<THaystacks> > finder_sequence_id( haystacks_rna_library );
    std::cout << "completed" << std::endl;
    std::cout << "RNA sequence Lengths(max=" << max_rna_len <<"):" << std::endl;


    ////////////////////////////////////////////////////////////////////////////////
    // Figure out experimental IDs and primer binding site from primer sequences.
    ///////////////////////////////////////////////////////////////////////////////
    figure_out_expt_IDs( file_primers, file_expt_id, short_expt_ids, haystacks_expt_ids, cseq, adapterSequence );
    unsigned seqCount_expt_id = short_expt_ids.size();

    if ( length( adapterSequence2 ) == 0 ) adapterSequence2 = universal_adapter_sequence2;

    check_unique_id( rna_library_vector_RC, cseq, seqid_length, max_rna_len );

    //    Index<THaystacks> index_expt_ids(haystacks_expt_ids);
    Finder<Index<THaystacks> > finder_expt_id(haystacks_expt_ids);

    std::cout << "Reading MiSEQ, RNA library, primer sequence files took: " << SEQAN_PROTIMEDIFF(loadTime) << " seconds." << std::endl;

    // initialize a histogram recording the counts [convenient for plotting in matlab, R, etc.]
    std::vector< double > sequence_counts( max_rna_len+1,0.0 );
    std::vector< std::vector< double > > bunch_of_sequence_counts( seqCount_library, sequence_counts);
    std::vector< std::vector< std::vector < double > > > all_count( seqCount_expt_id, bunch_of_sequence_counts);

    std::vector< std::vector< std::vector < double > > > all_count_strict = all_count;

    // keep track of how many sequences pass through each filter
    std::vector< unsigned > counter_counts;
    std::vector< std::string > counter_tags;
    unsigned perfect( 0 ), nullLigation( 0 );


    std::cout << "Running alignment" << std::endl;
    SEQAN_PROTIMESTART(alignTime); // reset counter.

    ////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////
    //                       MAIN LOOP!                           //
    ////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////
    //    while (!atEnd(reader1) && !atEnd(reader2)){

    for (unsigned i = start_at_read; i < seqCount1; i += increment_between_reads) {

      // Get the next forward and reverse read...
      assignSeq(seq1, multiSeqFile1[i], format1);    // read sequence
      assignQual(qual1, multiSeqFile1[i], format1);  // read ascii quality values
      assignSeqId(id1, multiSeqFile1[i], format1);   // read sequence id

      assignSeq(seq2, multiSeqFile2[i], format2);    // read sequence
      assignQual(qual2, multiSeqFile2[i], format2);  // read ascii quality values
      assignSeqId(id2, multiSeqFile2[i], format2);   // read sequence id

      // following would be way more memory efficient -- a stream.
      // however, RecordReader no longer seems to exist in seqan library !?
      // if (readRecord(id1, seq1, reader1, format1) != 0) return 1;
      // if (readRecord(id2, seq2, reader2, format2) != 0) return 1;

      reverseComplement(seq1);

      unsigned counter_idx( 0 ); // will keep track of which filter we pass.
      record_counter( "total", counter_idx, counter_counts, counter_tags );

      int pos1( -1 ), constant_sequence_begin_pos( -1 ), expt_idx( -1 );

      ///////////////////////////////////////////////////////////////////////////////////////////
      // Look for the constant region (primer binding site) -- JP's trick.
      // In future could do multi-pattern search for multiple primers ... in that
      // case, we'll have to rewrite this code unfortunately.
      ///////////////////////////////////////////////////////////////////////////////////////////
      //pos1 = try_exact_match( seq1, cseq, perfect );  //  interesting -- DPsearch (see next) is no slower than available exact matches.
      if ( pos1 < 0 ) pos1 = try_DP_match( seq1, cseq, perfect ); // allows for 1 mismatch, 2 deletions
      if ( pos1 < 0 ) continue;
      record_counter( "found primer binding site", counter_idx, counter_counts, counter_tags );

      //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
      // Look for experimental ID (expt ID that follows constant primer binding site, and is coded by reverse transcription primer)
      //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
      // first look for exact match -- should be super-fast, as using index.
      String<char> expt_id_in_read1 = suffix(seq1,(pos1+1));
      if ( find( finder_expt_id, expt_id_in_read1 ) )	{
	expt_idx = beginPosition(finder_expt_id).i1;
      }
      clear( finder_expt_id );

      if ( expt_idx < 0) expt_idx = try_DP_match_expt_ids( short_expt_ids, expt_id_in_read1 );

      // this avoids findBegin, but assumes no indels in constant primer binding sequence
      if ( constant_sequence_begin_pos < 0 ) constant_sequence_begin_pos = pos1 - length( cseq);

      if( expt_idx < 0 ) continue;
      record_counter( "found expt ID site", counter_idx, counter_counts, counter_tags );

      ////////////////////////////////////////////////////////////////////////////////////////
      // Look for the sequence ID (i.e., the identifier sequence at the 3' end of the RNA)
      // in a region of seqid nucleotides before the constant (primer-binding) site.
      // seqid is the (minimum) length of the barcode...
      ////////////////////////////////////////////////////////////////////////////////////////
      int min_pos = constant_sequence_begin_pos - seqid_length + 1;
      if (min_pos < 0)	 min_pos = 0;
      String<char> sequence_id_region_in_sequence1 = infixWithLength( seq1, min_pos, seqid_length);
      // We append the primer binding site to make sure that the search will be over actual barcode regions (adjoining the constant sequence) from the RNA library.
      append(sequence_id_region_in_sequence1,cseq);

      // Start by looking for exact match of sequence ID in read 1, and then look for match in read 2.
      //   If that doesn't work, can try single nucleotide variants later...
      bool found_match_in_read1( false ), found_match_in_read2( false );
      std::vector< unsigned > possible_sids, possible_begpos;
      find_possible_sids( possible_sids, possible_begpos, finder_sequence_id, sequence_id_region_in_sequence1 );

      // ambiguous assignments. [should not occur if n (seqid_length) is set large enough.]
      if ( possible_sids.size() > 1 )	disambiguate_possible_sids( possible_sids, possible_begpos, min_pos, seq1, RNA_sequences );

      // this might be a really short read -- can check this by looking for the appearance of the other
      // Illumina adapter sequence which should be ligated onto the 3' end.
      bool verbose( false );
      if ( align_all && possible_sids.size() == 0 )  check_for_short_insert( adapterSequence2, cseq, constant_sequence_begin_pos, seqid_length,
									     seq1, finder_sequence_id, possible_sids, align_null, verbose, nullLigation );


      // there was originally a different logic for this, where MAPseeker had a while loop that went through
      // every single nt variant until finding a hit. The following is slower, testing every variant -- might
      // still be useful for testing and is less biased. Anyway, currently match_single_nt_variants
      // is not in use by default, and turning it on doesn't get us more than ~5-10% more aligned reads.
      if ( possible_sids.size() == 0 && match_single_nt_variants ){
	CharString sequence_id_region_variant( sequence_id_region_in_sequence1 );
	unsigned variant_counter( 1 );
	while ( get_next_variant( sequence_id_region_in_sequence1, sequence_id_region_variant, variant_counter, seqid_length ) ){
	  find_possible_sids( possible_sids, possible_begpos, finder_sequence_id, sequence_id_region_variant );
	}
      }

      // Should be a class...
      // check for 'junk' -- random nts at 3' end of RNA added by T7 polymerase.
      // specified by user as sequence with '*' in the middle. See above for fasta readin.
      bool extra_junk_mode( false );
      std::vector< CharString > sequences_with_extra_junk;
      if ( possible_sids.size() == 0 )  check_for_extra_junk_using_star_sequences( possible_sids, sequences_with_extra_junk, extra_junk_mode,
										   finder_sequence_id, seq1, constant_sequence_begin_pos,
										   sequences_before_star, sequences_after_star, star_sequence_ids );

      // "hail mary"
      if ( align_all && possible_sids.size() == 0 )  {
	for ( unsigned s = 0; s < star_sequence_ids.size(); s++ ) possible_sids.push_back( star_sequence_ids[ s ] );
      }


      if ( possible_sids.size() == 0 ) continue;

      record_counter( "found match in RNA sequence (read 1)", counter_idx, counter_counts, counter_tags );
      found_match_in_read1 = true;

      std::vector< unsigned > mpos_vector, sid_vector;
      int mscr( 0 );

      for ( unsigned s = 0; s < possible_sids.size(); s++ ){

	// seq_from_library contains the RNA library sequences
	unsigned sid_idx = possible_sids[ s ];

	// what is the DNA?
	if ( !extra_junk_mode ){
	  seq_from_library = RNA_sequences[ sid_idx ];
	} else {
	  seq_from_library = sequences_with_extra_junk[ s ];
	}
	append( seq_from_library, short_expt_ids[ expt_idx ] ); // experimental ID, added in MAP-seq protocol as part of reverse transcription primer
	append( seq_from_library, adapterSequence ); // piece of illumina DNA, added in MAP-seq protocol as part of reverse transcription primer

	////////////////////////////////////////////////////////////////////////////////////////
	// Look for the second read to determine where the reverse transcription stop is.
	////////////////////////////////////////////////////////////////////////////////////////
	Finder<String<char> > finder_in_specific_sequence(seq_from_library);

	//reads beyond sequence ID are nonsense -- sequence ID better be there based on match to read1 above.
	int mpos_max = try_exact_match( seq_from_library, cseq ) - seqid_length;
	if ( align_all  ) mpos_max = try_exact_match( seq_from_library, cseq ) - 1;
	if ( align_null ) mpos_max = try_exact_match( seq_from_library, cseq ) - 1;  	  // allows for null ligations!
	if ( mpos_max < 0 ) mpos_max = length( seq_from_library );  //to catch boundary cases -- no match to constant sequence.

	if ( match_DP ){
	  //Set options for match, mismatch, gap. Again, should make these variables.
	  Pattern<String<char>, DPSearch<SimpleScore> >  pattern_in_specific_sequence (seq2,SimpleScore(0, -2, -1));
	  int EDIT_DISTANCE_SCORE_CUTOFF( -4 );
	  setScoreLimit(pattern_in_specific_sequence, EDIT_DISTANCE_SCORE_CUTOFF);

	  if ( mpos_vector.size() == 0 ) mscr = EDIT_DISTANCE_SCORE_CUTOFF - 1;
	  // Here, looking for best score -- but assuming that we've nailed the right RNA sequence (which may not be the case).
	  while (find(finder_in_specific_sequence, pattern_in_specific_sequence)) {
	    int cscr = getScore(pattern_in_specific_sequence);
	    if(cscr > mscr) {
	      mscr=cscr;
	      mpos_vector.clear();
	      sid_vector.clear();
	    }
	    if ( cscr == mscr ){ // in case of ties, keep track of all hits
	      findBegin( finder_in_specific_sequence, pattern_in_specific_sequence, mscr ); // the proper thing to do if DP is used.
	      unsigned mpos = beginPosition( finder_in_specific_sequence );
	      //std::cout << "FOUND IT " << cscr << " " << mscr << " " << mpos << " " << mpos_max << std::endl;
	      if ( mpos <= unsigned( mpos_max ) ) {
		mpos_vector.push_back( mpos );
		sid_vector.push_back( sid_idx );
	      }
	    }
	  }

	} else {  // default -- use fast MyersUkkonen [approximate search]
	  // following copies code from DP block. Can't figure out how to avoid this -- Pattern is not sub-classed,
	  // so Pattern< MyersUkkonen> cannot be interchanged with Pattern< DPsearch >. --Rhiju
	  // Alternative to DP -- edit distance, used by JP
	  //	  Pattern<String<char>, Myers<  AlignTextBanded< FindInfix, NMatchesN_, NMatchesN_> > > pattern_in_specific_sequence(seq2);
	  Pattern<String<char>, Myers< FindInfix > > pattern_in_specific_sequence(seq2);
	  int EDIT_DISTANCE_SCORE_CUTOFF( strict ? 0 : -2 );
	  setScoreLimit(pattern_in_specific_sequence, EDIT_DISTANCE_SCORE_CUTOFF);//Edit Distance used to be -10! not very stringent.

	  if ( mpos_vector.size() == 0 ) mscr = EDIT_DISTANCE_SCORE_CUTOFF - 1;

	  // Here, looking for best score -- but assuming that we've nailed the right RNA sequence (which may not be the case).
	  while (find(finder_in_specific_sequence, pattern_in_specific_sequence)) {
	    int cscr = getScore(pattern_in_specific_sequence);
	    if ( cscr >= mscr ){ // in case of ties, keep track of all hits
	      findBegin( finder_in_specific_sequence, pattern_in_specific_sequence, mscr );
	      int mpos = beginPosition( finder_in_specific_sequence )-1;
	      if ( mpos < 0 ) mpos = 0;
	      //	      if ( sid_idx >= 200 && mpos > 180 ) { if (!verbose) { std::cout << std::endl; verbose = true;} }
	      //	      if ( verbose ) std::cout << "check: " << mpos << " gives score " << cscr << std::endl;
	      // watch out ... this can't go beyond the "sequence id"!?
	      //std::cout << mpos << " " << mpos_max << std::endl;
	      if ( mpos <= mpos_max ) {
		if(cscr > mscr){
		  mscr=cscr;
		  mpos_vector.clear();
		  sid_vector.clear();
		}
		if ( !already_saved( mpos_vector, sid_vector, mpos, sid_idx ) ){
		  mpos_vector.push_back( mpos );
		  sid_vector.push_back( sid_idx );
		}
	      }
	    }
	  }
	}
	//	  if ( verbose ) std::cout << "pattern: " << seq2 << " vs finder " << seq_from_library << std::endl;
	if (verbose )  std::cout << "in read 2, checking " << sid_idx << ": " << sid_vector.size() << " " << seq1 << " " << seq2 << " [ score: " << mscr << " ] " << std::endl;
	//std::cout << "mpos_vector.size(): " << mpos_vector.size() << ", seq2: " << seq2 << std::endl;
      }

      if ( mpos_vector.size() == 0 ) continue;

      found_match_in_read2 = true;
      record_counter( "found match in RNA sequence (read 2)", counter_idx, counter_counts, counter_tags );
      if ( mscr == 0 ) record_counter( "found strict match in RNA sequence (read 2)", counter_idx, counter_counts, counter_tags );

      float const weight = 1.0 / mpos_vector.size();
      for (unsigned q = 0; q < mpos_vector.size(); q++ ){
	int sid_idx = sid_vector[q];
	int mpos    = mpos_vector[q];
	if ( verbose ) std::cout << "READ2 " << mpos << " " << sid_idx << std::endl;
	if ( mpos < 0 ) mpos = 0;
	all_count[ expt_idx ][ sid_idx ][ mpos ] += weight;
	if ( mscr == 0 ) all_count_strict[ expt_idx ][ sid_idx ][ mpos ] += weight;
      }
    }


    std::cout << "Aligning " << seqCount1 << " sequences took " << SEQAN_PROTIMEDIFF(alignTime) << " seconds " << std::endl;

    std::cout << std::endl;
    std::cout << "Purification table" << std::endl;
    for ( unsigned i = 0; i < counter_counts.size(); i++ ){
      std::cout << counter_counts[i] << " " << counter_tags[i] << std::endl;
    }
    std::cout << std::endl;

    std::cout << "Perfect constant sequence: " << perfect << std::endl;
    if ( align_all ) std::cout << "Null ligations           : " << nullLigation << std::endl;

    output_stats_files( all_count, outpath, "stats" );
    output_stats_files( all_count_strict, outpath, "strict_stats" );

    return 1;
}

///////////////////////////////////////////////
// helper utilities -- move to separate file?
///////////////////////////////////////////////

/////////////////////////////////////////////
// how many residues match up from one end?
int
get_number_of_matching_residues( std::vector< CharString > const & seq_primers ){

  unsigned count = 1;
  unsigned seqCount_primers = seq_primers.size();
  bool all_match( true );
  while ( all_match && count < length( seq_primers[0] )){
    char current_char;
    for(unsigned j=0; j< seqCount_primers; j++) {
      if ( j == 0 ) current_char = getValue( seq_primers[j], count );
      if (getValue( seq_primers[j], count ) != current_char ){
	all_match = false;
	break;
      }
    }
    count++;
  }
  return (count-1);
}

/////////////////////////////////////
void RNA2DNA( String<char> & seq ){
 seqan::Iterator<seqan::String<char> >::Type it = begin(seq);
 seqan::Iterator<seqan::String<char> >::Type itEnd = end(seq);

 while (it != itEnd) {
   if (*it == 'U') *it = 'T';
   ++it;
 }
}

/////////////////////////////////////
int
findchar( String<char> & seq, char c ){
 seqan::Iterator<seqan::String<char> >::Type it = begin(seq);
 seqan::Iterator<seqan::String<char> >::Type itEnd = end(seq);
 int n( 0 );
 while (it != itEnd) {
   if (*it == c ) return n;
   ++it;
   ++n;
 }
 return -1;
}

/////////////////////////////////////
void record_counter( std::string const tag,
		     unsigned & counter_idx,
		     std::vector< unsigned > & counter_counts,
		     std::vector< std::string > & counter_tags ){

  if (counter_idx >= counter_tags.size() ) {
    counter_tags.push_back( tag );
    counter_counts.push_back( 0 );
  }
  counter_counts[ counter_idx ]++;
  counter_idx++;
  //  std::cout << "counter_idx: " << counter_idx << std::endl;
}



/////////////////////////////////////////////////////////////////////////////
int
try_exact_match( CharString & seq1, CharString & cseq, unsigned & perfect ){

  int pos1( -1 );

  // try exact match with indexing
  // indexed is slow [though this might be fast if I index everything at once...]
  //Index<CharString> index( seq1 );
  //	Finder< Index<CharString> > finder( index );
  //	if ( find( finder, cseq ) ) pos1 = position( finder );

  Finder<String<char> > finder_constant_sequence(seq1); // this is what to search.
  Pattern<String<char>, Horspool > pattern_constant_sequence( cseq );
  if( find(finder_constant_sequence, pattern_constant_sequence) ) pos1 = position( finder_constant_sequence );

  if (pos1 > -1 ) perfect++;

  return pos1; // no position found
}

/////////////////////////////////////////////////////////////////////////////
int
try_exact_match( CharString & seq1, CharString & cseq ){
  unsigned perfect( 0 );
  return try_exact_match( seq1, cseq, perfect );
}


/////////////////////////////////////////////////////////////////////////////
int
try_DP_match( CharString & seq1, CharString & cseq, unsigned & perfect ){

  int pos1( -1 );

  Finder<String<char> > finder_constant_sequence(seq1); // this is what to search.
  //Set options for gap, mismatch,deletion
  int score_cutoff( -2 ), best_score( score_cutoff-1 );
  Pattern<String<char>, DPSearch<SimpleScore> > pattern_constant_sequence_DP(cseq,SimpleScore(0, -2, -1));

  // Find best match in case there are several.
  while( find(finder_constant_sequence, pattern_constant_sequence_DP, score_cutoff)) {
    if(getScore(pattern_constant_sequence_DP) > best_score) {
      best_score = getScore(pattern_constant_sequence_DP);
      pos1 = position(finder_constant_sequence);

      if ( best_score == 0 ) break; // early exit if we have an exact match already.
      // go to beginning of primer binding site
      // following is slow, and compared to simply decrementing by the length of the primer binding site (assume no indel),
      //  only adds ~1% to number of reads discovered.
      // findBegin( finder_constant_sequence, pattern_constant_sequence, best_score );
      // constant_sequence_begin_pos = beginPosition( finder_constant_sequence ) - 1;
    }
  }

  if( best_score == 0 ) perfect++;

  return pos1;
}

///////////////////////////////////////////////////////////////////////////////
int
try_DP_match_expt_ids( std::vector< CharString > & short_expt_ids, CharString & expt_id_in_read1 ){

  // use DP to allow mismatches
  int score_cutoff( -2 ), best_score( score_cutoff - 1 ), expt_idx( -1 );

  for ( unsigned n = 0; n < short_expt_ids.size(); n++ ){

    Finder<String<char> > finder_one_expt_id( expt_id_in_read1 );

    // could we save some time by preconstructing patterns?
    String<char> & ndl = short_expt_ids[n]; // this is the needle. const doesn't seem to work.
    //Set options for match, mismatch, gap. Again, should make these variables.
    // penalize gaps to take into account length mismatches!
    //    Pattern<String<char>, DPSearch<SimpleScore> > pattern_expt_id(ndl,SimpleScore(-1, -2, -1));
    Pattern<String<char>, DPSearch<SimpleScore> > pattern_expt_id(ndl,SimpleScore(0, -1, -1));

    best_score = score_cutoff - 1;

    while ( find( finder_one_expt_id, pattern_expt_id, score_cutoff )) { // shoud set score cutoff (-2) to be a variable.
      // for now assume no ties are possible -- perhaps in future output warning, or discard ambiguous.
      int score = getScore( pattern_expt_id );
      if ( score >= best_score) {
	best_score = score;
	// slow  -- see note on findBegin in try_DP_match()
	//  while( findBegin( finder_expt_id, pattern_expt_id, score ) ){
	//    constant_sequence_begin_pos = beginPosition(finder_expt_id) - 1;
	//  }
	expt_idx = n;
      }
      if ( score == 0 ) break; // best possible score.
    }

  }

  return expt_idx;
}


////////////////////////////////////////////////////
bool
get_next_variant( CharString const & seq, CharString & seq_var, unsigned & variant_counter, unsigned const & seqid_length ){

  seq_var = seq;

  if (variant_counter == 0 ){
    variant_counter++; return true;
  }

  unsigned count(0), pos_count( 0);
  seqan::Iterator<seqan::String<char> >::Type it = begin(seq_var);
  seqan::Iterator<seqan::String<char> >::Type itEnd = end(seq_var);

  static std::string const DNAchars ("ACGT"); // this probably exists somewhere in seqan... too lazy to go find it.

  while ( it != itEnd && pos_count < seqid_length ) {
    for ( unsigned n = 0; n < DNAchars.size(); n++ ){
      if ( DNAchars[n] == *it ) continue;

      count++;
      if ( count == variant_counter ){
	*it = DNAchars[n];
	variant_counter++;
	return true;
      }
    }
    ++it;
    pos_count++;
  }

  return false;

}

////////////////////////////////////////////////////
void
check_for_star_sequence( CharString & seq_from_library,
			 std::vector< CharString > & sequences_before_star,
			 std::vector< CharString > & sequences_after_star,
			 std::vector< unsigned > & star_sequence_ids,
			 unsigned const j ){

  int star_pos = findchar( seq_from_library, '*' );  // ironically, no simple equivalent to std::findin seqan
  if ( star_pos > -1 ){
    CharString sequence_before_star = prefix(seq_from_library,star_pos  );
    CharString sequence_after_star  = suffix(seq_from_library,star_pos+1);

    // following removes star from sequence stored in main library.
    // But later decided to keep the '*' in to prevent alignment
    //  using 'standard' protocol in main loop.
    CharString seq_from_library_new = sequence_before_star;
    append( seq_from_library_new, sequence_after_star );
    if ( findchar( seq_from_library_new, '*' ) > -1 ) {
      std::cerr << "Too many *'s in sequence: " << seq_from_library << std::endl;
      exit( 0 );
    }
    //    seq_from_library = seq_from_library_new;

    star_sequence_ids.push_back( j );
    sequences_before_star.push_back( sequence_before_star );
    sequences_after_star.push_back( sequence_after_star );
  }
}


/////////////////////////////////////////////////////////////
void
figure_out_expt_IDs( std::string const & file_primers,
		     std::string const & file_expt_id,
		     std::vector< String<char> > & short_expt_ids,
		     THaystacks & haystacks_expt_ids,
		     CharString & cseq,
		     CharString & adapterSequence ){

  CharString seq_expt_id;

    if ( length( file_primers ) > 0 ){

      MultiSeqFile multiSeqFile_primers; //barcode patterns
      if (!open(multiSeqFile_primers.concat, file_primers.c_str(), OPEN_RDONLY) ) exit( 0 );
      AutoSeqFormat format_primers;
      guessFormat(multiSeqFile_primers.concat, format_primers);
      split(multiSeqFile_primers, format_primers);

      unsigned seqCount_primers = length(multiSeqFile_primers);
      if ( seqCount_primers == 0 ) { std::cerr << "Must have at least one primer!" << std::endl; exit( 0 ); }
      std::cout << "Number of primers: " << seqCount_primers << std::endl;

      String<char > seq_primer;
      std::vector< String<char> > seq_primers, seq_primers_RC;
      for(unsigned j=0; j< seqCount_primers; j++) {
	assignSeq(seq_primer, multiSeqFile_primers[j], format_primers);    // read sequence
	seq_primers.push_back( seq_primer );

	CharString seq_primer_RC( seq_primer );
	reverseComplement( seq_primer_RC );
	seq_primers_RC.push_back( seq_primer_RC);
      }

      // now look for what sequence is shared across all primers from 5' end (should be Illumina adapter):
      // this will need to be rewritten if we use primers containing index reads.
      unsigned match_5prime = get_number_of_matching_residues( seq_primers );

      // straightforward override if illumina adapter is in there...
      if ( length( seq_primers[0] ) > length( universal_adapter_sequence ) ){
	if ( prefix( universal_adapter_sequence, length( universal_adapter_sequence ) ) == universal_adapter_sequence ){
	  std::cout << "Identified universal Illumina adapter sequence in primers! " << std::endl;
	  match_5prime = length( universal_adapter_sequence );
	}
      }

      //std::cout << "Matching from 5' end" << match_5prime << std::endl;
      CharString adapterSequence_inferred = prefix( seq_primers[0], match_5prime );
      if (length(adapterSequence) > 0 ){
	if ( adapterSequence != adapterSequence_inferred ){
	  std::cerr << "These do not match: " << std::endl;
	  std::cerr << adapterSequence << " [user input adapterSequence]; ";
	  std::cerr << adapterSequence_inferred << " [inferred adapterSequence]" << std::endl;
	  std::cerr << "over-riding with user-input." << std::endl << std::endl;
	}
      } else {
	adapterSequence = adapterSequence_inferred;
      }
      std::cout << "Adapter sequence shared by primers: " << adapterSequence << std::endl;


      unsigned match_3prime = get_number_of_matching_residues( seq_primers_RC );
      std::cout << "Matching from 3' end [showing reverse complement], " << match_3prime << std::endl;
      CharString cseq_inferred =  prefix( seq_primers_RC[0], match_3prime );
      if (length(cseq) > 0 ){
	if ( cseq != cseq_inferred ){
	  std::cerr << "WARNING! these do not match: " << std::endl;
	  std::cerr << cseq << " [user input cseq]" << std::endl;
	  std::cerr << cseq_inferred << " [inferred cseq]" << std::endl;
	  std::cerr << "over-riding with user-input." << std::endl << std::endl;
	}
      } else {
	cseq = cseq_inferred;
      }
      std::cout << "Constant sequence shared by primers [reverse complement]: " << cseq << std::endl;

      for(unsigned j=0; j< seqCount_primers; j++) {
	seq_expt_id = infix( seq_primers_RC[j], match_3prime, length( seq_primers_RC[j] ) - match_5prime );
	std::cout << "Experimental ID inferred [reverse complement of region in primer]: " << j << " " << seq_expt_id << std::endl;
	short_expt_ids.push_back( seq_expt_id );
	appendValue(haystacks_expt_ids, seq_expt_id );
      }

    } else if ( length( file_expt_id ) > 0 && length( cseq ) > 0 ){

      MultiSeqFile multiSeqFile_expt_id; //barcode patterns
      if (!open(multiSeqFile_expt_id.concat, file_expt_id.c_str(), OPEN_RDONLY) ) exit( 0 );

      AutoSeqFormat format_expt_id;
      guessFormat(multiSeqFile_expt_id.concat, format_expt_id);
      split(multiSeqFile_expt_id, format_expt_id);

      unsigned seqCount_expt_id = length(multiSeqFile_expt_id);

      if ( length( adapterSequence ) == 0 ) adapterSequence = universal_adapter_sequence;

      std::cout << "Getting " << seqCount_expt_id << " experimental IDs from 'barcode' file" << std::endl;
      ///////////////////////////////////////////////////
      // create a haystack to search with barcodes.
      ///////////////////////////////////////////////////
      for(unsigned j=0; j< seqCount_expt_id; j++) {
	//	assignSeqId(seq_expt_id_ID, multiSeqFile_expt_id[j], format_expt_id);    // read sequence
	assignSeq(seq_expt_id, multiSeqFile_expt_id[j], format_expt_id);    // read sequence

	short_expt_ids.push_back( seq_expt_id );
	appendValue(haystacks_expt_ids, seq_expt_id );
      }
    } else {
      std::cerr << std::endl << "ERROR! Must specify -p <primer_file>, or -b <barcode_file> -c <constant DNA sequence>." << std::endl;;
      exit( 0 );
    }
}


//////////////////////////////////////////////////
void
read_in_fastq( MultiSeqFile & multiSeqFile1,
	       AutoSeqFormat & format1,
	       std::string const & file1,
	       unsigned & seqCount1 ){

  std::cout << "Reading file: " << file1 << std::endl;

  if (!open(multiSeqFile1.concat, file1.c_str(), OPEN_RDONLY) ) { std::cerr << "Problem reading file "+file1 << std::endl; exit( 0 );}

  //The SeqAn library has a built in file parser that can guess the file format
  //we use the AutoSeqFormat option for the MiSeq, Library, and barcode files
  //MiSeq File1
  guessFormat(multiSeqFile1.concat, format1);
  split(multiSeqFile1, format1);
  seqCount1 = length(multiSeqFile1);
}


//////////////////////////////////////////////////
void
check_unique_id(  std::vector< String<char> > const & rna_library_vector_RC,
		  CharString const & cseq,
		  unsigned & seqid_length,
		  unsigned const & max_rna_len  ){

    //Infer RNA library sequence ID length.  This should have been specified by the -n flag, but this will
    //throw a warning if an incorrect value is believed to have been specified.
    //An accurate RNA library sequence ID length should be the shortest sequence from the 3' end that is
    //sufficient to distinguish any sequence in the library from any other.
    unsigned inferred_id_length = 0;
    bool match_found = true;
    unsigned cseq_len = length( cseq );
    for(unsigned i = 1; i < max_rna_len - cseq_len; i++){
      if(!match_found) break;
      inferred_id_length = i;
      match_found = false;
      unsigned const seqCount_library = rna_library_vector_RC.size();
      for(unsigned j = 0; j < seqCount_library; j++){
	String<char> test_seq = prefix( rna_library_vector_RC[j], i+cseq_len );
	for(unsigned k = j+1; k < seqCount_library; k++){
	  String<char> comp_seq = prefix( rna_library_vector_RC[k], i+cseq_len );
	  if(test_seq == comp_seq){
	    match_found = true;
	    break;
	  }
	}
	if(match_found) break;
      }
    }
    std::cerr << "Inferred sequence ID length needed to ensure disambiguation: " << inferred_id_length << std::endl;

    if (seqid_length < 1){
      std::cout << "Sequence ID length undefined by user. Using inferred sequence ID length as sequence ID length." << std::endl;
      seqid_length = inferred_id_length;
    }
    else if (inferred_id_length >  seqid_length){
      std::cerr << "These do not match: ";
      std::cerr << seqid_length << " [user input sequence ID length] and ";
      std::cout << inferred_id_length << " [inferred sequence ID length]" << std::endl;
      std::cerr << "Identical regions of user-specified length found in RNA library, and will try to disambiguate." << std::endl;
    }

    if (inferred_id_length >=  max_rna_len - cseq_len-1){
      std::cerr << "WARNING! Redundant RNA library members detected!" << std::endl;
    }
}


/////////////////////////////////////////////////////
void
disambiguate_possible_sids( std::vector< unsigned > & possible_sids,
			    std::vector< unsigned > const & possible_begpos,
			    unsigned const min_pos,
			    CharString const & seq1,
			    std::vector< CharString > const & RNA_sequences ) {
  int max_match = 0;
  CharString seq_from_library;
  std::vector< unsigned > possible_sids_new;
  for ( int s = 0; s < possible_sids.size(); s++ ) {
    seq_from_library = RNA_sequences[ possible_sids[s] ];
    int n_seq1    = min_pos           ; // + seqid_length;
    int n_library = possible_begpos[s]; // + seqid_length;
    unsigned num_match( 0 );
    while ( n_seq1 >= 0 && n_library >= 0 &&
	    ( seq1[ n_seq1 ] == seq_from_library[ n_library ] ) ){
      n_seq1--; n_library--; num_match++;
    }
    if ( num_match > max_match )  {
      possible_sids_new.clear();
      max_match = num_match;
    }
    if ( num_match == max_match ) possible_sids_new.push_back( possible_sids[s] );
  }
  possible_sids = possible_sids_new;
}


/////////////////////////////////////////////////////
// should only be called with --align_all or -A option.
void
check_for_short_insert( CharString const & adapterSequence2,
			CharString const & cseq,
			unsigned const & constant_sequence_begin_pos,
			unsigned const & seqid_length,
			CharString & seq1,
			Finder<Index<THaystacks> > & finder_sequence_id,
			std::vector< unsigned > & possible_sids,
			bool const & align_null,
			bool & verbose,
			unsigned & nullLigation ){

  CharString adapter_sequence2_pattern = adapterSequence2;
  int length_of_adapter_sequence2( constant_sequence_begin_pos - seqid_length - 1 );
  static int const min_length_of_adapter_sequence2( 7 );
  if ( length_of_adapter_sequence2 < min_length_of_adapter_sequence2 ) length_of_adapter_sequence2 = min_length_of_adapter_sequence2;
  if ( length_of_adapter_sequence2 < length( adapterSequence2 ) ){
    adapter_sequence2_pattern = infixWithLength( adapterSequence2, 0, length_of_adapter_sequence2 );
  }
  reverseComplement( adapter_sequence2_pattern );
  Pattern<String<char>, DPSearch<SimpleScore> > pattern_constant_sequence_DP( adapter_sequence2_pattern, SimpleScore(0, -2, -2));
  Finder<String<char> > finder_in_seq1(seq1);
  int adapter_sequence2_pos( 0 );
  CharString fragment;

  if ( find( finder_in_seq1, pattern_constant_sequence_DP, -1 /*score cutoff*/ ) ){
    adapter_sequence2_pos = beginPosition( finder_in_seq1 );
    if ( constant_sequence_begin_pos >= adapter_sequence2_pos - 1  ){
      if ( align_null || constant_sequence_begin_pos >= adapter_sequence2_pos )  {
	fragment = infixWithLength( seq1, adapter_sequence2_pos, constant_sequence_begin_pos - adapter_sequence2_pos + 1);
	CharString sequence_id_in_read1 = fragment;
	append( sequence_id_in_read1, cseq );
	std::vector< unsigned > mpos_vector, sid_vector;
	Pattern<CharString> pattern_sequence_id_in_read1( sequence_id_in_read1 ); // this is now the 'needle' -- look for this sequence in the haystack of potential sequence IDs
	clear( finder_sequence_id );
	while( find(finder_sequence_id, pattern_sequence_id_in_read1)) { // let's try *all* possibilities
	  int sid = beginPosition(finder_sequence_id).i1;
	  possible_sids.push_back( sid );
	  // note that this is a totally valid guess for mpos -- but we'll still check read2
	  int mpos = beginPosition(finder_sequence_id).i2;
	  //if (!verbose) std::cout << seq1 << " " << seq2 << std::endl;
	  //	  if ( sid == 180 && length( fragment ) >= 10 ) verbose = true;
	  if ( verbose ) std::cout << "READ1 " << mpos << " " << sid << " " << seq1 << " " << length( fragment ) << " " << fragment << std::endl;
	}
      }
    }
    if ( constant_sequence_begin_pos == adapter_sequence2_pos-1 ) nullLigation += 1;
  }
}


////////////////////////////////////
void
find_possible_sids( std::vector< unsigned > & possible_sids,
		    std::vector< unsigned > & possible_begpos,
		    Finder<Index<THaystacks> > & finder_sequence_id,
		    CharString & sequence_id_region_in_sequence1 ){

  Pattern<CharString> pattern_sequence_id_in_read1(sequence_id_region_in_sequence1); // this is now the 'needle' -- look for this sequence in the haystack of potential sequence IDs
  clear( finder_sequence_id ); //reset.
  while( find(finder_sequence_id, pattern_sequence_id_in_read1)) {
    // seq_from_library contains the RNA library sequences
    possible_sids.push_back( beginPosition(finder_sequence_id).i1 );
    possible_begpos.push_back( beginPosition(finder_sequence_id).i2 ); // useful for disambiguation.
  }
}


////////////////////////////////////
void
check_for_extra_junk_using_star_sequences(
					  std::vector< unsigned > & possible_sids,
					  std::vector< CharString > & sequences_with_extra_junk,
					  bool & extra_junk_mode,
					  Finder<Index<THaystacks> > & finder_sequence_id,
					  CharString & seq1,
					  unsigned const & constant_sequence_begin_pos,
					  std::vector< CharString > const & sequences_before_star,
					  std::vector< CharString > const & sequences_after_star,
					  std::vector< unsigned > const & star_sequence_ids ){

  for ( unsigned s = 0; s < star_sequence_ids.size(); s++ ){
    // find it.
    static int const min_length_of_sequence_before_star( 6 );
    CharString sequence_before_star = sequences_before_star[ s ];
    CharString search_suffix = suffix( sequence_before_star, length( sequence_before_star ) - min_length_of_sequence_before_star );
    CharString extra_junk;
    int star_pos( -1 );
    Finder<String<char> > finder_constant_sequence(seq1); // this is what to search.
    Pattern<String<char>, Horspool > pattern_constant_sequence( search_suffix );
    while( find(finder_constant_sequence, pattern_constant_sequence) ){
      int const finder_end_pos =  position( finder_constant_sequence )  + length( search_suffix );
      if ( finder_end_pos < constant_sequence_begin_pos + 1 ) star_pos = finder_end_pos;
      //if ( finder_end_pos < constant_sequence_begin_pos ) star_pos = finder_end_pos;
      else break;
    }
    if (star_pos > -1 ){
      int extra_junk_length = constant_sequence_begin_pos - star_pos + 1;
      if ( extra_junk_length > 0 ){
	extra_junk = infixWithLength( seq1, star_pos, extra_junk_length );
	// what is the reconstructed sequence?
	CharString sequence_with_extra_junk = sequence_before_star;
	append( sequence_with_extra_junk, extra_junk );
	CharString sequence_after_star = sequences_after_star[ s ];
	append( sequence_with_extra_junk, sequence_after_star );
	if (!extra_junk_mode ) {
	  if ( possible_sids.size() > 0 ) {
	    std::cerr << "cannot align to star/junk sequences if another option is available" << std::endl; exit( 0 );
	  }
	  extra_junk_mode = true;
	}
	possible_sids.push_back( star_sequence_ids[s] );
	sequences_with_extra_junk.push_back( sequence_with_extra_junk );
	// verbose = true;
      }

    }
    //std::cout << "MYSTERY " << seq1 << " look for "  << search_suffix << " " << star_pos << " " << extra_junk << std::endl;
  }
}

//////////////////////////////////////
void
output_stats_files( std::vector< std::vector< std::vector < double > > > const & all_count,
		    std::string const & outpath,
		    std::string const file_prefix )
{

  unsigned const seqCount_expt_id = all_count.size();
  std::cout << std::endl;
  //////////////////////////////////////////////////////
  //  output matrices with stored counts.
  //////////////////////////////////////////////////////
  for ( unsigned i = 0; i < seqCount_expt_id; i++ ){
    char stats_outFileName[ 100 ];
    sprintf( stats_outFileName, "%s%s_ID%d.txt", outpath.c_str(), file_prefix.c_str(), i+1 ); // index by 1.
    std::cout << "Outputting counts to: " << stats_outFileName << std::endl;
    FILE * stats_oFile;
    stats_oFile = fopen( stats_outFileName,"w");

    unsigned const seqCount_library = all_count[i].size();
    for ( unsigned j = 0; j < seqCount_library; j++ ){
      double total_for_RNA( 0.0 );

    unsigned const max_rna_len = all_count[i][j].size() - 1;
      for ( unsigned k = 0; k < max_rna_len+1; k++ ){
	fprintf( stats_oFile, " %11.3f", all_count[i][j][k] );
	total_for_RNA += all_count[i][j][k];
      }
      // std::cout << total_for_RNA << std::endl; // was used to check if total was integer.
      fprintf( stats_oFile, "\n");
    }
    fclose( stats_oFile );
  }
}


bool
already_saved( std::vector< unsigned > const & mpos_vector,
	       std::vector< unsigned > const & sid_vector,
	       unsigned const & mpos,
	       unsigned const & sid ){

  for ( std::vector< unsigned >::const_iterator miter = mpos_vector.begin(),
	  siter = sid_vector.begin();
	miter != mpos_vector.end() && siter != sid_vector.end();
	miter++, siter++ ){
    if ( *miter == mpos &&
	 *siter == sid ) {
      //      std::cout << "ALREADY THERE " << mpos << " " <<  sid << std::endl;
      return true;
    }
  }
  return false;
}

