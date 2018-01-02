#!/usr/bin/perl

# BSD 2-Clause License
#
# Copyright (c) 2018, Giovanni Bechis
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

use strict;
use warnings;

use MIME::Parser;
use Data::Dumper;
use Data::Validate::IP qw(is_private_ipv4 is_private_ipv6);
use IO::All;

my $message;
my $first_received;
my $received_header;
my $received_ip;
my $tmp_received_ip;

my $dir = $ARGV[0];

if ( not defined $dir ) {
	print "usage: $0 directory\n";
	exit;
}

opendir(DIR, $dir) or die "Could not open '$dir' for reading: $!\n";

while (my $email = readdir( DIR )) {

	if ($email eq '.' or $email eq '..') {
		next;
	}

	io($dir . "/" . $email) > $message;

	my $parser = MIME::Parser->new;
	$parser->output_to_core(1);

	my $entity = $parser->parse_data($message);

	my @received = $entity->head->get('Received');
	my $received_found = 0;
	foreach (@received) {
		chomp;
		$first_received = $_ unless /127\.0\.0\.1/;
		if ( defined $first_received && $first_received =~ /by/ ) {
			$received_header = $first_received;
			if ( $received_header =~/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/ ) {
				$tmp_received_ip = $1;
			}
			if ( is_private_ipv4($tmp_received_ip) ) {
				next;
			} else {
				$received_ip = $tmp_received_ip;
			}
		}
	}
	print $received_ip . "\n";
	$first_received = undef;
	$received_header = undef;
	$tmp_received_ip = undef;
	$received_ip = undef;
}
closedir(DIR);
