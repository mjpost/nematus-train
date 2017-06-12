#!/usr/bin/env perl
#
# This file is part of moses.  Its use is licensed under the GNU Lesser General
# Public License version 2.1 or, at your option, any later version.

# $Id: train-recaser.perl 1326 2007-03-26 05:44:27Z bojar $

use warnings;
use strict;
use Getopt::Long "GetOptions";

binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");

# apply switches
# ASR input has no case, make sure it is lowercase, and make sure known are cased eg. 'i' to be uppercased even if i is known
my ($MODEL, $UNBUFFERED, $ASR);
die("truecase.perl --model MODEL [-b] [-a] < in > out")
    unless &GetOptions('model=s' => \$MODEL,'b|unbuffered' => \$UNBUFFERED, 'a|asr' => \$ASR)
    && defined($MODEL);
if (defined($UNBUFFERED) && $UNBUFFERED) { $|=1; }
my $asr = 0;
if (defined($ASR) && $ASR) { $asr = 1; }

my (%BEST,%KNOWN);
open(MODEL,$MODEL) || die("ERROR: could not open '$MODEL'");
binmode(MODEL, ":utf8");
while(<MODEL>) {
  my ($word,@OPTIONS) = split;
  $BEST{ lc($word) } = $word;
  if ($asr == 0) {
    $KNOWN{ $word } = 1;
    for(my $i=1;$i<$#OPTIONS;$i+=2) {
      $KNOWN{ $OPTIONS[$i] } = 1;
    }
  }
}
close(MODEL);

my %SENTENCE_END = ("."=>1,":"=>1,"?"=>1,"!"=>1);
my %DELAYED_SENTENCE_START = ("("=>1,"["=>1,"\""=>1,"'"=>1,"&apos;"=>1,"&quot;"=>1,"&#91;"=>1,"&#93;"=>1);

while(<STDIN>) {
  chop;
  my @WORDS = split(' ', $_);
  my $sentence_start = 1;
  for(my $i=0;$i<=$#WORDS;$i++) {
    my ($word,$otherfactors);
    if ($WORDS[$i] =~ /^([^\|]+)(.*)/)
    {
      $word = $1;
      $otherfactors = $2;
    }
    else
    {
      $word = $WORDS[$i];
      $otherfactors = "";
    }
    if ($asr){
      $WORDS[$i] = lc($word); #make sure ASR output is not uc
    }

    if ($sentence_start && defined($BEST{lc($word)})) {
      $WORDS[$i] = $BEST{lc($word)}; # truecase sentence start
    }
    elsif (defined($KNOWN{$word})) {
      $WORDS[$i] = $word; # don't change known words
    }
    elsif (defined($BEST{lc($word)})) {
      $WORDS[$i] = $BEST{lc($word)}; # truecase otherwise unknown words
    }
    else {
      $WORDS[$i] = $word; # unknown, nothing to do
    }
    $WORDS[$i] .= $otherfactors;

    if    ( defined($SENTENCE_END{ $word }))           { $sentence_start = 1; }
    elsif (!defined($DELAYED_SENTENCE_START{ $word })) { $sentence_start = 0; }
  }
  print join(" ",@WORDS) . $/;
}
