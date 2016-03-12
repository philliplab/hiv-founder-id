# hello.

summarizeCovariatesOnePerParticipant <- function ( results ) {

                   results.covars.colnames <- c( "num.seqs", "num.diversity.seqs", "diversity", "inf.sites", "priv.sites", "inf.to.priv.ratio", "mean.entropy", "sd.entropy", "inf.sites.clusters", "InSites.founders", "StarPhy.founders", "multifounder.Synonymous.PFitter.is.poisson" );

                   ## Setting up.  Add a column for the coefficients that are used by the daysFromLambda function.
                   mutation.rate.coefs <-
                       sapply( 1:length( days.est.colnames.nb ), function( days.est.col.i ) {
                             apply( results, 1, function( .row ) {
                                 if( is.na( .row[ days.est.colnames.nb[ days.est.col.i ] ] ) ) {
                                     return( NA );
                                 }
                                 return( daysFromLambda.coefficient.of.inverse.epsilon( .row[ lambda.est.colnames[ days.est.col.i ] ], .row[ days.est.colnames.nb[ days.est.col.i ] ] ) );
                             } );
                         } );
                   colnames( mutation.rate.coefs ) <-
                       gsub( "(?:days|time)\\.est", "mut.rate.coef", days.est.colnames );

                   mutation.rate.coefs.totalbases <- days.est.nseq*days.est.nb;
                   colnames( mutation.rate.coefs.totalbases ) <-
                       gsub( "(?:days|time)\\.est", "mut.rate.coef.totalbases", days.est.colnames );

                   covars <-
                       cbind(
                           results[ , results.covars.colnames, drop = FALSE ],
                           mutation.rate.coefs,
                           mutation.rate.coefs.totalbases
                       );
    
    # Five cases: diversity, entropy, single, mut.rate.coef, and the rest ("max").
    # Case 1: for diversity, we create combined measures weighted using num.diversity.seqs.
    diversity.colnames <-
        grep( "diversity", colnames( covars ), value = TRUE, perl = TRUE )
    diversity.one.per.ppt <- 
    sapply( diversity.colnames, function ( .col.name ) {
        .column <- covars[ , .col.name ];
        .rv <- 
        sapply( unique( rownames( covars ) ), function( .ppt ) {
            .ppt.cells <- .column[ rownames( covars ) == .ppt ];
            if( all( is.na( .ppt.cells ) ) ) {
              return( NA );
            }
            .ppt.weights <- covars[ rownames( covars ) == .ppt, "num.diversity.seqs" ];
            .ppt.weights <- .ppt.weights / sum( .ppt.weights, na.rm = TRUE );
            sum( .ppt.cells * .ppt.weights, na.rm = TRUE );
        } );
        names( .rv ) <- unique( rownames( covars ) );
        return( .rv );
    } );
    
    # Case 2: for entropy, we create combined measures weighted using num.seqs
    entropy.colnames <-
        c( "num.seqs", grep( "entropy", colnames( covars ), value = TRUE, perl = TRUE ) );
    entropy.one.per.ppt <- 
    sapply( entropy.colnames, function ( .col.name ) {
        .column <- covars[ , .col.name ];
        .rv <- 
        sapply( unique( rownames( covars ) ), function( .ppt ) {
            .ppt.cells <- .column[ rownames( covars ) == .ppt ];
            if( all( is.na( .ppt.cells ) ) ) {
              return( NA );
            }
            .ppt.weights <- covars[ rownames( covars ) == .ppt, "num.seqs" ];
            .ppt.weights <- .ppt.weights / sum( .ppt.weights, na.rm = TRUE );
            sum( .ppt.cells * .ppt.weights, na.rm = TRUE );
        } );
        names( .rv ) <- unique( rownames( covars ) );
        return( .rv );
    } );
    
    # Case 3: for isSingleFounder columns, we create combined measures using the AND of the individual values (so any indication that there are multiple founders results in a call of multiple founders).
    single.colnames <-
        grep( "\\.is\\.|fits", colnames( covars ), perl = TRUE, value = TRUE );
    single.one.per.ppt <- 
    sapply( single.colnames, function ( .col.name ) {
        .column <- covars[ , .col.name ];
        .rv <- 
        sapply( unique( rownames( covars ) ), function( .ppt ) {
            .ppt.cells <- .column[ rownames( covars ) == .ppt ];
            if( all( is.na( .ppt.cells ) ) ) {
              return( NA );
            }
            # TODO: REMOVE. FOR DEBUGGING.
            if( FALSE && !all( as.logical( .ppt.cells ), na.rm = TRUE ) ) {
                print( .ppt );
                print( .ppt.cells );
            }
            as.numeric( all( as.logical( .ppt.cells ), na.rm = TRUE ) );
        } );
        names( .rv ) <- unique( rownames( covars ) );
        return( .rv );
    } );
    
    # Case 4: for mut.rate.coef columns, we create combined measures weighted using mut.rate.coef.totalbases.
    mut.rate.coef.colnames <-
        grep( "mut\\.rate\\.coef", colnames( covars ), perl = TRUE, value = TRUE );
    mut.rate.coef.one.per.ppt <- 
    sapply( mut.rate.coef.colnames, function ( .col.name ) {
        .column <- covars[ , .col.name ];
        .rv <- 
        sapply( unique( rownames( covars ) ), function( .ppt ) {
            .ppt.cells <- .column[ rownames( covars ) == .ppt ];
            if( all( is.na( .ppt.cells ) ) ) {
              return( NA );
            }
            .weights.col <- gsub( "coef$", "coef.totalbases", .col.name );
            .ppt.weights <- covars[ rownames( covars ) == .ppt, .weights.col ];
            .ppt.weights <- .ppt.weights / sum( .ppt.weights, na.rm = TRUE );
            sum( .ppt.cells * .ppt.weights, na.rm = TRUE );
        } );
        names( .rv ) <- unique( rownames( covars ) );
        return( .rv );
    } );
    
    ## Case 5: the rest of them.  For these we select the maximum.
    max.colnames <-
        setdiff( colnames( covars ), c( diversity.colnames, entropy.colnames, single.colnames, mut.rate.coef.colnames ) );
    max.one.per.ppt <- 
    sapply( max.colnames, function ( .col.name ) {
        .column <- covars[ , .col.name ];
        .rv <- 
        sapply( unique( rownames( covars ) ), function( .ppt ) {
            .ppt.cells <- .column[ rownames( covars ) == .ppt ];
            if( all( is.na( .ppt.cells ) ) ) {
              return( NA );
            }
            max( .ppt.cells, na.rm = TRUE );
        } );
        names( .rv ) <- unique( rownames( covars ) );
        return( .rv );
    } );
    
    return( cbind( diversity.one.per.ppt, entropy.one.per.ppt, single.one.per.ppt, mut.rate.coef.one.per.ppt, max.one.per.ppt )[ , colnames( covars ) ] );
} # summarizeCovariatesOnePerParticipant (..)
        