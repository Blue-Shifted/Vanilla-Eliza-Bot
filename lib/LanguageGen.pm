# TODO :: Create text generators using Markov Chains.
#			Create compliment generator.
package LanguageGen;

use English;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(insult_gen);

sub insult_gen {
	my @a = ("dick", "knob", "fuck", "bitch", "cunt", "tard", "twat", "arse", "ass");
	my @b = ("washing", "eating", "mongering", "polishing", "cuddling", "shooting", "lewding", "whistling", "cooking", "swoggling");
	my @c = ("canoe", "potato", "eggplant", "rhubarb", "goblin", "banana", "cheese", "egg", "whale");

	my $target = $ARG[0];
	my ($r1, $r2, $r3, $r4) = (rand(scalar @a), rand(scalar @b), rand(scalar @c), rand(scalar @a));
	return "**$target,** you $c[$r3] $b[$r2] $a[$r1]-$a[$r4]."
}
