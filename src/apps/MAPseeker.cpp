#define SEQAN_PROFILE // enable time measurements
#include <seqan/misc/misc_cmdparser.h>
#include <tr1/unordered_map>
#include <seqan/file.h>
#include <iostream>
#include <seqan/find.h>
#include <seqan/index.h>
#include <seqan/store.h>
#include <seqan/basic.h>
#include <sstream>
#include <string>
#include <stdio.h>

using namespace seqan;
std::string IntToStr( int n )
{
    std::ostringstream result;
    result << n;
    return result.str();
}

int
get_number_of_matching_residues( std::vector< CharString > const & seq_primers );

// could put following in util file?
void RNA2DNA( String<char> & seq );

// could package into a little class:
void record_counter( std::string const tag,
		     unsigned & counter_idx,
		     std::vector< unsigned > & counter_counts,
		     std::vector< std::string > & counter_tags );

int try_exact_match( CharString & seq1, CharString & cseq, unsigned & perfect );
int try_DP_match( CharString & seq1, CharString & cseq, unsigned & perfect );

int try_DP_match_expt_ids( std::vector< CharString > & short_expt_ids, CharString & expt_id_in_read1 );

bool
get_next_variant( CharString const & seq, CharString & seq_var, unsigned & variant_counter, int const & seqid_length );

//The known library of sequences is stored as a StringSet called THaystacks
//We will generate an index against this file to make the search faster
typedef StringSet<CharString> THaystacks;

//A hashmap is used to map the experimental ids to the descriptive labels
typedef std::tr1::unordered_map<std::string, std::string> hashmap;

