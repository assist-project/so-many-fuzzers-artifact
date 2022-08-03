#!/usr/bin/perl -s
##
use strict;
use warnings;
use Time::Seconds;
use File::Basename;
use List::Util qw(sum);
use Array::Utils qw(:all);
use Hash::Util qw(hash_value);


###
###
#
# Contiki-NG Benchmark : Print the tools' performance for a given fuzzing campaign.
# Author: Clement Poncelet
# Data: November21
#
#
# The script outputs the tools' first witnesses for each trial and the mean table of the campaign. 
# A fuzzing campaign folder consists in:
#   - trial folders (run<id>),
#   - containing tool folders (run<id>/tool)
#   - containing a fuzzing trial output with the folder crash[-_]triage.
#
###
###


## compute the mean from an array of integers
sub mean { return @_ ? sum(@_) / @_ : 0 }


print "\n -- Campaign Result Printer -- \n\n";
## option variables
our ($input,$csv);


### --------- get options
sub usage {
  my $usage  = "usage: $0 -input=dir [-csv=file]\n";
  $usage    .= " -input=dir                 campaign folder containing witness identification (in crash-triage)\n";
  $usage    .= " ----- Optional:\n";
  $usage    .= " -csv=file                  write raw-data into file (.csv format).\n";
  $usage    .= "  \n";
  print $usage;
}

do {usage(); die "Error: Options -input required\n"} if (not defined $input);
die "Error: Input folder not found" unless (-d "$input");
print "  - write raw-data into " . basename($csv) . ".\n" if (defined $csv);

my @trial_folders = grep {-d "$_"}  glob("$input/*");
my @tool_folders  = grep {-d "$_"}  glob("$trial_folders[0]/*");
print "[+] Collect " . int(@tool_folders) . " tools and " . int(@trial_folders) . " trials\n\n";

## Go over trials - tools
## raw_data: 'tool' -> 'trial number' -> timeout
my %raw_data;
my $trial_nb = 0;
foreach my $trial (@trial_folders) {
  $trial_nb ++;

  ## assuming naming convention
  my $trial_name = basename $trial;
  if ($trial_name =~ /run(\d+)/) {$trial_nb = int($1)}

  foreach my $tool (sort @tool_folders) {
    my $tool_name = basename $tool;
    my $current_path = "$trial/$tool_name";

    ## assuming triage already done
    my $crash_folder_format;
    unless (-d  "$current_path/crash-triage") {
	  die "Error: $trial_name/$tool_name/crash[-_]triage missing.\n" unless (-d "$current_path/crash_triage");
	  $crash_folder_format="crash_triage";
    } else {$crash_folder_format="crash-triage"}
    ## Convenient to debug 
    #  An undetected file contains an input which did not provoke the oracle misbehavior before fix.
    ###
    #print "Warning! $trial_name/$tool_name has undetected files!\n" if (-d "$current_path/$crash_folder_format/undetected");
    
    my @witnesses = ();
    if (-d "$current_path/$crash_folder_format/witnesses") {
	my $witnesses_lists = `tail -n +2 $current_path/$crash_folder_format/witnesses/witness[-_]report.txt | sort -n -k 4`; 
        @witnesses = split('\n', $witnesses_lists);
    }
    $raw_data{$trial_nb}{$tool_name}=\@witnesses;
  }
}


my $fh;
if (defined $csv) {open($fh, '>', "$csv") or die "Cannot open '$csv': $!\n";}

## Print raw-data (time-to-exposure or timeout for every trial)
#  Optionnaly print the raw-data into a csv file. 
print(" Raw Data from $input:\n");
my %top_witnesses;
my $header = "run";

print("\n           ");
foreach my $tool (sort @tool_folders) {
	$tool = basename($tool);
	printf(" %-20s:", $tool);
	$header .= ",$tool";
	## array of the nbtrial top witnesses
	$top_witnesses{$tool}{'exposure'} = [];
	$top_witnesses{$tool}{'file'}	  = [];
}
print("\n");
if (defined $csv) {print $fh "$header\n";}

foreach my $i (sort {$a <=> $b} keys %raw_data) {
	printf("-- run %-2s :", $i);
	my $line="run$i";


	foreach my $t (sort keys %{$raw_data{$i}}) {
		## ref to array
		my $rw = @{$raw_data{$i}}{$t};
		#print("Number of witness:" . int(@{$rw}) . "\n");

		if (int(@{$rw} > 0)) {
			my $earliest_witness = $rw->[0];

			my $file_name;
			my $time_to_exposure;

			if ($earliest_witness =~ /(id.*|SIG.*|.*honggfuzz.*)\s+(\d+)/)
				{$file_name=$1;$time_to_exposure=int($2);}

			printf("%-20s :", $time_to_exposure);
			push @{$top_witnesses{$t}{'exposure'}}, ($time_to_exposure);
			push @{$top_witnesses{$t}{'file'}}, ($file_name);

			$line .= ",$time_to_exposure";
		}
		else    {
			printf("%-20s :", "timeout");
			$line .= ",timeout";
		}
	}
	print("\n");
	if (defined $csv) {print $fh "$line\n"}
}
if (defined $csv) {close $fh;print "$csv written.\n"}


## Print campaign summary nb_success_trial:average)
print("-----------------\n");
print(" NBTrial and Mean Time to Exposure from $input :\n");
foreach my $t (sort keys %top_witnesses) {
	printf("-- %-30s:", $t);
	##printf("I mean: %s \n", join(" ", @{$top_witnesses{$t}{'exposure'}}));
	##			>with bad rounding function<
	my $avg = int(mean(@{$top_witnesses{$t}{'exposure'}}) + 0.5);
	printf("%+8s:%-7s", int(@{$top_witnesses{$t}{'file'}}), $avg);
	my $val = Time::Seconds->new($avg);
	printf("(%02d:%02d:%02d)\n", $val->hours,$val->minutes % 60,$val->seconds % 60);
}
print("-----------------\n");

