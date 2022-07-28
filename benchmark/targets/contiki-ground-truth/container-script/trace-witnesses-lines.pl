#!/usr/bin/perl -s
##
use strict;
use warnings;

my $current_path=$ENV{'PWD'};
our ($input_folder);

### compile with -g
chdir("$ENV{'HARNESS_PATH'}/native-build");
`./gdb-compile.sh`;


## set gdb
chdir("$current_path"); 
my $TIMEOUT=2;
my $entry_point_inject;

if    ($ENV{'ENTRY_POINT'} eq "coap")	 	{$entry_point_inject="inject_coap_packet"}
elsif ($ENV{'ENTRY_POINT'} eq "sicslowpan")	{$entry_point_inject="inject_sicslowpan_packet"}
elsif ($ENV{'ENTRY_POINT'} eq "snmp")		{$entry_point_inject="inject_snmp_packet"}
elsif ($ENV{'ENTRY_POINT'} eq "uip" ) 		{$entry_point_inject="inject_uip_packet"}
else {die "$ENV{'ENTRY_POINT'} not implemented";}

## only run the first witness for now
my @witnesses = glob("$input_folder/*");
my $input = $witnesses[0];

print_gdb_script("tmp.gdb");

### run the witnesses
my $target = "$ENV{'HARNESS_PATH'}/native-build/$ENV{'HARNESS_NAME'}.native";

print("exec: timeout $TIMEOUT gdb $target < tmp.gdb 2>gdb.err.\n");
my $gdb_output = `timeout $TIMEOUT gdb $target < tmp.gdb 2>gdb.err`;

sub print_gdb_script {

    my $gdb_script_name = shift;
    open(my $gdb_fd, '>', $gdb_script_name) or die "Error: Cannot create $gdb_script_name: $!\n";
 
    print $gdb_fd "
set pagination off
skip -gfi multiarch/*.S
skip -gfi multiarch/../*.S
skip -gfi libio/*.h
skip -gfi nptl/*.c
skip -gfi *printf*.c
skip -gfi linux/*.c

b $entry_point_inject
source gdb_tracer.py

commands
python step_trace()
quit
end

run $input
quit
";

    close($gdb_fd);
}

