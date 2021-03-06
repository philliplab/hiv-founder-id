
    missing.column.safe.rbind <- function ( matA, matB, matA.name, matB.name ) {
      stopifnot( !is.na( nrow( matA ) ) );
      stopifnot( !is.na( nrow( matB ) ) );
        all.colnames <- union( colnames( matA ), colnames( matB ) );
        .rv <- matrix( NA, nrow = nrow( matA ) + nrow( matB ), ncol = length( all.colnames ) );
        colnames( .rv ) <- all.colnames;
        rownames( .rv ) <-
            c( paste( rownames( matA ), matA.name, sep = "." ),
              paste( rownames( matB ), matB.name, sep = "." ) );
        .rv[ 1:nrow( matA ), colnames( matA ) ] <-
            as.matrix( matA );
        .rv[ nrow( matA ) + 1:nrow( matB ), colnames( matB ) ] <-
            as.matrix( matB );
        
        return( .rv );
    } # missing.column.safe.rbind (..)


getResultsByRegionAndTime <- function ( gold.standard.varname, get.results.for.region.and.time.fn, evaluate.results.per.person.fn, partition.size = NA, regions = c( "nflg", "v3" ), times = c( "1w", "1m", "6m", "1m6m" ) ) {
        if( !is.na( partition.size ) ) {
            regions <- "v3"; # Only v3 has partition results at this time.
        }
        results.by.region.and.time <-
            lapply( regions, function( the.region ) {
                ## TODO: REMOVE
                cat( the.region, fill = T );
           results.by.time <-
               lapply( times, function( the.time ) {
                   ## TODO: REMOVE
                   cat( the.time, fill = T );
                   get.results.for.region.and.time.fn( the.region, the.time, partition.size );               
               } );
           names( results.by.time ) <- times;

           if( !all( c( "1w", "1m", "6m" ) %in% times ) ) {
               return( results.by.time );
           }
           .vars <- setdiff( names( results.by.time[[1]] ), "evaluated.results" );
                ### ERE I AM.  The big discrepency when estimating parameters from multiple times may be effectively due to the greater standard deviation of date estimates from the 6m timepoint than from the 1m timepoint: the magnitude of the residuals depends on the date.  This suggests that a better model might allow that heteroskedasticity -- ie by using a negative binomial model (robust poisson regression like I do for the Picker TB project), or by using a heteroskedasticity-tolerant linear model. -- UPDATE. alas. that does not seem to help; the basic problem is that the study design is not ideal. We should have made the variation in the true days-since-infection equal the variation we will see in the trial (for this we can use as a surrogate the sampling date distribution from eg mtn003 or hvtn505) by using samples collected at more varying dates (rather than just at the 1m timepoint). Ironically, this makes eg Phambili a better choice for now, although that is impacted by uncertainty in the true dates of infection of those persons). But perhaps Morgane could sequence more samples?  Maybe Carolyn?  I could add it to the grant upon resubmission, if I get that lucky.
## After doing some playing with the mtn003 timing windows (see createArtificialBoundsOnInfectionDate.R) (see below), it seems that there's an argument to be made that for AMP, the SDs of our one month stuff is ok.  Still means we use a trivial model though. Or does it?
# sd( mtn003.timing.windows.of.infecteds)
# [1] 83.62038
# > sd( mtn003.timing.windows.of.infecteds[ mtn003.timing.windows.of.infecteds < 101 ])
# [1] 17.59504
# > sd( mtn003.timing.windows.of.infecteds[ mtn003.timing.windows.of.infecteds < 61 ])
# [1] 9.790947
# > sd( mtn003.timing.windows.of.infecteds[ mtn003.timing.windows.of.infecteds < 41 ])
# [1] 4.701886
## #############
                ########
                ####### ok so also if we are using intercepts for evaluateTimings, then we should also allow for a shift for the 6m.not.1m.
           results.1m.6m <- lapply( .vars, function ( .varname ) {
               #print( .varname );
               if( .varname == "bounds" ) {
                   if( length( intersect( names( results.by.time[[ "1m" ]][[ .varname ]] ), names( results.by.time[[ "6m" ]][[ .varname ]] ) ) ) > 0 ) {
                     .rv <- 
                     lapply( intersect( names( results.by.time[[ "1m" ]][[ .varname ]] ), names( results.by.time[[ "6m" ]][[ .varname ]] ) ), function( .bounds.type ) {
                         #print( .bounds.type );
                         missing.column.safe.rbind(
                             results.by.time[[ "1m" ]][[ .varname ]][[ .bounds.type ]],
                             results.by.time[[ "6m" ]][[ .varname ]][[ .bounds.type ]],
                             "1m",
                             "6m"
                         )
                     } );
                     names( .rv ) <-
                         names( results.by.time[[ "1m" ]][[ .varname ]] );
                   } else {
                       .rv <- NULL;
                   }
                   
                   ## ## Add a new bounds.type called "uniform_1m5weeks_6m30weeks"
                   ## new.bounds.table <-
                   ##     missing.column.safe.rbind(
                   ##         results.by.time[[ "1m" ]][[ .varname ]][[ "uniform_5weeks" ]],
                   ##         results.by.time[[ "6m" ]][[ .varname ]][[ "uniform_30weeks" ]],
                   ##         "1m",
                   ##         "6m"
                   ##     );
                   ## .rv <- c( list( "uniform_1m5weeks_6m30weeks" = new.bounds.table ), .rv );
                   ## 
                   ## ## Add a new bounds.type called "exponentialwidth_uniform_1m5weeks_6m30weeks"
                   ## another.new.bounds.table <-
                   ##     missing.column.safe.rbind(
                   ##         results.by.time[[ "1m" ]][[ .varname ]][[ "exponentialwidth_uniform_5weeks" ]],
                   ##         results.by.time[[ "6m" ]][[ .varname ]][[ "exponentialwidth_uniform_30weeks" ]],
                   ##         "1m",
                   ##         "6m"
                   ##     );
                   ## .rv <- c( list( "exponentialwidth_uniform_1m5weeks_6m30weeks" = another.new.bounds.table ), .rv );
                   ## 
                   ## ## Add a new bounds.type called "gammawidth_uniform_1m5weeks_6m30weeks"
                   ## yetanother.new.bounds.table <-
                   ##     missing.column.safe.rbind(
                   ##         results.by.time[[ "1m" ]][[ .varname ]][[ "gammawidth_uniform_5weeks" ]],
                   ##         results.by.time[[ "6m" ]][[ .varname ]][[ "gammawidth_uniform_30weeks" ]],
                   ##         "1m",
                   ##         "6m"
                   ##     );
                   ## .rv <- c( list( "gammawidth_uniform_1m5weeks_6m30weeks" = yetanother.new.bounds.table ), .rv );

                   ## Add a new bounds.type called "sampledwidth_uniform_1monemonth_6msixmonths"
                   # stillanother.new.bounds.table <-
                   #     missing.column.safe.rbind(
                   #         results.by.time[[ "1m" ]][[ .varname ]][[ "sampledwidth_uniform_onemonth" ]],
                   #         results.by.time[[ "6m" ]][[ .varname ]][[ "sampledwidth_uniform_sixmonths" ]],
                   #         "1m",
                   #         "6m"
                   #     );

                   ## Add a new bounds.type called "sampledwidth_uniform_1mmtn003_6mhvtn502"
                   great.new.bounds.table <-
                       missing.column.safe.rbind(
                           results.by.time[[ "1w" ]][[ .varname ]][[ "sampledwidth_uniform_mtn003" ]],
                           results.by.time[[ "1m" ]][[ .varname ]][[ "sampledwidth_uniform_mtn003" ]],
                           results.by.time[[ "6m" ]][[ .varname ]][[ "sampledwidth_uniform_hvtn502" ]],
                           "1w",
                           "1m",
                           "6m"
                       );
                   .rv <- c( list( "sampledwidth_uniform_1mmtn003_6mhvtn502" = great.new.bounds.table ), .rv );
                   return( .rv );
               } else if( .varname == gold.standard.varname ) {
                   # one dimensional
                   .rv <- c( 
                             results.by.time[[ "1w" ]][[ .varname ]],
                             results.by.time[[ "1m" ]][[ .varname ]],
                             results.by.time[[ "6m" ]][[ .varname ]]
                       );
                     names( .rv ) <-
                         c( paste( names( results.by.time[[ "1w" ]][[ .varname ]] ), "1w", sep = "." ),
                           paste( names( results.by.time[[ "1m" ]][[ .varname ]] ), "1m", sep = "." ),
                           paste( names( results.by.time[[ "6m" ]][[ .varname ]] ), "6m", sep = "." ) );
                   return( .rv );
               } else {
                     .rv <- 
                       missing.column.safe.rbind(
                           results.by.time[[ "1w" ]][[ .varname ]],
                           results.by.time[[ "1m" ]][[ .varname ]],
                           results.by.time[[ "6m" ]][[ .varname ]],
                           "1w",
                           "1m",
                           "6m"
                       );
                     if( .varname == "results.covars.per.person.with.extra.cols" ) {
                       .x <-
                         c(
                           rep( 0, nrow( results.by.time[[ "1w" ]][[ .varname ]] ) ),
                           rep( 0, nrow( results.by.time[[ "1m" ]][[ .varname ]] ) ),
                           rep( 1, nrow( results.by.time[[ "6m" ]][[ .varname ]] ) )
                         );
                       .rv <- cbind( "6m.not.1m" = .x, .rv );
                     }
                     return( .rv );
                 }
           } );
           names( results.1m.6m ) <-
             .vars;

           time.dependent.estimate.colname.roots <- c( "COB", "Infer" );
           for( .colname.root in time.dependent.estimate.colname.roots ) {
             if( length( grep( .colname.root, colnames( results.by.time[[ "1m" ]][[ "results.per.person" ]] ) ) ) > 0 ) {
               
               ## ## Add a new center-of-bounds result called "COB.uniform.1m5weeks.6m30weeks.time.est"
               ## new.estimates.table <-
               ##   rbind(
               ##     results.by.time[[ "1m" ]][[ "results.per.person" ]][ , paste( .colname.root, "uniform.5weeks.time.est", sep = "." ), drop = FALSE ],
               ##     results.by.time[[ "6m" ]][[ "results.per.person" ]][ , paste( .colname.root, "uniform.30weeks.time.est", sep = "." ), drop = FALSE ]
               ##   );
               ## rownames( new.estimates.table ) <-
               ##   c(
               ##     paste( rownames( results.by.time[[ "1m" ]][[ "results.per.person" ]] ), "1m", sep = "." ),
               ##     paste( rownames( results.by.time[[ "6m" ]][[ "results.per.person" ]] ), "6m", sep = "." )
               ##   );
               ## colnames( new.estimates.table ) <- paste( .colname.root, "uniform.1m5weeks.6m30weeks.time.est", sep = "." );
               ## results.1m.6m[[ "results.per.person" ]] <-
               ##     cbind( new.estimates.table, results.1m.6m[[ "results.per.person" ]] );
               ## 
               ## ## Add a new center-of-bounds result called "COB.exponentialwidth.uniform.1m5weeks.6m30weeks.time.est"
               ## if( ( paste( .colname.root, "exponentialwidth.uniform.5weeks.time.est", sep = "." ) %in% colnames( results.by.time[[ "1m" ]][[ "results.per.person" ]] ) ) && ( paste( .colname.root, "exponentialwidth.uniform.30weeks.time.est", sep = "." ) %in% colnames( results.by.time[[ "6m" ]][[ "results.per.person" ]] ) ) ) {
               ##   another.new.estimates.table <-
               ##     rbind(
               ##       results.by.time[[ "1m" ]][[ "results.per.person" ]][ , paste( .colname.root, "exponentialwidth.uniform.5weeks.time.est", sep = "." ), drop = FALSE ],
               ##       results.by.time[[ "6m" ]][[ "results.per.person" ]][ , paste( .colname.root, "exponentialwidth.uniform.30weeks.time.est", sep = "." ), drop = FALSE ]
               ##     );
               ##   rownames( another.new.estimates.table ) <-
               ##     c(
               ##       paste( rownames( results.by.time[[ "1m" ]][[ "results.per.person" ]] ), "1m", sep = "." ),
               ##       paste( rownames( results.by.time[[ "6m" ]][[ "results.per.person" ]] ), "6m", sep = "." )
               ##     );
               ##   colnames( another.new.estimates.table ) <- paste( .colname.root, "exponentialwidth.uniform.1m5weeks.6m30weeks.time.est", sep = "." );
               ##   results.1m.6m[[ "results.per.person" ]] <-
               ##     cbind( another.new.estimates.table, results.1m.6m[[ "results.per.person" ]] );
               ## }
               ## 
               ## ## Add a new center-of-bounds result called "COB.gammawidth.uniform.1m5weeks.6m30weeks.time.est"
               ## if( ( paste( .colname.root, "gammawidth.uniform.5weeks.time.est", sep = "." ) %in% colnames( results.by.time[[ "1m" ]][[ "results.per.person" ]] ) ) && ( paste( .colname.root, "gammawidth.uniform.30weeks.time.est", sep = "." ) %in% colnames( results.by.time[[ "6m" ]][[ "results.per.person" ]] ) ) ) {
               ##   yetanother.new.estimates.table <-
               ##     rbind(
               ##       results.by.time[[ "1m" ]][[ "results.per.person" ]][ , paste( .colname.root, "gammawidth.uniform.5weeks.time.est", sep = "." ), drop = FALSE ],
               ##       results.by.time[[ "6m" ]][[ "results.per.person" ]][ , paste( .colname.root, "gammawidth.uniform.30weeks.time.est", sep = "." ), drop = FALSE ]
               ##     );
               ##   rownames( yetanother.new.estimates.table ) <-
               ##     c(
               ##       paste( rownames( results.by.time[[ "1m" ]][[ "results.per.person" ]] ), "1m", sep = "." ),
               ##       paste( rownames( results.by.time[[ "6m" ]][[ "results.per.person" ]] ), "6m", sep = "." )
               ##     );
               ##   colnames( yetanother.new.estimates.table ) <- paste( .colname.root, "gammawidth.uniform.1m5weeks.6m30weeks.time.est", sep = "." );
               ##   results.1m.6m[[ "results.per.person" ]] <-
               ##     cbind( yetanother.new.estimates.table, results.1m.6m[[ "results.per.person" ]] );
               ## }
             
               ## Add a new center-of-bounds result called "COB.sampledwidth.uniform.1mmtn003.6mhvtn502.time.est"
               if( ( paste( .colname.root, "sampledwidth.uniform.mtn003.time.est", sep = "." ) %in% colnames( results.by.time[[ "1m" ]][[ "results.per.person" ]] ) ) && ( paste( .colname.root, "sampledwidth.uniform.hvtn502.time.est", sep = "." ) %in% colnames( results.by.time[[ "6m" ]][[ "results.per.person" ]] ) ) ) {
                 stillanother.new.estimates.table <-
                   rbind(
                     results.by.time[[ "1w" ]][[ "results.per.person" ]][ , paste( .colname.root, "sampledwidth.uniform.mtn003.time.est", sep = "." ), drop = FALSE ],
                     results.by.time[[ "1m" ]][[ "results.per.person" ]][ , paste( .colname.root, "sampledwidth.uniform.mtn003.time.est", sep = "." ), drop = FALSE ],
                     results.by.time[[ "6m" ]][[ "results.per.person" ]][ , paste( .colname.root, "sampledwidth.uniform.hvtn502.time.est", sep = "." ), drop = FALSE ]
                   );
                 rownames( stillanother.new.estimates.table ) <-
                   c(
                     paste( rownames( results.by.time[[ "1w" ]][[ "results.per.person" ]] ), "1w", sep = "." ),
                     paste( rownames( results.by.time[[ "1m" ]][[ "results.per.person" ]] ), "1m", sep = "." ),
                     paste( rownames( results.by.time[[ "6m" ]][[ "results.per.person" ]] ), "6m", sep = "." )
                   );
                 colnames( stillanother.new.estimates.table ) <- paste( .colname.root, "sampledwidth.uniform.1mmtn003.6mhvtn502.time.est", sep = "." );
                 results.1m.6m[[ "results.per.person" ]] <-
                   cbind( stillanother.new.estimates.table, results.1m.6m[[ "results.per.person" ]] );
               }
             }
           } # End foreach .colname.root
           results.1m.6m <-
               c( results.1m.6m,
###                 list( evaluated.results = evaluate.results.per.person.fn( results.per.person = results.1m.6m[[ "results.per.person" ]], days.since.infection = results.1m.6m[[ gold.standard.varname ]], results.covars.per.person.with.extra.cols = results.1m.6m[[ "results.covars.per.person.with.extra.cols" ]], the.time = "1m.6m", the.artificial.bounds = results.1m.6m[[ "bounds" ]] ) ) );
                 list( evaluated.results = evaluate.results.per.person.fn( results.1m.6m[[ "results.per.person" ]], results.1m.6m[[ gold.standard.varname ]], results.covars.per.person.with.extra.cols = results.1m.6m[[ "results.covars.per.person.with.extra.cols" ]], the.time = "1m.6m", the.artificial.bounds = results.1m.6m[[ "bounds" ]] ) ) );
           return( c( list( "1m.6m" = results.1m.6m ), results.by.time ) );
       } ); # End foreach the.region
        names( results.by.region.and.time ) <- regions;

      if( !all( c( "nflg", "v3" ) %in% regions ) ) {
          return( results.by.region.and.time );
      }
      # We now evaluate pooled results for every pair of regions, except nflg&rv217_v3.
      results.across.regions.by.time <-
        lapply( 1:( length( regions ) - 1), function( from.region.i ) {
          from.region <- regions[ from.region.i ];
        .rv.from.region.i <- 
        lapply( ( from.region.i + 1 ):length( regions ), function( to.region.j ) {
            to.region <- regions[ to.region.j ];
            if( ( from.region == "nflg" ) && ( to.region == "rv217_v3" ) ) {
                return( NA );
            }
          .times <- names( results.by.region.and.time[[ from.region ]] );
          .rv.from.region.i.to.region.j <- 
          lapply( .times, function ( the.time ) {
            ## TODO: REMOVE
            print( paste( "Pooling regions", from.region, "and", to.region, "at time", the.time ) );
              .vars <-
                  setdiff( names( results.by.region.and.time[[ from.region ]][[ the.time ]] ), "evaluated.results" );
              .rv.for.time <- 
              lapply( .vars, function ( .varname ) {
               #print( .varname );
               if( .varname == "bounds" ) {
                   .rv <- 
                   lapply( names( results.by.region.and.time[[ from.region ]][[ the.time ]][[ .varname ]] ), function( .bounds.type ) {
                       missing.column.safe.rbind(
                           results.by.region.and.time[[ from.region ]][[ the.time ]][[ .varname ]][[ .bounds.type ]],
                           results.by.region.and.time[[ to.region ]][[ the.time ]][[ .varname ]][[ .bounds.type ]],
                           from.region,
                           to.region
                       )
                   } );
                   names( .rv ) <-
                       names( results.by.region.and.time[[ from.region ]][[ the.time ]][[ .varname ]] );
                   return( .rv );
               } else if( .varname == gold.standard.varname ) {
                   # one dimensional
                   .rv <- c( 
                             results.by.region.and.time[[ from.region ]][[ the.time ]][[ .varname ]],
                             results.by.region.and.time[[ to.region ]][[ the.time ]][[ .varname ]]
                       );
                     names( .rv ) <-
                         c( paste( names( results.by.region.and.time[[ from.region ]][[ the.time ]][[ .varname ]] ), from.region, sep = "." ),
                           paste( names( results.by.region.and.time[[ to.region ]][[ the.time ]][[ .varname ]] ), to.region, sep = "." ) );
                   return( .rv );
               } else {
                     .rv <-
                         missing.column.safe.rbind(
                             results.by.region.and.time[[ from.region ]][[ the.time ]][[ .varname ]],
                             results.by.region.and.time[[ to.region ]][[ the.time ]][[ .varname ]],
                           from.region,
                           to.region
                       );
                     return( .rv );
                 }
           } );
           names( .rv.for.time ) <- .vars;

            ## Add a covar to indicate the region (to.region vs from.region)
            .new.column <- c( rep( 0, nrow( results.by.region.and.time[[ from.region ]][[ the.time ]][[ "results.covars.per.person.with.extra.cols" ]] ) ), rep( 1, nrow( results.by.region.and.time[[ to.region ]][[ the.time ]][[ "results.covars.per.person.with.extra.cols" ]] ) ) );
            .rv.for.time[[ "results.covars.per.person.with.extra.cols" ]] <-
              cbind( .new.column, .rv.for.time[[ "results.covars.per.person.with.extra.cols" ]] );
            colnames( .rv.for.time[[ "results.covars.per.person.with.extra.cols" ]] )[ 1 ] <-
              paste( to.region, "not", from.region, sep = "_" );
            
           # Add the evaluated.results:
           .evaluated.results <-
               evaluate.results.per.person.fn( .rv.for.time[[ "results.per.person" ]], .rv.for.time[[ gold.standard.varname ]], .rv.for.time[[ "results.covars.per.person.with.extra.cols" ]], the.time = the.time, .rv.for.time[[ "bounds" ]] );
            #evaluate.results.per.person.fn( results.per.person=.rv.for.time[[ "results.per.person" ]], days.since.infection=.rv.for.time[[ gold.standard.varname ]], results.covars.per.person.with.extra.cols=.rv.for.time[[ "results.covars.per.person.with.extra.cols" ]], the.time = the.time, the.artificial.bounds = .rv.for.time[[ "bounds" ]] );
           .rv.for.time <- c( .rv.for.time, 
                             list( evaluated.results = .evaluated.results ) )
           return( .rv.for.time );
          } );
        names( .rv.from.region.i.to.region.j ) <- .times;
          return( .rv.from.region.i.to.region.j );
        } );
        names( .rv.from.region.i ) <- regions[ ( from.region.i + 1 ):length( regions ) ];
          return( .rv.from.region.i );
      } );
      names( results.across.regions.by.time ) <- regions[ 1:( length( regions ) - 1 ) ];
      return( c( results.by.region.and.time, list( results.across.regions.by.time = results.across.regions.by.time ) ) );
} # getResultsByRegionAndTime ( .. )

