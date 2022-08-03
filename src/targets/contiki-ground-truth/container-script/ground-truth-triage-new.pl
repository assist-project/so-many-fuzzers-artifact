#!/usr/bin/perl -s
##
use strict;
use warnings;
use File::Basename;
use Cwd 'abs_path';

print "\n -- Crash triage for Contiki-NG Ground Truth experiment (new) -- \n\n";

use File::Basename;
use Hash::Util qw(hash_value);
use Array::Utils qw(:all);

#Constants
## global setting the timeout for later executions
my $timeout = 3;

#ENV VARIABLES
my $FIXNAME_FILE  = $ENV{'FIXNAME_FILE'}  ? $ENV{'FIXNAME_FILE'}  : "$ENV{'HARNESS_PATH'}/info/security-fixes.txt";
my $LAB_PATH      = $ENV{'LAB_PATH'}      ? $ENV{'LAB_PATH'}      : "$ENV{'WORKDIR_PATH'}/validation";
## option variables
our ($validate,$check,$stack,$commit,$develop,$fix,$quiet,$output,$stamps);

### --------- get arguments
sub usage() {
  my $usage  = "usage: $0 MODE [options] -- folder\n";
  $usage    .= "\t\tModes: validate or check\n";
  $usage    .= "  -validate         validate a set of input files for a fix or at the develop head commit\n";
  $usage    .= "  -check            check a set of crashes/crashing stacks with different targets\n";
  $usage    .= "\t\t  -- Modes validate --\n";
  $usage    .= "usage: $0 -validate [options] -- folder\n";
  $usage    .= "  ---- Required parameters:\n";
  $usage    .= "  folder:           folder containing input files\n";
  $usage    .= "  \n";
  $usage    .= "  ---- Optional parameters:\n";
  $usage    .= " -stamps=<file>:    provide timestamps for crashing file reports\n";
  $usage    .= "  \n";
  $usage    .= "\t\t  -- Modes check --\n";
  $usage    .= "usage: $0 -check [options] -- folder\n";
  $usage    .= "  ---- Options:\n";
  $usage    .= " -stack=folder:     consider the folder contaning stacktraces, and only check the first crash of every stack\n";
  $usage    .= " -commit=sha:       the sha of Contiki-NG commit to check the inputs at\n";
  $usage    .= "  \n";
  $usage    .= "  ------------- General Options:\n";
  $usage    .= " -develop:          execute the inputs at the develop head commit\n";
  $usage    .= " -fix=<fix_name>:   specify a fix name to validate\n";
  $usage    .= " -output:           output folder [default: crash_triage]\n";
  $usage    .= " -quiet:            do not output all the files\n";
  $usage    .= "  \n";
  $usage    .= "  ------------- General Environment Variables:\n";
  $usage    .= "  FIXNAME_FILE      define the path to the security files containing fixes [default: $ENV{'HARNESS_PATH'}/info/security-fixes.txt]\n";
  $usage    .= "  ENTRY_POINT       Contiki-NG protocol entry point\n";
  $usage    .= "  LAB_PATH          define the working directory [default: $ENV{'WORKDIR_PATH'}/validation]\n\n\n";

  print $usage;
}

do {usage();die "Error: No mode specified\n"} if (not defined $validate and not defined $check);
do {usage();die "Error: validate and check are exclusive modes\n"}   if (defined $validate and defined $check);

## check previous instance
# create lab folder
die "Error: $LAB_PATH exists remove the directory first\n" if (-d $LAB_PATH);
`mkdir -p $LAB_PATH`;
print "[+] Working directory:  $LAB_PATH\n";

my $crash_folder;
my @errors;
my @base_errors;

## assume running from script folder!!
chomp (my $script_dir = `pwd`);

do {&usage();die "Error: Need a crash folder\n"} if (@ARGV < 1);
($crash_folder) = @ARGV;

if ($check) {
  print "[+] Checking ";

  if ($stack) {
    print "crashing stacks in $stack from crashes in $crash_folder \n";
  } else {
    print "crashes in $crash_folder\n";
    check_crash_folder($crash_folder);
  }

} else {
  do {usage();die "Error: No fix nor develop option\n"} if (not defined $fix and not defined $develop);
  print "[+] Validating crashes in $crash_folder\n";
  check_crash_folder($crash_folder);
}


