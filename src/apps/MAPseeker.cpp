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

// could put following in util file?
void RNA2DNA( String<char> & seq );

// could package into a little class:
void record_counter( std::string const tag,
		     unsigned & counter_idx,
		     std::vector< unsigned > & counter_counts,
		     std::vector< std::string > & counter_tags );

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
    int perfect=0;
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
    addOption(parser, addArgumentText(CommandLineOption("c", "cseq", "Constant sequence", OptionType::String), "<DNA sequence>"));
    addOption(parser, addArgumentText(CommandLineOption("1", "miseq1", "miseq output [read 1] containing primer ids",OptionType::String), "<FASTAQ FILE>"));
    addOption(parser, addArgumentText(CommandLineOption("2", "miseq2", "miseq output [read 2] containing 3' ends",OptionType::String), "<FASTAQ FILE>"));
    addOption(parser, addArgumentText(CommandLineOption("l", "library", "library of sequences to align against", OptionType::String),"<FASTA FILE>"));
    addOption(parser, addArgumentText(CommandLineOption("b", "barcodes", "fasta file containing experimental barcodes", OptionType::String), "<FASTA FILE>"));
    addOption(parser, addArgumentText(CommandLineOption("o", "outfile", "output filename", (int)OptionType::String, "out.fasta"), "<Filename>"));
    addOption(parser, addArgumentText(CommandLineOption("n", "sid.length", "sequence id length", OptionType::Int), "<Int>"));
    addOption(parser, addArgumentText(CommandLineOption("d", "debug", "full output =1 condensed output=0", OptionType::Int), "<Int>"));
    if (argc == 1)
    {
        shortHelp(parser, std::cerr);	// print short help and exit
        return 0;
    }

    if (!parse(parser, argc, argv, ::std::cerr)) return 1;
    if (isSetLong(parser, "help") || isSetLong(parser, "version")) return 0;	// print help or version and exit

//This isn't required but shows you how long the processing took
    SEQAN_PROTIMESTART(loadTime);
    std::string file1,file2,file3,file4,outfile;

//cseq is the constant region between the experimental id and the sequence id
//in the Das lab this is the tail2 sequence AAAGAAACAACAACAACAAC
    String<char> cseq="";
    getOptionValueLong(parser, "cseq",cseq);
    getOptionValueLong(parser, "miseq1",file1);
    getOptionValueLong(parser, "miseq2",file2);
    getOptionValueLong(parser, "library",file3);
    getOptionValueLong(parser, "barcodes",file4);
    getOptionValueLong(parser, "outfile",outfile);
    int seqid_length=-1;
    int debug=0;
    getOptionValueLong(parser,"sid.length",seqid_length);
    getOptionValueLong(parser,"debug",debug);

//Opening the output file and returning an error if it can't be opened
    FILE * oFile;
    oFile = fopen(outfile.c_str(),"w");

    MultiSeqFile multiSeqFile1;
    MultiSeqFile multiSeqFile2;
    MultiSeqFile multiSeqFile3;
    MultiSeqFile multiSeqFile4; //barcode patterns
    if (!open(multiSeqFile1.concat, file1.c_str(), OPEN_RDONLY) ) return 1;
    if (!open(multiSeqFile2.concat, file2.c_str(), OPEN_RDONLY) ) return 1;
    if (!open(multiSeqFile3.concat, file3.c_str(), OPEN_RDONLY) ) return 1;
    if (!open(multiSeqFile4.concat, file4.c_str(), OPEN_RDONLY) ) return 1;
    if (cseq=="" || seqid_length==-1 )  return 1;

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
    AutoSeqFormat format3;
    guessFormat(multiSeqFile3.concat, format3);
    split(multiSeqFile3, format3);

    //Barcodes
    AutoSeqFormat format4;
    guessFormat(multiSeqFile4.concat, format4);
    split(multiSeqFile4, format4);

    std::cout << "Reading un sequence files took: " << SEQAN_PROTIMEDIFF(loadTime) << " seconds." << std::endl;

    if(length(multiSeqFile1)!=length(multiSeqFile2)) {
        std::cout << "MiSeq input files contain different number of sequences" << std::endl;
        return 1;
    } else {
        std::cout << "Total Pairs: " << length(multiSeqFile1) << ":" << length(multiSeqFile2) << std::endl;
    }

