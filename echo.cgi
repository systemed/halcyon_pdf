#!/usr/bin/perl -w

my $buffer = '';
if($ENV{CONTENT_LENGTH}) { read(STDIN,$buffer,$ENV{CONTENT_LENGTH}); }
$length=length($buffer);
print STDERR "Writing PDF, length $length\n";
print "Content-type: application/pdf\n";
print "Content-length: $length\n";
print "Content-disposition: inline; filename=\"file.pdf\"\n\n";
print $buffer;

