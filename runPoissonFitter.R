library( "ade4", warn.conflicts = FALSE ) # needed by something.  ape?
library( "ape" ) # for "chronos", "as.DNAbin", "dist.dna", "read.dna", "write.dna"
library( "seqinr", warn.conflicts = FALSE ) # for "as.alignment", "consensus"

## Compute Hamming distances, prepare inputs to PFitter.R, call PFitter.R.
runPoissonFitter <- function ( fasta.file, output.dir = NULL, include.gaps.in.Hamming = FALSE ) {

    if( length( grep( "^(.*?)\\/[^\\/]+$", fasta.file ) ) == 0 ) {
        fasta.file.path <- ".";
    } else {
        fasta.file.path <-
            gsub( "^(.*?)\\/[^\\/]+$", "\\1", fasta.file );
    }
    fasta.file.short <-
        gsub( "^.*?\\/?([^\\/]+?)$", "\\1", fasta.file, perl = TRUE );
    fasta.file.short.nosuffix <-
        gsub( "^(.*?)\\.[^\\.]+$", "\\1", fasta.file.short, perl = TRUE );

  if( is.null( output.dir ) ) {
      output.dir <- fasta.file.path;
  } else {
      output.dir <- output.dir;
  }
  ## Remove "/" from end of output.dir
  output.dir <-
      gsub( "^(.*?)\\/+$", "\\1", output.dir );

    output.dir <- paste( output.dir, "/", fasta.file.short.nosuffix, "_PoissonFitterDir", sep = "" );
    
    unlink( output.dir, recursive = TRUE );
    dir.create( output.dir, showWarnings = TRUE );
    
    in.fasta <- read.dna( fasta.file, format = "fasta" );

    # Add the consensus.
    .consensus.mat <- matrix( seqinr::consensus( as.character( in.fasta ) ), nrow = 1 );
    consensus <- as.DNAbin( .consensus.mat );
    rownames( consensus ) <- paste( "Consensus" );

    fasta.with.consensus <- rbind( consensus, in.fasta );

    # Remove any columns with a consensus that is a gap, which means
    # that over half of seqs have gaps.  This needs to be removed
    # because it becomes not sensible to consider poisson rates of
    # insertions.  We do however consider rates of deletions, treating
    # them as point mutations (by including the indel counts in the
    # Hamming distance calculation).
    fasta.with.consensus <- fasta.with.consensus[ , .consensus.mat[ 1, ] != "-" ];
    
    # The pairwise.deletion = TRUE argument is necessary so that columns with any gaps are not removed.
    # The optional second call adds in the count of sites with gap differences
    # (gap in one sequence but not the other), which are not included
    # in the first call's "raw" count. Adding them back in, we are
    # effectively treating those as differences.
    fasta.with.consensus.dist <- dist.dna( fasta.with.consensus, model = "N", pairwise.deletion = TRUE );
    fasta.with.consensus.dist[ is.nan( fasta.with.consensus.dist ) ] <- 0;
    if( include.gaps.in.Hamming ) {
        fasta.with.consensus.dist <- fasta.with.consensus.dist + dist.dna( fasta.with.consensus, model = "indel", pairwise.deletion = TRUE );
    }
    
    if( any( is.null( fasta.with.consensus.dist ) ) || any( is.na( fasta.with.consensus.dist ) ) || any( !is.finite( fasta.with.consensus.dist ) ) ) {
      ## TODO: REMOVE
      warning( "UH OH got illegal distance value" );
      print( "UH OH got illegal distance value" );
      print( fasta.with.consensus.dist );
    }

    pairwise.distances.as.matrix <- as.matrix( fasta.with.consensus.dist );

    pairwise.distances.as.matrix.flat <- matrix( "", nrow = ( ( nrow( pairwise.distances.as.matrix ) * ( ncol( pairwise.distances.as.matrix ) - 1 ) ) / 2 ), ncol = 3 );
    line.i <- 1;
    for( row.i in 1:( nrow( pairwise.distances.as.matrix ) - 1 ) ) {
        for( col.i in ( row.i + 1 ):ncol( pairwise.distances.as.matrix ) ) {
            if( row.i == 1 ) { # consensus, no _1 (multiplicity of the observed sequence)
                pairwise.distances.as.matrix.flat[ line.i, ] <-
                    c( rownames( pairwise.distances.as.matrix )[ row.i ], paste( colnames( pairwise.distances.as.matrix )[ col.i ], "_1", sep = "" ), pairwise.distances.as.matrix[ row.i, col.i ] );
            } else {
                pairwise.distances.as.matrix.flat[ line.i, ] <-
                    c( paste( rownames( pairwise.distances.as.matrix )[ row.i ], "_1", sep = "" ), paste( colnames( pairwise.distances.as.matrix )[ col.i ], "_1", sep = "" ), pairwise.distances.as.matrix[ row.i, col.i ] );
            }
            line.i <- line.i + 1;
        }
    }
    
    pairwise.distances.as.matrix.file <- paste( output.dir, "/", fasta.file.short.nosuffix, "_pairwiseHammingDistances.txt", sep = "" );
    write.table( pairwise.distances.as.matrix.flat, file = pairwise.distances.as.matrix.file, sep = "\t", col.names = FALSE, row.names = FALSE, quote = FALSE );

    R.cmd <- paste( "R CMD BATCH '--vanilla --args", pairwise.distances.as.matrix.file, "2.16e-05", ncol( fasta.with.consensus ), "' PFitter.R" );
    return( system( R.cmd ) );
} # runPoissonFitter ( fasta.file, output.dir )

## Here is where the action is.
fasta.file <- Sys.getenv( "runPoissonFitter_inputFilename" ); # alignment
output.dir <- Sys.getenv( "runPoissonFitter_outputDir" ); # NOTE: will create a subdir for the output, named after the fasta file, with "PoissonFitterDir".
## TODO: REMOVE
# warning( paste( "alignment input file:", fasta.file ) );
# warning( paste( "output dir:", output.dir ) );

if( file.exists( fasta.file ) ) {
    print( runPoissonFitter( fasta.file, output.dir ) );
} else {
    stop( paste( "File does not exist:", fasta.file ) );
}