## check paths (because of chdir later)
my $output_folder = ($output ? $output : "crash-triage");
$output_folder = $script_dir . "/" . $output_folder    unless ($output_folder =~ /^\//);
`mkdir -p $output_folder`;

$crash_folder = $script_dir . "/" . $crash_folder      unless ($crash_folder =~ /^\//);

my $stamp_file = abs_path($stamps) if ($stamps);

if ($fix) {
  print "at $fix in file $FIXNAME_FILE";
  if ($develop)   {print " and at develop head\n";}
  else            {print "\n";}
} elsif ($commit) {print "at commit $commit\n";}
else              {print "at develop head only\n";}

unless ($stack) {print "[+] Processing " . int(@errors) ." files with protocol: $ENV{'ENTRY_POINT'}\n";}
print "\n";

### --------- initialization
### start reading commit files
# commits hash: {id} -> [name, commit_before, commit, @errors]
my %commits;
## populate %commits
&parse_pullrequest($FIXNAME_FILE);

## A bugfix is a pull request fixname
my $nb_bugfixes= int(keys %commits);
my %crashes_per_commit;         #{commit} -> [san-warned_filenames]
my %warning_per_commit;         #{commit} -> [valgrind-afl_filenames]
my %afl_per_commit;             #{commit} -> [afl_filenames]
my %undetected_per_commit;      #{commit} -> [undetected_filenames]
my %uniq_bad_inputs_per_commit; ## unified list of crashing files
## crashes to step (set after every execute_inputs)
my %crash_data; #{crash_filename} -> [type,step,time-to-exposure]

# go to our lab
{
  chdir("$LAB_PATH");

  print "at $LAB_PATH ... setting SUT ...\n";
  # clone a fresh contiki-ng repo
  `rm -fr contiki-ground-truth` if (-d "contiki-ground-truth");
  `git clone https://github.com/contiki-ng/contiki-ng.git contiki-ground-truth`;

  # get contiki-ng-fuzzing harnesses and its configuration
  `cp -r $ENV{HARNESS_PATH} eval-build`;
  print "[+] Setting done.\n\n";

  if ($check) {
    ## init @errors if stack traces
    if ($stack) {create_errors_from_stacktraces($stack);}

    my $cmt = "develop";
    #my ($name, $commit_before, $commit_to_validate) = @{$commits{$pr_id}};
    if ($fix)     {$cmt = $commits{(keys %commits)[0]}[1];}
    if ($commit)  {$cmt = $commit}

    reproducibility_check($cmt);

    print "[+] Check done.\n";
    exit 0;
  }

  ## set input timestamps if option
  &set_timestamps($stamp_file) if ($stamps);

  print "Start investigation among $nb_bugfixes fix(es) in $LAB_PATH\n";
  foreach my $pr_id (sort { $a <=> $b } (keys %commits)) {

    my ($name, $commit_before, $commit_to_validate) = @{$commits{$pr_id}};
    print "- [+] PR $name: <". substr($commit_before, 0, 10) . ", ". substr($commit_to_validate, 0, 10) . ">\n";


    # go to the commit before and check the actual crashing inputs
    # compute also the crashing stack traces
    &execute_inputs($commit_before, \@base_errors, 1);
    @{$uniq_bad_inputs_per_commit{$commit_before}} = array_minus(@base_errors, @{$undetected_per_commit{$commit_before}});
    my $crashes_before = int(@{$uniq_bad_inputs_per_commit{$commit_before}});

    ### --------- commit to validate (after fix)
    &execute_inputs($commit_to_validate, \@base_errors, 1);

    @{$uniq_bad_inputs_per_commit{$commit_to_validate}} = array_minus(@base_errors, @{$undetected_per_commit{$commit_to_validate}});
    my $crashes_after = int(@{$uniq_bad_inputs_per_commit{$commit_to_validate}});

    my $fixed_crashes   = $crashes_before - $crashes_after;
    my @witnesses       = array_minus(@{$uniq_bad_inputs_per_commit{$commit_before}},  @{$uniq_bad_inputs_per_commit{$commit_to_validate}});

    print " --- --- --- --- --- --- \n";
    print "[+] -- PR $name report:\n";
    print "      before [" . substr($commit_before,0,10) . "]: $crashes_before bad inputs\n";
    print "      after  [" . substr($commit_to_validate,0,10) . "]: $crashes_after bad inputs\n";
    print "[!] -- Number of undetected files: " . int(@{$undetected_per_commit{$commit_before}}) . "\n" if (int(@{$undetected_per_commit{$commit_before}}) > 0);
    print "[+] -- Number of bad inputs fixed: " . int(@witnesses) . "\n";
    print " --- --- --- --- --- --- \n";


    if ((not $quiet) and (int(@witnesses) > 0)) {
    	print "\n[+] List of witnesses:\n";
    	foreach my $witness (sort (@witnesses)) {
           print "     '$witness'\n";
      }
    }

     if ((not $quiet) and (int(@{$uniq_bad_inputs_per_commit{$commit_to_validate}}) > 0)) {
        print "[+] List of bad inputs after fix:\n";
        foreach my $bad_input (sort (@{$uniq_bad_inputs_per_commit{$commit_to_validate}})) {
           print "     '$bad_input'\n";
        }
     }

    ## populate output folder
    ## undetected
    if (int(@{$undetected_per_commit{$commit_before}}) > 0) {
      `mkdir -p $output_folder/undetected`;
      `mv '$LAB_PATH/$commit_before/undetected' $output_folder/undetected 2>/dev/null`;
    }
    ## witnesses
    my $witness_report_file = "$output_folder/witnesses/witness-report.txt";
    if (int(@witnesses) > 0) {
      `mkdir -p $output_folder/witnesses`;
      `mkdir -p $output_folder/witnesses/bad-inputs`;
      `mkdir -p $output_folder/witnesses/stacktraces`;

      open(my $FD, ">$witness_report_file")  or die "Cannot open file $witness_report_file: $!\n";
      printf $FD "%-s %-12s %-90s %-s\n", "type", "step", "name", "time-to-exposure(s)";
      foreach my $witness (sort (@witnesses)) {
        my $step = $crash_data{$witness}[1];
        `mv '$LAB_PATH/$commit_before/$step/crashes/$witness' $output_folder/witnesses/bad-inputs`;
        `mv '$LAB_PATH/$commit_before/$step/stacktraces/$witness-output.txt' $output_folder/notfixed/stacktraces 2>/dev/null`;
        printf $FD "%-4s %-12s %-90s %-d\n", $crash_data{$witness}[0], $step, $witness, ($stamps? $crash_data{$witness}[2]:0000);
        # get and move hash stacks
        chomp(my $stackhash = `grep -l "$witness" $LAB_PATH/$commit_before/$step/stacktraces/*stacktrace 2>/dev/null`);
        `cp '$stackhash' $output_folder/witnesses/` if(defined $stackhash and not (-e "$output_folder/witnesses/" . basename($stackhash)));
        `cp $LAB_PATH/$commit_before/$step/valgrind* $output_folder/witnesses/` if(defined glob("$LAB_PATH/$commit_before/$step/valgrind*"));
      }
      close($FD);
    }
    ## crashes
    my $notfixed_report_file = "$output_folder/notfixed/notfixed-report.txt";
    if (defined $uniq_bad_inputs_per_commit{$commit_to_validate}) {
      `mkdir -p $output_folder/notfixed`;
      `mkdir -p $output_folder/notfixed/bad-inputs`;
      `mkdir -p $output_folder/notfixed/stacktraces`;

      open(my $FD, ">$notfixed_report_file")  or die "Cannot open file $notfixed_report_file: $!\n";
      printf $FD "%-s %-12s %-90s %-s\n", "type", "step", "name", "time-to-exposure(s)";
      foreach my $bad_input (sort (@{$uniq_bad_inputs_per_commit{$commit_to_validate}})) {
        my $step = $crash_data{$bad_input}[1];
        `mv '$LAB_PATH/$commit_to_validate/$step/crashes/$bad_input' $output_folder/notfixed/bad-inputs`;
        `mv '$LAB_PATH/$commit_to_validate/$step/stacktraces/$bad_input-output.txt' $output_folder/notfixed/stacktraces 2>/dev/null`;
        ## to have the file sorted acc. the time-to-exposure:
        ## sort crash_triage/notfixed/notfixed_report.txt -n -k4
        printf $FD "%-4s %-12s %-90s %-d\n", $crash_data{$bad_input}[0], $step, $bad_input, ($stamps? $crash_data{$bad_input}[2] : 0000);
        # get and move hash stacks
        chomp(my $stackhash = `grep -l "$bad_input" $LAB_PATH/$commit_to_validate/$step/stacktraces/*stacktrace 2>/dev/null`);
        `cp '$stackhash' $output_folder/notfixed/` if(defined $stackhash and not (-e "$output_folder/notfixed/" . basename($stackhash)));
        `cp $LAB_PATH/$commit_to_validate/$step/valgrind* $output_folder/notfixed/` if(defined glob("$LAB_PATH/$commit_to_validate/$step/valgrind*"));
      }
      close($FD);
    }
  }

  if ($develop) {
    ## execute on notfixed errors (only if a fixname has been provided)
    if ($fix) {
      my ($name, $commit_before, $commit_to_validate) = @{$commits{(keys %commits)[0]}};
      if (defined $uniq_bad_inputs_per_commit{$commit_to_validate} and int($uniq_bad_inputs_per_commit{$commit_to_validate}) > 0) {
        &execute_inputs("develop", \@{$uniq_bad_inputs_per_commit{$commit_to_validate}}, 1);
      } else {
        print "[+] -- No crashes left after [" . substr($commit_to_validate,0,10) . "]\n";
        ### done
        exit(0);
      }
    } else {&execute_inputs("develop", \@base_errors, 1);}

    @{$uniq_bad_inputs_per_commit{"develop"}} = array_minus(@base_errors, @{$undetected_per_commit{"develop"}});
    my $crashes_not_fixed = int(@{$uniq_bad_inputs_per_commit{"develop"}});

    if ($crashes_not_fixed > 0) {
      print "[!] List of the $crashes_not_fixed bad inputs at the HEAD of Contiki-NG develop branch:\n";
      foreach my $bad_input (sort (@{$uniq_bad_inputs_per_commit{'develop'}})) {
            print "     '$bad_input'\n";
          }
      my $develop_report_file = "$output_folder/develop/develop-report.txt";
      `mkdir -p $output_folder/develop`;
      `mkdir -p $output_folder/develop/bad-inputs`;
      `mkdir -p $output_folder/develop/stacktraces`;

      open(my $FD, ">>$develop_report_file")  or die "Cannot open file $develop_report_file: $!\n";
      printf $FD "%-s %-12s %-90s %-s\n", "type", "step", "name", "time-to-exposure(s)";
      foreach my $bad_input (sort (@{$uniq_bad_inputs_per_commit{'develop'}})) {
        my $step = $crash_data{$bad_input}[1];
        `mv '$LAB_PATH/develop/$step/crashes/$bad_input' $output_folder/develop/bad-inputs`;
        `mv '$LAB_PATH/develop/$step/stacktraces/$bad_input-output.txt' $output_folder/develop/stacktraces 2>/dev/null`;
        ## to have the file sorted acc. the time-to-exposure:
        ## sort crash_triage/notfixed/notfixed_report.txt -n -k4
        printf $FD "%-4s %-12s %-90s %-d\n", $crash_data{$bad_input}[0], $step, $bad_input, ($stamps? $crash_data{$bad_input}[2] : 0000);
        # get and move hash stacks
        chomp(my $stackhash = `grep -l "$bad_input" $LAB_PATH/develop/$step/stacktraces/*stacktrace 2>/dev/null`);
        `cp '$stackhash' $output_folder/develop/` if(defined $stackhash and not (-e "$output_folder/develop/" . basename($stackhash)));
        `cp $LAB_PATH/develop/$step/valgrind* $output_folder/develop/` if(defined glob("$LAB_PATH/develop/$step/valgrind*"));
      }
      close($FD);
    } else {
      print "[+] -- No bad inputs at the HEAD of Contiki-NG develop branch\n";
    }
  }
}

### done
exit(0);

### --------- Functions

### --------- Argurments/Output Handlers

## initialize @errors and @base_errors with input files from $crash_folder
sub check_crash_folder {
  @errors = glob("$crash_folder/*");
  die "Error: No crashing inputs found\n"  if (@errors == 0);
  ## use to compute the undetected errors
  @base_errors = map {basename($_)} @errors;
}

## initialize the commits before/after (%commits) to validate the corresponding PR
## parse a security-fixes file
sub parse_pullrequest {
  my $file = shift;

  open(my $fh, '<', "$file")
  or die "Error: Cannot open '$file': $!\n";

  while(<$fh>) {
    ## FIX_NAME   PULL_REQUEST    COMMITS           COMMITS-BEFORE
    ##    $1          $2            $3                  $4
    if (/([\w\-]+)\s+(\d+)\s+(\w+)\s+(\w+)/)
    {
      if ($fix)
      {
        if (! ($1 cmp $fix)) {
          push @{$commits{int($2)}}, ($1, $4, $3);
          return;
        }
      }
    }
  }

}

## extract exposure time from $stamps
sub set_timestamps {
  my $file = shift;

  foreach my $input (@base_errors) {
    if ($input =~ /^(.*?)(:hang)?(:[^:]+)?$/) { #remove :<fuzzer> from the input name (and possibly the 'hang' keyword)
      my $fuzzer_file = $1;
      chomp(my $line = `grep "$fuzzer_file" $file `);
      if ($line =~ /,(\d+)$/)   {$crash_data{$input}[2]=$1}
      else                      {die "Error: wrong format for $file - '$input' - $line\n";}
    }
  }
  print "[+] Times to exposure loaded.\n";
}

### --------- Argurments/Output Handlers

### --------- Bug Validation Handlers
## Deduplicate bad inputs:
## Build the AFL-companion following fuzzing scripts
sub execute_inputs {
  my $commit = shift;
  my $inputs = shift;
  my $verbose = shift;

  # initialize Contiki_NG lab
  {
    ## checkout contiki-ng  github repo
    chdir("$LAB_PATH/contiki-ground-truth");
    `git checkout $commit 1>/dev/null 2>&1`;
    chdir("..");
  }

  # initialize the loop
  my $step=0;
  my @undetected_crash = @{$inputs};
  `mkdir $LAB_PATH/$commit`;
  `mkdir $LAB_PATH/$commit/to-detect`;
  `cp -p $crash_folder/* $LAB_PATH/$commit/to-detect`;

  if ( -d "$LAB_PATH/eval-build/savior-build" ) {
	  if ( $ENV{AFL_SANITIZED} ) { $ENV{'AFL_COMPANION'}="afl-clang-fast-$ENV{AFL_SANITIZED}"}
	  else                       { $ENV{'AFL_COMPANION'}="afl-clang-fast"}
  }

  ## set oracle with AFL_COMPANION if not set
  print "-- WITNESS_ORACLE $ENV{'WITNESS_ORACLE'} --\n" if (defined $ENV{'WITNESS_ORACLE'});
  print "-- AFL_COMPANION $ENV{'AFL_COMPANION'} --\n" if (defined $ENV{'AFL_COMPANION'});
  unless ( defined $ENV{'WITNESS_ORACLE'} ) {
    die "AFL_COMPANION or WITNESS_ORACLE should be set" unless ( defined $ENV{'AFL_COMPANION'} );
    print "-- set WITNESS_ORACLE with $ENV{'AFL_COMPANION'} --\n";
	  $ENV{'WITNESS_ORACLE'} = $ENV{'AFL_COMPANION'};
  } elsif ( $ENV{'WITNESS_ORACLE'} =~ /^\s*$/ ) {
    print "-- set WITNESS_ORACLE with $ENV{'AFL_COMPANION'} --\n";
	  $ENV{'WITNESS_ORACLE'} = $ENV{'AFL_COMPANION'};
  }

  print "\n[+] -- Commit $commit --\n";

  while (@undetected_crash > 0) {
    print " ... execute " . int(@undetected_crash) . " file(s) at step $step ...\n";

    `mkdir $LAB_PATH/$commit/$ENV{'WITNESS_ORACLE'}`;

    ### We use AFL-instrumentation as bug-oracle
    #Notice that we use (standard) AFL-clang-fast script for SAVIOR also since their AFL implementation was not soundly replicating the witnesses.
    #if ( -d "$LAB_PATH/eval-build/savior-build" ) {
    #  afl_savior_companion_check(\@undetected_crash, $commit, $verbose);
    #} else {
      companion_check(\@undetected_crash, $commit, $verbose);
    #}

    print "\n";

    if (defined $afl_per_commit{$commit}) {
      print "\t[-] Detected " . int(@{$afl_per_commit{$commit}}) . " bad inputs.\n";
      ## remove detected files from folder to detect
      &move_files(\@{$afl_per_commit{$commit}}, "$LAB_PATH/$commit/$ENV{'WITNESS_ORACLE'}/crashes/", $commit);
      #sanitizer scripts are not handling timeouts (detected with valgrind)
      foreach my $f (@{$afl_per_commit{$commit}}) {$crash_data{$f}[0]="c";$crash_data{$f}[1]="$ENV{'WITNESS_ORACLE'}";}
      ## update file to detect
      @undetected_crash = array_minus(@undetected_crash, @{$afl_per_commit{$commit}});
    } else {print "\t[-] Nothing detected\n"; `rm -fr $LAB_PATH/$commit/$ENV{'WITNESS_ORACLE'}`;}

    if (int(@undetected_crash) > 0) {
        `mkdir $LAB_PATH/$commit/undetected`;
        push @{$undetected_per_commit{$commit}}, @undetected_crash;
        &move_files(\@{$undetected_per_commit{$commit}}, "$LAB_PATH/$commit/undetected/", $commit);
        print "\t[-] Undetected " . int(@{$undetected_per_commit{$commit}}) . " files.\n";
    }
    last; #break
  }
}

## move detected bad inputs from to_detect to dest. folder
sub move_files {
  my $bad_inputs  = shift;
  my $destination = shift;
  my $commit      = shift;
  if (@{$bad_inputs} > 0)
  {
    `mkdir -p $destination`;
    foreach my $f (@{$bad_inputs})
      {
        `mv '$LAB_PATH/$commit/to-detect/$f' $destination`;
        `mv '$LAB_PATH/$commit/to-detect/$f-output.txt' $destination/../stacktraces` if (-e "$LAB_PATH/$commit/to-detect/$f-output.txt");
      }
  }
}


sub afl_savior_companion_check {
  my $undetected_files  = shift;
  my $commit            = shift;
  my $verbose           = shift;

  {
    # compile and check binary
    print "\t[-] Compiling Contiki-NG with $ENV{'AFL_COMPANION'} (savior) --\n";

    chdir("$LAB_PATH/eval-build/savior-build");

    `patch ../../contiki-ground-truth/Makefile.include < patch/Makefile.include.patch`;
    if ( $ENV{'FIXNAME'} =~ /uip-rpl-classic.*/ ) {
 	`patch ../../contiki-ground-truth/os/net/ipv6/uip-nd6.c < patch/uip-nd6.patch`;
    }

    `./savior-compile.sh > $ENV{LOG_PATH}/triage-compile.log 2>&1`;

    `rm -fr bin` if (-d "bin");
    `mkdir bin`;
    `mv $ENV{'WORKDIR_PATH'}/bin/$ENV{'HARNESS_NAME'}.afl-clang-fast bin/`;
    die "Error: Unable to compile contiki-ng with $ENV{'AFL_COMPANION'} (see log into $ENV{'LOG_PATH'}/triage-compile.log)\n" unless (-e "bin/$ENV{'HARNESS_NAME'}.afl-clang-fast");
    chdir("../..");
  }

  print "\t[-] Execution --\n";
  foreach my $file (@{$undetected_files}) {
    `UBSAN_OPTIONS="halt_on_error=1:abort_on_error=1" timeout $timeout ./eval-build/savior-build/bin/$ENV{HARNESS_NAME}.afl-clang-fast '$LAB_PATH/$commit/to-detect/$file'`;
    my $return_code = $?;
    push @{$afl_per_commit{$commit}}, ($file) if (print_status($return_code, 0));
  }
}

sub companion_check {
  my $undetected_files  = shift;
  my $commit            = shift;
  my $verbose           = shift;
  my $path_to_oracle;

  {
    # Hack to force another binary for validating witnesses
    # switch between native-build and afl build folders on the name of AFL_COMPANION
    if ( $ENV{'WITNESS_ORACLE'} =~ /afl/ )
     {$path_to_oracle="eval-build/afl-build";}
    elsif ( $ENV{'WITNESS_ORACLE'} =~ /hfuzz/ )
     {$path_to_oracle="eval-build/hfuzz-build";}
     else
     {$path_to_oracle="eval-build/native-build";}

    # compile and check binary
    print "\t[-] Compiling Contiki-NG with $path_to_oracle/$ENV{'WITNESS_ORACLE'} --\n";

    chdir("$LAB_PATH/$path_to_oracle");
    `./$ENV{'WITNESS_ORACLE'}-compile.sh > $ENV{LOG_PATH}/triage-compile.log 2>&1`;
    die "Error: Unable to compile contiki-ng with $ENV{'WITNESS_ORACLE'} (see log into $ENV{LOG_PATH}/triage-compile.log)\n" unless (-e "bin/$ENV{HARNESS_NAME}.$ENV{'WITNESS_ORACLE'}");
    chdir("../..");
  }

  print "\t[-] Execution: ./$path_to_oracle/bin/$ENV{HARNESS_NAME}.$ENV{'WITNESS_ORACLE'} --\n";
  my $ubsan_options = "UBSAN_OPTIONS=\"halt_on_error=1:abort_on_error=1:exitcode=" . 139 . "\"";
  foreach my $file (@{$undetected_files}) {
    `$ubsan_options timeout $timeout ./$path_to_oracle/bin/$ENV{HARNESS_NAME}.$ENV{'WITNESS_ORACLE'} \'$LAB_PATH/$commit/to-detect/$file\'`;
    my $return_code = $?;
    push @{$afl_per_commit{$commit}}, ($file) if (print_status($return_code, 1));
  }
}


### --------- Valgrind Handlers
## parse valgrind output and set %verdict with valdring's return value for every inputs
## TODO: problem: valgrind's --error-exitcode=<number> fixed to 50 not -11 ?
sub parse_valgrind_error {
  my $valgrind_output = shift;
  my $crash_file      = undef;
  my %verdict;

  # split Valgrind ouput by 'Testing' keyword
  my @error_output = split(/Testing /, $valgrind_output);
  shift @error_output; #remove first line (command line)

  my $cpt=1;
  my $loop_bound=int(@error_output);
  # foreach crash output
  foreach my $oss (@error_output) {
    local $| = 1;
    print "\r\t[-] Validating $cpt/$loop_bound --";
    STDOUT->flush();
    # get the corresponding crash file
    if ($oss =~ /with ([\w\.\/\-:,+]+)/) {
      $verdict{basename($crash_file)} = 0 if (defined $crash_file and not defined $verdict{basename($crash_file)});
      $crash_file = $1;
    }
    # get the corresponding valgrind return code
    if ($oss =~ /valgrind return code: (-?\d+)/) {
      die "Error while parsing Valgrind output\n" unless(defined $crash_file); # we missed the file name
      $verdict{basename($crash_file)} = int($1);
      $crash_file = undef;
    }
    $cpt++;
  }
  print "\n";
  return \%verdict;
}

## parse valgrind output and save the stacktrace %traces with valdring's return value for every inputs
sub print_valgrind_stacktrace {
  my $folder = shift;
  my $valgrind_output = shift;

  my $crash_file = undef;
  my %traces;
  my %verdict;

  # split Valgrind ouput by 'Testing' keyword
  my @error_output = split(/Testing /, $valgrind_output);
  shift @error_output; #remove first line (command line)

  # foreach crash output
  foreach my $oss (@error_output) {
    # get the corresponding crash file
    if ($oss =~ /with ([\w\.\/\-:,+]+)/) {
      $verdict{basename($crash_file)} = 0 if (defined $crash_file and not defined $verdict{basename($crash_file)});
      $crash_file = $1;
    }
    # get the corresponding valgrind stacktrace
    if ($oss =~ /valgrind return code: (-?\d+)/) {
      die "Error while parsing Valgrind output\n" unless(defined $crash_file); # we missed the file name
      if (int ($1) == -11) {
        my ($hash,$stacktrace) = &valgrind_stack_parse_and_hash($oss);
        if (defined $traces{$hash})
          {push @{$traces{$hash}{'crash_files'}}, basename($crash_file);}
        else {
          push @{$traces{$hash}{'crash_files'}}, basename($crash_file);
          $traces{$hash}{'trace'}         = $stacktrace;
        }
      }
      $verdict{basename($crash_file)} = int ($1);
      $crash_file = undef;
    }
  }

  ## print stack traces and crashing input matching them
  &print_stack_traces($folder, \%traces);
}

## parse valgrind's stacktrace and create its hash
sub valgrind_stack_parse_and_hash {
  my $error_output = shift;
  if ($error_output =~ /Stack trace for(.*)valgrind return/s) {
    my @trace_by_line = split('\n', $1);
    shift @trace_by_line;
    shift @trace_by_line;
    my $stacktrace  = join("\n", @trace_by_line) . "\n";
    my $hash        = hash_value($stacktrace);
    #print "Stack trace is:\n$stacktrace, hash: $hash";
    return ($hash,$stacktrace);
  }
  die "Error: Crashing input without valgrind stack trace\n";
}

## print valgrind's stacktrace with its corresponding crashing inputs
use constant STACKTRACE_OUT        => ".stacktrace";
sub print_stack_traces {
  my $folder = shift;
  my $ref_to_stacktrace = shift;

  `mkdir $folder`;
  foreach my $hash (keys %{$ref_to_stacktrace}) {
    open(my $stck_fd, '>', "$folder/$hash" . STACKTRACE_OUT) or die "Error: Cannot open '$hash" . STACKTRACE_OUT . "': $!\n";

    print $stck_fd int(@{$ref_to_stacktrace->{$hash}{'crash_files'}}) . " crashing input(s) matching the hash '$hash':\n";
    print $stck_fd join("\n", (sort @{$ref_to_stacktrace->{$hash}{'crash_files'}}));

    print $stck_fd "\n\nStack Trace:\n";
    print $stck_fd $ref_to_stacktrace->{$hash}{'trace'};

    close($stck_fd);
  }

  ## some nice information:
  print "\t[-] Distinct number of crashing stack traces: " . int(keys %{$ref_to_stacktrace}) . " --\n";
}

## count the number of bad_inputs into %verdict
sub count_crashes {
    my $ref_verdict = shift;
    my $nb_bads = 0;
    foreach my $item (keys  %{$ref_verdict}) {
      $nb_bads++ if (&is_bad_valgrind_code($ref_verdict->{$item}));
    }
  return $nb_bads;
}

# A crash is a valgrind's return code of -11 or -9 (timeouts)
# bad valgrind's return code
sub is_bad_valgrind_code {
  my $return_code = shift;
  return 1 if ($return_code == -11);
  return 2 if ($return_code == -9);
  return 0;
}
### --------- Valgrind Handlers


### --------- Sanitizer Handlers

## parse raise-san-messages.sh output and collect sanitizer stacktraces
sub count_san_warnings {
  my $folder = shift;
  my $san_output = shift;
  my %traces;
  my @file_warned = ();

  ## raise-san-messages lists the san-outputs per files
  while($san_output =~ /([\w\-:,+]*) raised an ASAN\/UBSAN error/g)
  {
    my $filename = $1;
    my $output = `cat $folder/$filename-output.txt`;
    $output =~ s/(0x[0-9a-f]+)//g; ## remove addresses to compute a common hash
    my ($hash,$stacktrace) = &san_parse_and_hash($output);
    # if ($stacktrace eq "0")
    # {
    #   push @file_warned, ($filename); ##UndefinedBehavior
    #   next;
    # }
    $traces{$hash}{'trace'} = $stacktrace unless (defined $traces{$hash});
    push @{$traces{$hash}{'crash_files'}}, ($filename);
    push @file_warned, ($filename);
  }

  return (\@file_warned,\%traces);
}

## parse sanitizer stacktrace and create its hash
sub san_parse_and_hash {
  my $error_output = shift;
  if ($error_output =~ /ERROR: AddressSanitizer(.*)(AddressSanitizer can not provide additional|is located|is a wild pointer)/s) {
    my @trace_by_line = split('\n', $1);
    shift @trace_by_line;
    shift @trace_by_line;
    my $stacktrace  = join("\n", @trace_by_line) . "\n";
    my $hash        = hash_value( $stacktrace );
    #print "Stack trace is:\n$stacktrace, hash: $hash";
    return ($hash,$stacktrace);
  } elsif ($error_output =~ /runtime error(.*)SUMMARY: UndefinedBehaviorSanitizer/s) {
    my @trace_by_line = split('\n', $1);
    shift @trace_by_line;
    my $stacktrace  = join("\n", @trace_by_line) . "\n";
    my $hash        = hash_value( $stacktrace );
    #print "Stack trace is:\n$stacktrace, hash: $hash";
    return ($hash,$stacktrace);
  }
  die "Error: SAN messages without stack trace:\n$error_output\n";
}

use constant SAN_STACKTRACE_OUT        => ".san-stacktrace";
sub print_san_stack_traces {
  my $folder            = shift;
  my $ref_to_stacktrace = shift;

  `mkdir -p $folder`;
  foreach my $hash (keys %{$ref_to_stacktrace}) {
    open(my $stck_fd, '>', "$folder/" . $hash . SAN_STACKTRACE_OUT) or die "Error: Cannot open '$hash" . STACKTRACE_OUT . "': $!\n";

    print $stck_fd int(@{$ref_to_stacktrace->{$hash}{'crash_files'}}) . " warned input(s) matching the hash '$hash':\n";
    print $stck_fd join("\n", (sort @{$ref_to_stacktrace->{$hash}{'crash_files'}}));

    print $stck_fd "\n\nStack Trace:\n";
    print $stck_fd $ref_to_stacktrace->{$hash}{'trace'};

    close($stck_fd);
  }

  ## some nice information:
  print "\t[-] Distinct number of sanitizer stack traces: " . int(keys %{$ref_to_stacktrace}) . " --\n";
}
### --------- Sanitizer Handlers


### --------- Check mode

## extract the first crash input from stacktrace reports
sub create_errors_from_stacktraces {
  my $stack_folder = shift;

  my @stacks = glob("$stack_folder/*stacktrace");
  foreach my $s (@stacks) {
    my @outputs = split('\n',`head -n 2 $s`);
    shift(@outputs);
    chomp(my $crash_name = shift(@outputs));
    $crash_name =~ s/^\s+|\s+$//g;

    push @errors, ($crash_name);
  }
  ## use to compute the undetected errors
  @base_errors = map {basename($_)} @errors;
}

## compile and execute N different Contiki-NG binaries
sub reproducibility_check {
  my  $commit  = shift;

  die "[-] Error: wrong commit value\n" if (not defined $commit);
  print "\t At:    $commit\n";
  print "\t GCC:   " . `gcc --version | head -n 1 `;
  print "\t CLANG: " . `clang --version | head -n 1 `;

  my $HARNESS = $ENV{'HARNESS_NAME'};
  {
    ## checkout contiki-ng  github repo
    chdir("contiki-ground-truth");
    `git checkout $commit 1>/dev/null 2>&1`;

    # compile
    print "\t[-] compiling with...";

    chdir("../eval-build");
    `rm -fr bin` if (-d "bin");

    print "gcc-5 -O0,";
    `CC=gcc-5 CFLAGS="-fPIE -O0" ./gcc-compile.sh 1>/dev/null 2>&1`;
    `mv bin/$HARNESS.native-gcc bin/$HARNESS.native-gcc5-00`;

    print "gcc-5 -O3,";
    `CC=gcc-5 CFLAGS="-fPIE -O3" ./gcc-compile.sh 1>/dev/null 2>&1`;
    `mv bin/$HARNESS.native-gcc bin/$HARNESS.native-gcc5-03`;

    print "gcc -O0,";
    `CFLAGS="-O0" ./gcc-compile.sh 1>/dev/null 2>&1`;
    `mv bin/$HARNESS.native-gcc bin/$HARNESS.native-gcc-00`;

    print "gcc -O3,";
    `CFLAGS="-O3" ./gcc-compile.sh 1>/dev/null 2>&1`;
    `mv bin/$HARNESS.native-gcc bin/$HARNESS.native-gcc-03`;

    print "clang -O0,";
    `CFLAGS="-O0" ./clang-compile.sh 1>/dev/null 2>&1`;
    `mv bin/$HARNESS.native-clang bin/$HARNESS.native-clang-00`;

    print "clang -O3,";
    `CFLAGS="-O3" ./clang-compile.sh 1>/dev/null 2>&1`;
    `mv bin/$HARNESS.native-clang bin/$HARNESS.native-clang-03`;

    print "afl-gcc-5,";
    `CC=$ENV{'AFL5_PATH'}/afl-gcc AFL_CC=gcc-5 ./afl-gcc-compile.sh 1>/dev/null 2>&1`;
    `mv bin/$HARNESS.afl-gcc bin/$HARNESS.afl-gcc5`;
    print "afl-gcc,";
    `./afl-gcc-compile.sh 1>/dev/null 2>&1`;

    print "afl-clang,";
    `./afl-clang-compile.sh 1>/dev/null 2>&1`;
    print "afl-clang-fast,";
    `./afl-cf-compile.sh 1>/dev/null 2>&1`;

    print "native-san,";
    `./clang-san-compile.sh 1>/dev/null 2>&1`;
    print "afl-gcc-asan.";
    `./afl-gcc-asan-compile.sh 1>/dev/null 2>&1`;

    print "\n";
    chdir("..");
  }

  ## track compiler crashes count for summary
  my ($cpt_gcc50, $cpt_gcc53, $cpt_gcc0, $cpt_gcc3, $cpt_clang0, $cpt_clang3, $cpt_aflgcc, $cpt_aflgcc5, $cpt_aflclang, $cpt_aflcf, $cpt_san, $cpt_aflasan)
  =  (0,0,0,0,0,0,0,0,0,0,0,0);

  my $asan_options = "ASAN_OPTIONS=exitcode=" . 139;
  foreach my $crash_name (@base_errors) {
    ## do hash error -> stack trace
    my $s = "<stack>";
    print "Stack trace: $s (crash file: '$crash_folder/$crash_name')\n";

    `timeout $timeout ./eval-build/bin/$HARNESS.native-gcc5-00 $crash_folder/$crash_name`;
    my $return_code = $?;
    printf ("%15s: ", "gcc5-O0");
    $cpt_gcc50++ if (print_status($return_code, 1));

    `timeout $timeout ./eval-build/bin/$HARNESS.native-gcc5-03 $crash_folder/$crash_name`;
    $return_code = $?;
    printf ("%15s: ", "gcc5-O3");
    $cpt_gcc53++ if (print_status($return_code, 1));

    `timeout $timeout  ./eval-build/bin/$HARNESS.native-gcc-00 $crash_folder/$crash_name`;
    $return_code = $?;
    printf ("%15s: ", "gcc-O0");
    $cpt_gcc0++ if (print_status($return_code, 1));

    `timeout $timeout ./eval-build/bin/$HARNESS.native-gcc-03 $crash_folder/$crash_name`;
    $return_code = $?;
    printf ("%15s: ", "gcc-O3");
    $cpt_gcc3++ if (print_status($return_code, 1));

    `timeout $timeout ./eval-build/bin/$HARNESS.native-clang-00 $crash_folder/$crash_name`;
    $return_code = $?;
    printf ("%15s: ", "clang-O0");
    $cpt_clang0++ if (print_status($return_code, 1));

    `timeout $timeout ./eval-build/bin/$HARNESS.native-clang-03 $crash_folder/$crash_name`;
    $return_code = $?;
    printf ("%15s: ", "clang-O3");
    $cpt_clang3++ if (print_status($return_code, 1));

    `timeout $timeout ./eval-build/bin/$HARNESS.afl-gcc $crash_folder/$crash_name`;
    $return_code = $?;
    printf ("%15s: ", "afl-gcc");
    $cpt_aflgcc++ if (print_status($return_code, 1));

    `timeout $timeout ./eval-build/bin/$HARNESS.afl-gcc5 $crash_folder/$crash_name`;
    $return_code = $?;
    printf ("%15s: ", "afl-gcc5");
    $cpt_aflgcc5++ if (print_status($return_code, 1));

    `timeout $timeout ./eval-build/bin/$HARNESS.afl-clang $crash_folder/$crash_name`;
    $return_code = $?;
    printf ("%15s: ", "afl-clang");
    $cpt_aflclang++ if (print_status($return_code, 1));

    `timeout $timeout ./eval-build/bin/$HARNESS.afl-clang-fast $crash_folder/$crash_name`;
    $return_code = $?;
    printf ("%15s: ", "afl-clang-fast");
    $cpt_aflcf++ if (print_status($return_code, 1));

    `$asan_options timeout $timeout ./eval-build/bin/$HARNESS.san $crash_folder/$crash_name 1>/dev/null 2>&1`;
    $return_code = $?;
    printf ("%15s: ", "gcc-san");
    $cpt_san++ if (print_status($return_code, 1));

    #print "exec: $asan_options ./eval-build/bin/$HARNESS.afl-gcc-asan $crash_folder/$crash_name 1>/dev/null 2>&1";
    `$asan_options timeout $timeout ./eval-build/bin/$HARNESS.afl-gcc-asan $crash_folder/$crash_name 1>/dev/null 2>&1`;
    $return_code = $?;
    printf ("%15s: ", "afl-gcc-asan");
    $cpt_aflasan++ if (print_status($return_code, 1));
  }

  print "[+] Total crashes: " . int(@base_errors) . "\n";
  print " compiler crashes: gcc5-0, gcc5-3, gcc0, gcc3, clang0, clang3, aflgcc, aflgcc5, aflclang, aflcf, san, aflasan\n";
  printf("                  %6d, %6d, %4d, %4d, %6d, %6d, %6d, %6d, %8d, %5d, %3d, %7d\n",
    $cpt_gcc50, $cpt_gcc53,
    $cpt_gcc0, $cpt_gcc3,
    $cpt_clang0, $cpt_clang3,
    $cpt_aflgcc, $cpt_aflgcc5, $cpt_aflclang, $cpt_aflcf,
    $cpt_san, $cpt_aflasan);
}

### Check target's status value after executing an input file
# - return 0 if nothing bad detected    (print .)
# - return 1 if deadly signal detected  (print x)
# - return 2 if timeout detected        (print h)
## ref: https://perldoc.perl.org/perlvar#$?
sub print_status {
  my $status = shift;
  my $verbose = shift;
  if    ($status == -1) {die "failed to execute: $!\n";}
  elsif ($status & 127) {printf "died with signal %d, %s coredump XXX\n", ($status & 127),  ($status & 128) ? 'with' : 'without' if($verbose); return 1;}
  else
  { #we specified an exit code for sanitizers
    if ($status >> 8 == 139)   {printf "x" if($verbose); return 1;}
    elsif($status >> 8 == 134) {printf "x" if($verbose); return 1;}
    elsif($status >> 8 == 124) {printf "h" if($verbose); return 2;}
    else                       {printf "." if($verbose); return 0;}
  }
}
### --------- Check mode