//Getting the total number of sequences in each of the files
//The two MiSeq files should match in the number of sequences
//They should also be in the same order
    unsigned seqCount1 = length(multiSeqFile1);
    unsigned seqCount3 = length(multiSeqFile3);
    unsigned seqCount4 = length(multiSeqFile4);
    int unmatchedtail=0;
    int unmatchedlib=0;

// FRAGMENT(read_sequences)
    String<char> seq1;
    String<char> seq1id;
    String<char> seq2;
    String<char> seq3;
    String<char> seq3id;
    String<char> seq4;
    String<char> seq4id;
    CharString qual1;
    CharString qual2;
    CharString id1;
    CharString id2;
    THaystacks haystacks;

    std::cout << "Getting " << seqCount4 << " Barcodes.. " << std::endl;

    hashmap idmap;
    std::vector<int> eidlen;
    int max_eidlen=0;
    for(unsigned j=0; j< seqCount4; j++) {
        assignSeqId(seq4id, multiSeqFile4[j], format4);    // read sequence
        assignSeq(seq4, multiSeqFile4[j], format4);    // read sequence
        std::string desc_v=toCString(seq4id);
        std::string eid_v=toCString(seq4);
        std::cout << desc_v.c_str() << " " << eid_v.c_str() << std::endl;
        idmap[eid_v]=desc_v;
        int in=0;
        if(max_eidlen < length(seq4)) {
            max_eidlen=length(seq4);
        }
        for(int w=0; w<eidlen.size(); w++) {
            if(eidlen[w]==length(seq4)) {
                in=1;
                break;
            }
        }
        if(in==0) {
            eidlen.push_back(length(seq4));
        }
    }

//If barcodes are of different lengths print the lengths here

    std::cout << "Barcode Lengths(max=" << max_eidlen <<"):" << std::endl;
    for(int i=0; i<eidlen.size(); i++) {
        std::cout << "length: " << eidlen[i] << std::endl;
    }

