#!/usr/bin/perl -w
# ============================== Summary =======================================
# Program : check_redis.pl
# Version : 2010.7.29
# Date    : July 15 2010
# Updated : July 15 2010
# Author  : Alex Simenduev - (http://www.planetit.ws)
# Author  : Elan Ruusamäe <glen@delfi.ee>
# Summary : This is a Nagios plugin that checks Redis server state
#
# ================================ Description =================================
# The plugin is capable of check couple aspects of redis server. Supported
# checks are Connections, Memory, and Uptime. Check usage for how to use them.
# ================================ Change log ==================================
# Legend:
#               [*] Informational, [!] Bugix, [+] Added, [-] Removed
#
# Ver 2011.12.21
#               [!] use Redis plugin, not mess with TCP directly, fixes lockup
#                   when using redis 2.2.15 server (glen)
#
# Ver 2010.7.29:
#               [*] Removed unuseful 'print' code
#
# Ver 2010.7.15:
#               [*] Initial implementation.
# ========================== START OF PROGRAM CODE =============================
use strict;
use Getopt::Long;
use File::Basename;
use Redis;

# Variables Section
# -------------------------------------------------------------------------- #
my $VERSION       = "2011.12.21";
my $SCRIPT_NAME   = basename(__FILE__);
my $TIMEOUT       = 10;

# Nagios states
my $STATE_OK		= 0;
my $STATE_WARNING	= 1;
my $STATE_CRITICAL	= 2;
my $STATE_UNKNOWN	= 3;
my $STATE_DEPENDENT	= 4;

my @STATES = ("OK", "WARNING", "CRITICAL", "UNKNOWN", "DEPENDENT");

# Command line arguments variables
my $o_help	    = undef; # Want some help?
my $o_host	    = undef; # Hostname
my $o_port	    = undef; # Port
my $o_warn	    = undef; # Warning level
my $o_crit	    = undef; # Critical level
my $o_check	    = undef; # What to check (items, connections, memory)
my $o_inverse   = undef; # Use inverse calculation of warning/critical thresholds
my $o_version	= undef; # Script version
my $info;

# Entry point of the script
# -------------------------------------------------------------------------- #
check_arguments();	# First check for command line arguments

my ($intState, $intData, $strOutput, $strPerfData);

# Run 'info' command
eval {
	no warnings 'redefine';
	local *Carp::longmess = sub { shift(), "\n" };
	$info = get_info();
};

if ($@) {
	# Exit if connection failed
	print $STATES[$STATE_CRITICAL] . " - $@";
	exit $STATE_CRITICAL;
}

# Get number of items
if ($o_check =~ /^connections$/i) {
	$intData = $info->{connected_clients};
    $strOutput    = "$intData number of connections to the server";
    $strPerfData  = "'Connections'=" . $intData . ";;;;";
}
# Get memory usage
elsif ($o_check =~ /^memory$/i) {
	my $used_memory_human = $info->{used_memory_human}; # Get used in human readable format
	$intData = $info->{used_memory}; # Get used bytes
    $strOutput    = "$used_memory_human memory in use by server";
    $strPerfData  = "'Used'=" . $intData . "B;;;; ";
}
# Get uptime
elsif ($o_check =~ /^uptime$/i) {
	$intData = $info->{uptime_in_days};
    $strOutput    = "Up for $intData days";
    $strPerfData  = "'Uptime'=" . $intData . "d;;;;";
}
# Set state to Unknown for anything else
else {
    $intState     =  $STATE_UNKNOWN;
    $strOutput    = "Unknown check option ('$o_check') was specified";
}

# Check if state was set to UNKNOWN (3),
# if not, check if we using inverse option, then
# calculate the state according to data variable from the above checks
if (defined($intState) && $intState == $STATE_UNKNOWN) {
    $strPerfData  = "";
}
elsif (! defined($o_inverse)) {
    if ($intData > $o_crit) { $intState = $STATE_CRITICAL; }
    elsif ($intData > $o_warn) { $intState = $STATE_WARNING; }
    else { $intState = $STATE_OK; }
}
else {
    if ($intData < $o_crit) { $intState = $STATE_CRITICAL; }
    elsif ($intData < $o_warn) { $intState = $STATE_WARNING; }
    else { $intState = $STATE_OK; }
}

# Now print the final output string
print $STATES[$intState] . " - $strOutput|$strPerfData\n";

# Finally exit with current state error code.
exit $intState;

# This sub parses the command line arguments
sub check_arguments {
    # if no arguments specified just print usage
    if ($#ARGV + 1 == 0) {
	    print_usage();
	    exit $STATE_UNKNOWN;
    }

	Getopt::Long::Configure ("bundling");
	GetOptions(
		'h|help'		=> \$o_help,
		'H|hostname=s'	=> \$o_host,
		'P|port=i'      => \$o_port,
		'C|check=s'     => \$o_check,
		'w|warn=i'	    => \$o_warn,
		'c|crit=i'	    => \$o_crit,
		'I|inverse'     => \$o_inverse,
		'V|version'	    => \$o_version,
	) || exit $STATE_UNKNOWN; # exit if one of the options was not privided with required type (integer or string)

	if (defined($o_help)) {
	    print_help();
	    exit $STATE_UNKNOWN;
	}

	if (defined($o_version)) {
	    print "$SCRIPT_NAME: $VERSION\n";
	    exit $STATE_UNKNOWN;
    }

	if (!defined($o_check)) {
	    print "Usage error: Specify what to check, using '--check' option!\n";
	    print_usage();
	    exit $STATE_UNKNOWN;
	}

	if (!defined($o_warn) || !defined($o_crit)) {
	    print "Usage error: Warning and critical options must be specified!\n";
	    print_usage();
	    exit $STATE_UNKNOWN;
    }

    # Set default values for some options if needed.
    $o_host = "localhost" unless defined($o_host);
    $o_port = "6379" unless defined($o_port);
}

sub get_info {
    $o_host = "localhost" unless defined($o_host);
    $o_port = "6379" unless defined($o_port);

	my $redis_hp = $o_host . ":" . $o_port;
	my $r = Redis->new( server => $redis_hp );
	my $info_hash = $r->info;
	return $info_hash;
}

sub print_usage {
	print "Usage: $SCRIPT_NAME [-H <host>] [-P <port>] -C <check> -w <warn level> -c <crit level> [-I] [-V]\n";
}

sub print_help {
	print "\nRedis check plugin for Nagios, version ", $VERSION, "\n";
	print "(C) 2010, Alex Simenduev - http://www.planetit.ws\n\n";
	print_usage();
	print <<EOD;
-h, --help
    print this help message
-H, --hostname=STRING
    name or IP address of host to check (default: localhost)
-P, --port=INTEGER
    Memcached port to use (default: 6379)
-C --check=STRING
    What to check (one of: connections, memory, uptime)
-w, --warn=INTEGER
    warning level (unit depends on the check)
-c, --crit=INTEGER
    critical level (unit depends on the check)
-I, --inverse
    Use inverse calculation of warning/critical thresholds
-V, --version
    prints version number

EOD
}
