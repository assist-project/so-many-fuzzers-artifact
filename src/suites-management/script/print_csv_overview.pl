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
# Contiki-NG Benchmark : Print the tools' performance from a csv file.
# Author: Clement Poncelet
# Data: July22
#
#
# The script outputs the tools' first witnesses for each trial and the mean table of the campaign. 
###
###


## compute the mean from an array of integers
sub mean { return @_ ? sum(@_) / @_ : 0 }


print "\n -- Campaign CSV Printer -- \n\n";
## option variables
our ($input);


### --------- get options
sub usage {
  my $usage  = "usage: $0 -input=file.csv\n";
  $usage    .= " -input=file.csv            csv file containing raw-data from a fuzzing campaign\n";
  $usage    .= "  \n";
  print $usage;
}

do {usage(); die "Error: Options -input required\n"} if (not defined $input);
die "Error: Input file not found" unless (-f "$input");

open(my $data, '<', $input) or die;

my %tools;
### -- header
my $head = <$data>;
chomp($head);
my @words = split ",", $head;
shift(@words);
for (my $i = 0; $i < @words; $i++)
{
	$tools{$i} = $words[$i];
}

my $nbRun = 1;
my %raw_data;
while (my $line = <$data>) 
{
    chomp $line;
    my @words = split ",", $line;  
    shift(@words);
    for (my $i = 0; $i < @words; $i++)
    {
	my @tmp = ();
	unless($words[$i] =~ /timeout/) {
		@tmp = ($words[$i]);
	}
        $raw_data{$nbRun}{$tools{$i}} = \@tmp;
    }
    $nbRun++;
}

my $fh;
## Print raw-data (time-to-exposure or timeout for every trial)
#  Optionnaly print the raw-data into a csv file.
print(" Raw Data from $input:\n");


my %top_witnesses;
my $header = "run";

print("\n           ");
foreach my $i (sort keys %tools) {
	my $tool = $tools{$i};
	$tool = basename($tool);
	printf(" %-20s:", $tool);
	$header .= ",$tool";
	## array of the nbtrial top witnesses
	$top_witnesses{$tool}{'exposure'} = [];
	$top_witnesses{$tool}{'file'}	  = [];
}
print("\n");

foreach my $i (sort {$a <=> $b} keys %raw_data) {
	printf("-- run %-2s :", $i);
	foreach my $t (sort keys %{$raw_data{$i}}) {
		## ref to array
		my $rw = @{$raw_data{$i}}{$t};
		#print("Number of witness:" . int(@{$rw}) . "\n");

		if (int(@{$rw} > 0)) {
			my $time_to_exposure;
			$time_to_exposure=int($rw->[0]);

			printf("%-20s :", $time_to_exposure);
			push @{$top_witnesses{$t}{'exposure'}}, ($time_to_exposure);
			push @{$top_witnesses{$t}{'file'}}, ("something");#just push at each exposure (count nb trial exposed)
		}
		else    {
			printf("%-20s :", "timeout");
		}
	}
	print("\n");
}

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

