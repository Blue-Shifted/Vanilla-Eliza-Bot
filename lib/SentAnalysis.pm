# Naive implementation of rule-based sentiment analysis.
package SentAnalysis;

use English;
use DBI;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(sentiment_analysis);

my $sadb = "data/SA.db";
my $usrdb = "data/user.db";

sub logit_scale { return (log($ARG[0] + .05) - log($ARG[1] + .05)); }
sub update_user {
	my $usrdbh = DBI->connect("dbi:SQLite:dbname=$usrdb");
	my $sa = $ARG[0];
	my $user = $ARG[1];
	my $msg = time() .":$user->{'content'}";
	my $stmt = "SELECT personality FROM users WHERE id = (?)";
	my $usrth = $usrdbh->prepare($stmt);
	$usrth->execute($user->{'author'}{'id'});
	my $points = $usrth->fetchrow_array;
	$usrth->finish;
	if (defined $points) {
		if ($points eq "N/A") {
			$stmt = "UPDATE users SET last_message = (?) WHERE id = (?);";
			$usrth = $usrdbh->prepare($stmt);
			$usrth->execute($msg, $user->{'author'}{'id'});
		} else {
			$sa = sprintf("%.2f", ($points + $sa));
			$stmt = "UPDATE users SET last_message = (?), personality = (?) WHERE id = (?);";
			$usrth = $usrdbh->prepare($stmt);
			$usrth->execute($msg, "$sa", $user->{'author'}{'id'}); 
		}
	} 
	else {
		$stmt = "INSERT INTO users VALUES(?, ?, ?, ?, ?, null);"; 
		$usrth = $usrdbh->prepare($stmt);
		$usrth->execute($user->{'author'}{'id'}, $user->{'author'}{'username'}, "$sa", $msg, time());
	}
	$usrdbh->disconnect;
	return $sa;
}
# Modify this to only take the general $msg parameter.
sub sentiment_analysis {
	my $sadbh = DBI->connect("dbi:SQLite:dbname=$sadb");
	my $text = $ARG[0]->{'content'};
	$text =~ s/[[:punct:]]//g;
	my @text_arr = split ' ', lc($text);
	my ($p, $n) = (0, 0);
	my $stmt = "SELECT point FROM lexicon WHERE word = (?)";
	my $sasth = $sadbh->prepare($stmt);
	for my $word(@text_arr) {
		$sasth->execute($word);
		my $point = $sasth->fetchrow_array;
		if ($point) {
			if ($point < 0) { $n -= $point; }
			elsif ($point > 0) { $p += $point; }
		}
		$sasth->finish;
	}
	$sadbh->disconnect;
	return update_user(logit_scale($p, $n), $ARG[0]);
	#return logit_scale($p, $n);
}