//Versioning information
inline void
_addVersion(CommandLineParser& parser) {
    ::std::string rev = "$Revision: 0001 $";
    addVersionLine(parser, "Version 1.1 (27 December 2012) Revision: " + rev.substr(11, 4) + "");
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

    addUsageLine(parser, "-c <constant sequence> -1 <miseq output1> -2 <miseq output2> -l <library> -b <experimental barcodes> -n <sequence id length> -d <0/1 output type>");

    addSection(parser, "Main Options:");

    //cseq is the constant region between the experimental id and the sequence id
    //in the Das lab this is the tail2 sequence AAAGAAACAACAACAACAAC
    std::string const daslab_tail2_sequence("AAAGAAACAACAACAACAAC");
    // a.k.a. TruSeq Universal Adapter -- gets added to one end of many illumina preps. Should be shared 5' end of all primers.
    std::string const universal_adapter_sequence("AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATCT");

    addOption(parser, addArgumentText(CommandLineOption("c", "cseq", "Constant sequence", OptionType::String,""), "<DNA sequence>"));
    addOption(parser, addArgumentText(CommandLineOption("1", "miseq1", "miseq output [read 1] containing primer ids",OptionType::String), "<FASTAQ FILE>"));
    addOption(parser, addArgumentText(CommandLineOption("2", "miseq2", "miseq output [read 2] containing 3' ends",OptionType::String), "<FASTAQ FILE>"));
    addOption(parser, addArgumentText(CommandLineOption("l", "library", "library of sequences to align against", OptionType::String),"<FASTA FILE>"));
    addOption(parser, addArgumentText(CommandLineOption("b", "barcodes", "fasta file containing experimental barcodes", OptionType::String,""), "<FASTA FILE>"));
    addOption(parser, addArgumentText(CommandLineOption("p", "primers", "fasta file containing experimental primers", OptionType::String,""), "<FASTA FILE>"));
    addOption(parser, addArgumentText(CommandLineOption("o", "outfile", "output filename", (int)OptionType::String, "out.fasta"), "<Filename>"));
    addOption(parser, addArgumentText(CommandLineOption("n", "sid_length", "sequence id length", OptionType::Int), "<Int>"));
    addOption(parser, addArgumentText(CommandLineOption("x", "match_single_nt_variants", "check off-by-one matches in sequence ID in read 1", OptionType::Bool, false), ""));
    addOption(parser, addArgumentText(CommandLineOption("D", "match_DP", "use dynamic programming in matching sequence ID in read 2 (allow in/del)", OptionType::Bool, false), ""));
    addOption(parser, addArgumentText(CommandLineOption("d", "debug", "full output =1, condensed output=0", OptionType::Int, 0), "<Int>"));
    addOption(parser, addArgumentText(CommandLineOption("a", "adapter", "Illumina Adapter sequence = 5' DNA sequence shared by all primers", OptionType::String,""), "<DNA sequence>"));


    if (argc == 1) {
      shortHelp(parser, std::cerr);	// print short help and exit
      return 0;
    }

    if (!parse(parser, argc, argv, ::std::cerr)) return 1;
    if (isSetLong(parser, "help") || isSetLong(parser, "version")) return 0;	// print help or version and exit

//This isn't required but shows you how long the processing took
    SEQAN_PROTIMESTART(loadTime);
    std::string file1,file2,file_library,file_expt_id,file_primers,outfile;
    String<char> cseq,adapterSequence;
    getOptionValueLong(parser, "cseq",cseq);
    getOptionValueLong(parser, "adapter",adapterSequence);
    getOptionValueLong(parser, "miseq1",file1);
    getOptionValueLong(parser, "miseq2",file2);
    getOptionValueLong(parser, "library",file_library);
    getOptionValueLong(parser, "barcodes",file_expt_id);
    getOptionValueLong(parser, "primers",file_primers);
    getOptionValueLong(parser, "outfile",outfile);
    bool match_single_nt_variants = isSetLong( parser, "match_single_nt_variants" );
    bool match_DP = isSetLong( parser, "match_DP" );
    int seqid_length=-1;    int debug=0;
    getOptionValueLong(parser,"sid_length",seqid_length);
    getOptionValueLong(parser,"debug",debug);

    //Opening the output file and returning an error if it can't be opened
    FILE * oFile;
    oFile = fopen(outfile.c_str(),"w");

    /////////////////////////////////////////////////////////////////////////
    // Read in Miseq files and RNA Library.
    /////////////////////////////////////////////////////////////////////////
    MultiSeqFile multiSeqFile1;
    MultiSeqFile multiSeqFile2;
    MultiSeqFile multiSeqFile_library;
    if (!open(multiSeqFile1.concat, file1.c_str(), OPEN_RDONLY) ) return 1;
    if (!open(multiSeqFile2.concat, file2.c_str(), OPEN_RDONLY) ) return 1;
    if (!open(multiSeqFile_library.concat, file_library.c_str(), OPEN_RDONLY) ) return 1;
    //if (cseq=="" || seqid_length==-1 )  return 1;

    //The SeqAn library has a built in file parser that can guess the file format
    //we use the AutoSeqFormat option for the MiSeq, Library, and barcode files
    //MiSeq File1
    AutoSeqFormat format1;
    guessFormat(multiSeqFile1.concat, format1);
    split(multiSeqFile1, format1);

    //MiSeq File2
    AutoSeqFormat format2;
    guessFormat(multiSeqFile2.concat, format2);
    split(multiSeqFile2, format2);

    //Library
    AutoSeqFormat format_library;
    guessFormat(multiSeqFile_library.concat, format_library);
    split(multiSeqFile_library, format_library);

    std::cout << "Reading MiSEQ and RNA library sequence files took: " << SEQAN_PROTIMEDIFF(loadTime) << " seconds." << std::endl;

    //Getting the total number of sequences in each of the files
    //The two MiSeq files should match in the number of sequences
    //They should also be in the same order
    unsigned seqCount1 = length(multiSeqFile1);
    unsigned seqCount2 = length(multiSeqFile2);
    unsigned seqCount_library = length(multiSeqFile_library);

    if(seqCount1 != seqCount2 ){
        std::cout << "MiSeq input files contain different number of sequences" << std::endl;
        return 1;
    } else {
        std::cout << "Total Pairs: " << length(multiSeqFile1) << ":" << length(multiSeqFile2) << std::endl;
    }

    // FRAGMENT(read_sequences)
    String<char> seq1,seq1id,seq2,seq_library,seq_libraryid,seq_expt_id,seq_expt_id_id,qual1,qual2,id1,id2;
    THaystacks haystacks_rna_library, haystacks_expt_ids;
    std::vector< String<char> > short_expt_ids;

    /////////////////////////////////////////////////////////////////////////
    // Figure out experimental IDs and primer binding site from barcodes.
    /////////////////////////////////////////////////////////////////////////
    if ( length( file_primers ) > 0 ){

      MultiSeqFile multiSeqFile_primers; //barcode patterns
      if (!open(multiSeqFile_primers.concat, file_primers.c_str(), OPEN_RDONLY) ) return 1;
      AutoSeqFormat format_primers;
      guessFormat(multiSeqFile_primers.concat, format_primers);
      split(multiSeqFile_primers, format_primers);

      unsigned seqCount_primers = length(multiSeqFile_primers);
      if ( seqCount_primers == 0 ) { std::cerr << "Must have at least one primer!" << std::endl; return 1; }

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
      unsigned match_5prime = get_number_of_matching_residues( seq_primers );
      //std::cout << "Matching from 5' end" << match_5prime << std::endl;
      CharString adapterSequence_inferred = prefix( seq_primers[1], match_5prime );
      if (length(adapterSequence) > 0 ){
	if ( adapterSequence != adapterSequence_inferred ){
	  std::cerr << "WARNING! these do not match: " << std::endl;
	  std::cerr << adapterSequence << " [user input adapterSequence]" << std::endl;
	  std::cerr << adapterSequence_inferred << " [inferred adapterSequence]" << std::endl;
	  std::cerr << "over-riding with user-input." << std::endl << std::endl;
	}
      } else {
	adapterSequence = adapterSequence_inferred;
      }
      std::cout << "Adapter sequence shared by primers: " << adapterSequence << std::endl;


      unsigned match_3prime = get_number_of_matching_residues( seq_primers_RC );
      //      std::cout << "Matching from 3' end [showing reverse complement]" << match_3prime << std::endl;
      CharString cseq_inferred =  prefix( seq_primers_RC[1], match_3prime );
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
	CharString seq_expt_id = infix( seq_primers_RC[j], match_3prime, length( seq_primers_RC[j] ) - match_5prime );
	std::cout << "Experimental ID inferred [reverse complement of region in primer]: " << j << " " << seq_expt_id << std::endl;
	short_expt_ids.push_back( seq_expt_id );
	appendValue(haystacks_expt_ids, seq_expt_id );
      }

    } else if ( length( file_expt_id ) > 0 && length( cseq ) > 0 ){

      MultiSeqFile multiSeqFile_expt_id; //barcode patterns
      if (!open(multiSeqFile_expt_id.concat, file_expt_id.c_str(), OPEN_RDONLY) ) return 1;

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
	assignSeqId(seq_expt_id_id, multiSeqFile_expt_id[j], format_expt_id);    // read sequence
	assignSeq(seq_expt_id, multiSeqFile_expt_id[j], format_expt_id);    // read sequence

	short_expt_ids.push_back( seq_expt_id );
	appendValue(haystacks_expt_ids, seq_expt_id );
      }
    } else {
      std::cerr << std::endl << "ERROR! Must specify -p <primer_file>, or -b <barcode_file> -c <constant DNA sequence>." << std::endl;;
      return 1;
    }
    unsigned seqCount_expt_id = short_expt_ids.size();

    //    Index<THaystacks> index_expt_ids(haystacks_expt_ids);
    Finder<Index<THaystacks> > finder_expt_id(haystacks_expt_ids);

