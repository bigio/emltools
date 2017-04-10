#!/usr/bin/perl

# BSD 2-Clause License
# 
# Copyright (c) 2017, Giovanni Bechis
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
use IO::All;

my $message;
my $score = 2.0;

my $dir = $ARGV[0];

opendir(DIR, $dir) or die "Could not open '$dir' for reading: $!\n";

while (my $email = readdir( DIR )) {

	if ($email eq '.' or $email eq '..') {
		next;
	}

	io($dir . "/" . $email) > $message;

	my $parser = MIME::Parser->new;
	$parser->output_to_core(1);

	my $entity = $parser->parse_data($message);

	my $mfrom = $entity->head->get('From');
	chomp($mfrom);
	$mfrom =~ s/(.*)\<//g;
	$mfrom =~ s/\>(.*)//g;

	if ( $mfrom =~ /\@/ ) {
		print $mfrom . " " . $score . "\n";
	}
}
closedir(DIR);