// Index library sequences for alignment
    unsigned max_rna_len( 0 );
    std::cout << "Indexing Sequences(N=" << seqCount3 << ")..";
    for(unsigned j=0; j< seqCount3; j++) {
        assignSeq(seq3, multiSeqFile3[j], format3);    // read sequence
	RNA2DNA( seq3 );
        appendValue(haystacks, seq3);
	if ( max_rna_len < length( seq3 ) ) max_rna_len = length( seq3 );
    }
    Index<THaystacks> index(haystacks);
    Finder<Index<THaystacks> > finder_sequence_id(haystacks);
    std::cout << "completed" << std::endl;
    std::cout << "RNA sequence Lengths(max=" << max_rna_len <<"):" << std::endl;

    // initialize a histogram recording the counts [convenient for plotting in matlab, R, etc.]
    std::vector< unsigned > sequence_counts( max_rna_len,0);
    std::vector< std::vector< unsigned > > bunch_of_sequence_counts( seqCount3+1, sequence_counts);
    std::vector< std::vector< std::vector < unsigned > > > all_count( seqCount4, bunch_of_sequence_counts);

    std::cout << "Running alignment, output should be appearing in " << outfile.c_str() << std::endl;
    std::vector< unsigned > counter_counts;
    std::vector< std::string > counter_tags;
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
      // Look for the constant region (primer binding site)
      ////////////////////////////////////////////////////////////////
      Finder<String<char> > finder_constant_sequence(seq1); // this is what to search.

      //Set options for gap, mismatch,deletion
      String<char> ndl=cseq; // this is the needle
      Pattern<String<char>, DPSearch<SimpleScore> > pattern_constant_sequence(ndl,SimpleScore(0, -2, -1));

      // Find best match in case there are several.
      if(find(finder_constant_sequence, pattern_constant_sequence, -2)) {

	int pos1=position(finder_constant_sequence);
	int score=getScore(pattern_constant_sequence);
	while(find(finder_constant_sequence, pattern_constant_sequence, -2)) {
	  if(getScore(pattern_constant_sequence) > score) {
	    score=getScore(pattern_constant_sequence);
	    pos1=position(finder_constant_sequence);
	  }
	}

	record_counter( "found primer binding site", counter_idx, counter_counts, counter_tags );

	////////////////////////////////////////////////////////////////////////////////////////
	// Look for the sequence ID (i.e., the identifier sequence at the 3' end of the RNA)
	// in a region of seqid nucleotides before the constant (primer-binding) site.
	// seqid is the (minimum) length of the barcode...
	////////////////////////////////////////////////////////////////////////////////////////
	int min_pos=pos1-length(cseq)-seqid_length+1;
	if(min_pos < 0)	 min_pos=0;
	String<char> sequence_id_region_in_sequence1=infixWithLength(seq1,min_pos,seqid_length);
	// We append the primer binding site to make sure that the search will be over actual barcode regions (adjoining the constant sequence) from the RNA library.
	append(sequence_id_region_in_sequence1,cseq);
	Pattern<CharString> pattern_sequence_id_in_read1(sequence_id_region_in_sequence1); // this is now the 'needle' -- look for this sequence in the haystack of potential sequence IDs

	if(find(finder_sequence_id, pattern_sequence_id_in_read1)) { // wait, shouldn't we try *all* possibilities?
	  // std::cout << beginPosition(finder_sequence_id).i1 << std::endl;
	  // seq3 contains the RNA library sequences
	  int sid_idx = beginPosition(finder_sequence_id).i1;
	  assignSeq(seq3, multiSeqFile3[sid_idx], format3); // read sequence of the RNA
	  assignSeqId(seq3id,multiSeqFile3[sid_idx], format3); // read the ID of the RNA

	  record_counter( "found RNA sequence", counter_idx, counter_counts, counter_tags );

	  ////////////////////////////////////////////////////////////////////////////////////////
	  // Look for the second read to determine where the reverse transcription stop is.
	  ////////////////////////////////////////////////////////////////////////////////////////
	  RNA2DNA( seq3 );
	  Finder<String<char> > finder_experimental_id(seq3); // this could be created above, right? But note -- we should pad on the experimental ID and  AdapterSequence!!! RHIJU ADD THIS!
	  Pattern<String<char>, MyersUkkonen> pattern_sequence2(seq2);

	  // following is imperfect -- should add on Adapter Sequence, and then do a more stringent search.
	  // also, would be good to use Quality information.
	  setScoreLimit(pattern_sequence2, -10);//Edit Distance = -1. -2 would be worse
	  int mpos=-1;
	  int mscr=-100;

	  // Here, looking for best score -- but assuming that we've nailed the right RNA sequence (which may not be the case).
	  while (find(finder_experimental_id, pattern_sequence2)) {

	    int cscr=getScore(pattern_sequence2);
	    if(cscr > mscr) {
	      mscr=cscr;
	      mpos=position(finder_experimental_id);
	    }
	  }

	  if(mpos >=0) {

	    record_counter( "found match in sequence", counter_idx, counter_counts, counter_tags );

	    mpos=mpos-length(seq2); // what?
	    perfect++;

	    ///////////////////////////////////////////////////////////////////////////////////////////////////
	    // This should go above!!! Needed for determining adapter sequence.
	    // Match experimental ID
	    //  note -- this could be replaced with 'find best match', allowing mismatch. Would not cost much.
	    ///////////////////////////////////////////////////////////////////////////////////////////////////
	    int eid_extent=max_eidlen;
	    if(length(seq1) < pos1+1+max_eidlen) {
	      // maximum extent towards end of read1 to get experimental ID. Wait, is this right?
	      eid_extent=length(seq1)-(pos1+1);
	    }
	    String<char> mid=infixWithLength(seq1,(pos1+1),eid_extent);

	    std::string edescr=toCString(mid);
	    bool found_eid( false );
	    String<char> eid_string;
	    for(int j=0; j<eidlen.size(); j++) {
	      String<char> sub=infixWithLength(mid,0,eidlen[j]);
	      std::string str=toCString(sub);
	      hashmap::iterator it = idmap.find(str);
	      if(it != idmap.end()) {
		edescr=it->second;
		eid_string = sub;
		found_eid = true;
	      }
	    }

	    if(debug==1) {
	      fprintf(oFile,"%s,%s,%s,%s,%d,%d,%s,%s\n",toCString(id1),toCString(id2),edescr.c_str(),toCString(seq3id),(mpos+1),mscr,toCString(seq2),toCString(seq3));
	    }
	    else {
	      // need to replace this with a histogram... or save a vector of information (perhaps with weights?) that we histogram below.
	      fprintf(oFile,"%s,%s,%d,%d\n",edescr.c_str(),toCString(seq3id),(mpos+1),mscr);
	      if ( found_eid ) {

		// this is kind of silly. I should have the index of the expt id above, but its computed in a funny way.
		int eid_idx;
		for (eid_idx=0; eid_idx <seqCount4; eid_idx++ ){
		  assignSeq(seq4, multiSeqFile4[eid_idx], format4);    // read sequence
		  if ( seq4 == eid_string ) break;
		}

	       	// std::cout << "about to save: " << eid_idx << " " << sid_idx << " " << mpos+1 << std::endl;
		// std::cout << seq3 << std::endl;
		// std::cout << seq2 << std::endl;
		// std::cout << std::endl;
		if ( mpos < -1 ) mpos = -1;
		all_count[ eid_idx ][ sid_idx ][ mpos+1 ]++;
	      }
	    }
	  }

	} else {
	  unmatchedlib++;
	  //fprintf(uFile,"%s,%s,%d,%d,%s,%s\n",mid,uid,seq1id);
	}
	clear(finder_sequence_id);

      } else {
	unmatchedtail++;
      }
    }
    std::cout << "Aligning " << seqCount1 << " sequences took " << SEQAN_PROTIMEDIFF(loadTime);
    std::cout << " seconds." << std::endl << std::endl;
    std::cout << "Total Sequence Pairs: " << length(multiSeqFile1) << std::endl;
    std::cout << "Perfect ID matches: " << perfect << std::endl;
    std::cout << "Unmatched Tail: " << unmatchedtail << std::endl;
    std::cout << "Unmatched Lib: " << unmatchedlib << std::endl;

    std::cout << std::endl;
    std::cout << "Purification table" << std::endl;
    for ( unsigned i = 0; i < counter_counts.size(); i++ ){
      std::cout << counter_counts[i] << " " << counter_tags[i] << std::endl;
    }
    std::cout << std::endl;

    //////////////////////////////////////////////////////
    //  output matrices with stored counts.
    //////////////////////////////////////////////////////
    for ( unsigned i = 0; i < seqCount4; i++ ){
      char stats_outFileName[ 50 ];
      sprintf( stats_outFileName, "stats_ID%d.txt", i+1 ); // index by 1.
      std::cout << "Outputting counts to: " << stats_outFileName << std::endl;
      FILE * stats_oFile;
      stats_oFile = fopen( stats_outFileName,"w");
      for ( unsigned j = 0; j < seqCount3; j++ ){
    	for ( unsigned k = 0; k < max_rna_len; k++ ){
    	  fprintf( stats_oFile, " %d", all_count[i][j][k] );
    	}
    	fprintf( stats_oFile, "\n");
      }
      fclose( stats_oFile );
    }

    return 0;
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
  std::cout << "counter_idx: " << counter_idx << std::endl;
}
