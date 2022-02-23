#!/usr/bin/perl -w

# BSD 2-Clause License
#
# Copyright (c) 2017-2022, Giovanni Bechis
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

use Getopt::Std;
use Net::SMTP;
use POSIX qw(strftime);

=head1 NAME

smtp.pl - a simple smtp client

=head1 DESCRIPTION

smtp.pl is a simple cli smtp client used to send test emails for
debugging purposes.

=cut

my %opts;
my ($from, $host, $to, $cc);
my $err = 0;
my $text;

getopts('c:f:h:t:', \%opts);

# Check if stdin is empty using a 1 second timeout
$SIG{ALRM} = sub { die 'STDIN' };
eval {
  alarm(1);
  while (<STDIN>) {
    $text .= $_;
  }
  alarm(0);
};

if ( defined $opts{'f'} ) {
  $from = $opts{'f'};
} else {
  print "From address is needed [-f]\n";
  $err = 1;
}

if ( defined $opts{'h'} ) {
  $host = $opts{'h'};
} else {
  print "Mail server host is needed [-h]\n";
  $err = 1;
}

if ( defined $opts{'t'} ) {
  $to = $opts{'t'};
} else {
  print "To address is needed [-t]\n";
  $err = 1;
}

$cc = $opts{'c'};

if($err eq 1) {
  exit 1;
}

my @email = split(/\@/, $from);

my $smtp = Net::SMTP->new($host,
                           Hello => $email[1],
                           Timeout => 30,
                           Debug   => 1,
                          );
$smtp->mail($from);
if($to =~ /\,/) {
  foreach my $t ( split(/\,/, $to) ) {
    $smtp->to("$t\n");
  }
} else {
  $smtp->to("$to\n");
}
if (!$err) {
  $smtp->data();
  $smtp->datasend("From: $from\n");
  if($to =~ /\,/) {
    foreach my $t ( split(/\,/, $to) ) {
      $smtp->datasend("To: $t\n");
    }
  } else {
    $smtp->datasend("To: $to\n");
  }
  $smtp->datasend("Cc: $cc\n") if defined $cc;
  if(not defined $text) {
    $smtp->datasend("Date: " . strftime("%a, %d %b %Y %H:%M:%S %z", localtime(time())) . "\n");
    $smtp->datasend("Subject: a test message\n");
    $smtp->datasend("\n");
    $smtp->datasend("A simple test message\n");
  } else {
    $smtp->datasend("$text\n");
  }
  $smtp->dataend();
} else {
  print "Error: ", $smtp->message();
}
$smtp->quit;