// Index library sequences for alignment
    unsigned max_rna_len( 0 );
    std::cout << "Indexing Sequences(N=" << seqCount_library << ")..";
    for(unsigned j=0; j< seqCount_library; j++) {
        assignSeq(seq_library, multiSeqFile_library[j], format_library);    // read sequence
	RNA2DNA( seq_library );
        appendValue(haystacks_rna_library, seq_library);
	if ( max_rna_len < length( seq_library ) ) max_rna_len = length( seq_library );
    }
    //    Index<THaystacks> index(haystacks_rna_library);
    Finder<Index<THaystacks> > finder_sequence_id( haystacks_rna_library );
    std::cout << "completed" << std::endl;
    std::cout << "RNA sequence Lengths(max=" << max_rna_len <<"):" << std::endl;

    // initialize a histogram recording the counts [convenient for plotting in matlab, R, etc.]
    std::vector< float > sequence_counts( max_rna_len+1,0.0 );
    std::vector< std::vector< float > > bunch_of_sequence_counts( seqCount_library+1, sequence_counts);
    std::vector< std::vector< std::vector < float > > > all_count( seqCount_expt_id, bunch_of_sequence_counts);

    // keep track of how many sequences pass through each filter
    std::vector< unsigned > counter_counts;
    std::vector< std::string > counter_tags;
    unsigned perfect=0;

    std::cout << "Running alignment" << std::endl;

    SEQAN_PROTIMESTART(alignTime); // reset counter.
    if ( debug) std::cout << "Output should be appearing in " << outfile.c_str() << std::endl;

    for (unsigned i = 0; i < seqCount1; ++i)
    {

      ////////////////////////////////////////////////////////////////
      // Get the next forward and reverse read...
      ////////////////////////////////////////////////////////////////
      assignSeq(seq1, multiSeqFile1[i], format1);    // read sequence
      assignQual(qual1, multiSeqFile1[i], format1);  // read ascii quality values
      assignSeqId(id1, multiSeqFile1[i], format1);   // read sequence id

      assignSeq(seq2, multiSeqFile2[i], format2);    // read sequence
      assignQual(qual2, multiSeqFile2[i], format2);  // read ascii quality values
      assignSeqId(id2, multiSeqFile2[i], format2);   // read sequence id

      reverseComplement(seq1);

      unsigned counter_idx( 0 ); // will keep track of which filter we pass.
      record_counter( "total", counter_idx, counter_counts, counter_tags );

      ////////////////////////////////////////////////////////////////
      ////////////////////////////////////////////////////////////////
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
      if ( find( finder_expt_id, expt_id_in_read1 ) )	expt_idx = beginPosition(finder_expt_id).i1;
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
      if (min_pos < 0)	 min_pos=0;
      String<char> sequence_id_region_in_sequence1=infixWithLength(seq1,min_pos,seqid_length);
      // We append the primer binding site to make sure that the search will be over actual barcode regions (adjoining the constant sequence) from the RNA library.
      append(sequence_id_region_in_sequence1,cseq);

      // Start by looking for exact match of sequence ID in read 1, and then look for match in read 2.
      //   If that doesn't work, try single nucleotide variants [this is the job of get_next_variant()]);

      bool found_match_in_read1( false ), found_match_in_read2( false );
      unsigned variant_counter( 0 );
      CharString sequence_id_region_variant( sequence_id_region_in_sequence1 );

      while ( !found_match_in_read2 && get_next_variant( sequence_id_region_in_sequence1, sequence_id_region_variant, variant_counter, seqid_length ) ){
	//std::cout << "Looking for: " << sequence_id_region_variant << " " << variant_counter << std::endl;
	if ( !match_single_nt_variants && variant_counter > 1 ) break;

	if (!found_match_in_read1){
	  record_counter( "found match in RNA sequence (read 1)", counter_idx, counter_counts, counter_tags );
	  found_match_in_read1 = true;
	}

	Pattern<CharString> pattern_sequence_id_in_read1(sequence_id_region_variant); // this is now the 'needle' -- look for this sequence in the haystack of potential sequence IDs

	clear( finder_sequence_id ); //reset.
	if( find(finder_sequence_id, pattern_sequence_id_in_read1)) { // wait, shouldn't we try *all* possibilities?

	  // seq_library contains the RNA library sequences
	  int sid_idx = beginPosition(finder_sequence_id).i1;

	  // what is the DNA?
	  assignSeq(seq_library, multiSeqFile_library[sid_idx], format_library); // read sequence of the RNA
	  append( seq_library, short_expt_ids[ expt_idx ] ); // experimental ID, added  in MAP-seq protocol as part of reverse transcription primer
	  append( seq_library, adapterSequence ); // piece of illumina DNA, added in MAP-seq protocol as part of reverse transcription primer

	  //	assignSeqId(seq_libraryid,multiSeqFile_library[sid_idx], format_library); // read the ID of the RNA -- is this used anymore?

	  ////////////////////////////////////////////////////////////////////////////////////////
	  // Look for the second read to determine where the reverse transcription stop is.
	  ////////////////////////////////////////////////////////////////////////////////////////
	  RNA2DNA( seq_library );
	  Finder<String<char> > finder_in_specific_sequence(seq_library);
	  std::vector< int > mpos_vector;
	  if ( match_DP ){
	    //Set options for gap, mismatch, deletion. Again, should make these variables.
	    Pattern<String<char>, DPSearch<SimpleScore> >  pattern_in_specific_sequence (seq2,SimpleScore(0, -2, -1));
	    int EDIT_DISTANCE_SCORE_CUTOFF( -4 );
	    setScoreLimit(pattern_in_specific_sequence, EDIT_DISTANCE_SCORE_CUTOFF);

	    int mscr( EDIT_DISTANCE_SCORE_CUTOFF - 1 );
	    // Here, looking for best score -- but assuming that we've nailed the right RNA sequence (which may not be the case).
	    while (find(finder_in_specific_sequence, pattern_in_specific_sequence)) {
	      int cscr = getScore(pattern_in_specific_sequence);
	      if(cscr > mscr) {
		mscr=cscr;
		mpos_vector.clear();
	      }
	      if ( cscr == mscr ){ // in case of ties, keep track of all hits
		findBegin( finder_in_specific_sequence, pattern_in_specific_sequence, mscr ); // the proper thing to do if DP is used.
		int mpos = beginPosition( finder_in_specific_sequence ) - 1;
		mpos_vector.push_back( mpos );
	      }
	    }

	  } else {  // default -- use fast MyersUkkonen, which does not allow in/dels

	    // following copies code from DP block. Can't figure out how to avoid this -- Pattern is not sub-classed,
	    // so Pattern< MyersUkkonen> cannot be interchanced with Pattern< DPsearch >. --Rhiju

	    // Alternative to DP -- edit distance, used by JP
	    Pattern<String<char>, MyersUkkonen> pattern_in_specific_sequence(seq2);
	    int EDIT_DISTANCE_SCORE_CUTOFF( -2 );
	    setScoreLimit(pattern_in_specific_sequence, EDIT_DISTANCE_SCORE_CUTOFF);//Edit Distance used to be -10! not very stringent.

	    int  mscr( EDIT_DISTANCE_SCORE_CUTOFF - 1 );
	    // Here, looking for best score -- but assuming that we've nailed the right RNA sequence (which may not be the case).
	    while (find(finder_in_specific_sequence, pattern_in_specific_sequence)) {
	      int cscr = getScore(pattern_in_specific_sequence);
	      if(cscr > mscr) {
		mscr=cscr;
		mpos_vector.clear();
	      }
	      if ( cscr == mscr ){ // in case of ties, keep track of all hits
		int mpos = position( finder_in_specific_sequence ) - length(seq2)-1;// get from end to position just before beginning of the read
		mpos_vector.push_back( mpos );
	      }
	    }
	  }

	  if ( mpos_vector.size() == 0 ) continue;
	  record_counter( "found match in RNA sequence (read 2)", counter_idx, counter_counts, counter_tags );

	  //if(debug==1) fprintf(oFile,"%s,%s,%s,%s,%d,%d,%s,%s\n",toCString(id1),toCString(id2),edescr.c_str(),toCString(seq_libraryid),(mpos+1),mscr,toCString(seq2),toCString(seq_library));

	  float const weight = 1.0 / mpos_vector.size();
	  for (unsigned q = 0; q < mpos_vector.size(); q++ ){
	    int mpos = mpos_vector[q];
	    if ( mpos < 0 ) mpos = 0;
	    all_count[ expt_idx ][ sid_idx ][ mpos ] += weight;
	  }

	}

      }
    }
    std::cout << "Aligning " << seqCount1 << " sequences took " << SEQAN_PROTIMEDIFF(alignTime) << std::endl;
    std::cout << "Perfect constant sequence matches: " << perfect << std::endl;

    std::cout << std::endl;
    std::cout << "Purification table" << std::endl;
    for ( unsigned i = 0; i < counter_counts.size(); i++ ){
      std::cout << counter_counts[i] << " " << counter_tags[i] << std::endl;
    }
    std::cout << std::endl;

    //////////////////////////////////////////////////////
    //  output matrices with stored counts.
    //////////////////////////////////////////////////////
    for ( unsigned i = 0; i < seqCount_expt_id; i++ ){
      char stats_outFileName[ 50 ];
      sprintf( stats_outFileName, "stats_ID%d.txt", i+1 ); // index by 1.
      std::cout << "Outputting counts to: " << stats_outFileName << std::endl;
      FILE * stats_oFile;
      stats_oFile = fopen( stats_outFileName,"w");
      for ( unsigned j = 0; j < seqCount_library; j++ ){
    	for ( unsigned k = 0; k < max_rna_len; k++ ){
    	  fprintf( stats_oFile, " %8.1f", all_count[i][j][k] );
    	}
    	fprintf( stats_oFile, "\n");
      }
      fclose( stats_oFile );
    }

    return 0;
}

/////////////////////////////////////////////
// how many residues match up from one end?
int
get_number_of_matching_residues( std::vector< CharString > const & seq_primers ){

  int count = 1;
  int seqCount_primers = seq_primers.size();
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
try_DP_match( CharString & seq1, CharString & cseq, unsigned & perfect ){

  int pos1( -1 );

  Finder<String<char> > finder_constant_sequence(seq1); // this is what to search.
  //Set options for gap, mismatch,deletion
  int score_cutoff( -2 ), best_score( score_cutoff-1 );
  Pattern<String<char>, DPSearch<SimpleScore> > pattern_constant_sequence_DP(cseq,SimpleScore(0, -2, -1));

  // Find best match in case there are several.
  while( find(finder_constant_sequence, pattern_constant_sequence_DP, score_cutoff)) {
    if(getScore(pattern_constant_sequence_DP) > best_score) {
      best_score=getScore(pattern_constant_sequence_DP);
      pos1=position(finder_constant_sequence);

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
  int score_cutoff( -2 ), best_score( score_cutoff-1 ), expt_idx( -1 );
  for ( unsigned n = 0; n < short_expt_ids.size(); n++ ){

    Finder<String<char> > finder_one_expt_id( expt_id_in_read1 );

    // could we save some time by preconstructing patterns?
    String<char> & ndl = short_expt_ids[n]; // this is the needle. const doesn't seem to work.
    //Set options for gap, mismatch, deletion. Again, should make these variables.
    Pattern<String<char>, DPSearch<SimpleScore> > pattern_expt_id(ndl,SimpleScore(0, -2, -1));

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
get_next_variant( CharString const & seq, CharString & seq_var, unsigned & variant_counter, int const & seqid_length ){

  seq_var = seq;

  if (variant_counter == 0 ){
    variant_counter++; return true;
  }

  unsigned count(0), pos_count( 0);
  seqan::Iterator<seqan::String<char> >::Type it = begin(seq_var);
  seqan::Iterator<seqan::String<char> >::Type itEnd = end(seq_var);

  static std::string const DNAchars ("ACGT"); // this probably exists somewhere in seqan... too lazy to go find it.

  while ( it != itEnd && pos_count < seqid_length ) {
    for ( int n = 0; n < DNAchars.size(); n++ ){
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
