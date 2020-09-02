use SentAnalysis qw(sentiment_analysis);
use LanguageGen qw(insult_gen);

use DBI;
use English;
use Tie::RegexpHash;
use AnyEvent::Discord::Client;
use strict;
use warnings;

my %command_ref ;
tie %command_ref, 'Tie::RegexpHash';
my $usrdb = "data/user.db";
my $token = "";
my $bot = new AnyEvent::Discord::Client(
        token => $token,
);

$command_ref{qr/^\!insult/} = sub { 
	my $msg = $ARG[0];
	my @mentions = @{$msg->{'mentions'}};
	if (!@mentions) { return "Please include target. Usage !insult \@victim(s)."; }
	my $ret = " ";
	foreach my $mention(@mentions) {
		$ret = $ret .insult_gen($mention->{'username'}) ."\n";
	}
	return $ret;
};

$command_ref{qr/^\!seen/} = sub {
	my $msg = $ARG[0];
	my $mention = $msg->{'mentions'}[0];
	if (!$mention) { return "Please include target. Usage !seen \@user."; }
	my $dbh = DBI->connect("dbi:SQLite:dbname=$usrdb");
	my $sth = $dbh->prepare("SELECT * FROM users WHERE id = (?);");
	$sth->execute($mention->{'id'});
	my @usr = $sth->fetchrow_array;
	$sth->finish;
	if (!@usr) { return "**$mention->{'username'}** has not been registered with the server."; }
	my $n = length($usr[3]);
	my $last_message = substr($usr[3], 11, ($n-1));
	print $last_message."\n";
	my $time_message = localtime(substr($usr[3], 0, 10));
	my $joined = localtime($usr[4]);
	$dbh->disconnect;
	return ">>> **Username:**\t$mention->{'username'}\n**Personality:**\t$usr[2]\n**Joined:**\t$joined\n**Last Message Sent:**\n\t$time_message: \t*$last_message*";
};

$command_ref{qr/^\!opt-out$/} = sub {
	my $user = $ARG[0]->{'author'}{'id'};
	my $dbh = DBI->connect("dbi:SQLite:dbname=$usrdb");
	my $sth = $dbh->prepare("SELECT * FROM users WHERE id = (?);");
	$sth->execute($user);
	if ($sth->fetchrow_array) {
		$sth->finish;
		$sth = $dbh->prepare("UPDATE users SET personality = 'N/A' WHERE id = (?);");
		$sth->execute($user);
	} else {
		$sth->finish;
		$sth = $dbh->prepare("INSERT INTO users VALUES(?, ?, ?, ?, ?);");
		$sth->execute($user, $ARG[0]->{'author'}{'username'}, 'N/A', time().":!opt-out", time());
	}
	$sth->finish;
	$dbh->disconnect;
	return "**$ARG[0]->{'author'}{'username'}** has opted out of all data mining on server.";
};

$command_ref{qr/^\!man$/} = sub {
	return qq[>>> 
**!opt-out:**\tuser opts out of all data-mining done by this bot.\n**Usage:**\t!opt-out\n\
**!insult:**\tEliza Bot insults every user listed.\n**Usage:**\t!insult \@pentashift\n\
**!seen:**\tEliza Bot returns information on any user that has sent a message within the server.\n**Usage:**\t!seen \@pentashift\n];
};

my $re = qr/.+/;
tie %{$bot->{'commands'}}, 'Tie::RegexpHash';
$bot->add_commands(
	# Wildcard match using regex
	# for some reason trying to match anything more specific doesn't work?
	 $re => sub {
		my ($bot, $args, $msg, $channel, $guild) = @_;
		my $message = $msg->{'content'};
		# Message is a command.
		if (substr($message, 0, 1) eq '!') {
			if ($command_ref{$message}) { $bot->say($channel->{id}, &{$command_ref{$message}}($msg)); } 
			else { $bot->say($channel->{'id'}, "Command not recognized: $message"); }	
		# Shell command, run only if Owner.
		} elsif (substr($message, 0, 2) eq '#!') {
			my $dbh = DBI->connect("dbi:SQLite:dbname=$usrdb");
			my $sth = $dbh->prepare("SELECT rank FROM users WHERE id = (?);");
			$sth->execute($msg->{'author'}{'id'});
			my @role = $sth->fetchrow_array;
			$sth->finish;
			if (defined $role[0] && $role[0] eq 'Owner') { 
				my $n = length($msg->{'content'});
				my $bsh = substr($msg->{'content'}, 2, $n-1);
				print "$bsh\n";
				my $exe = qx/$bsh/;
				print $exe;
				$bot->say($channel->{'id'}, "```\n$exe\n```");
			}
			$dbh->disconnect;
		# Normal Message, run sentiment analysis.
		} else { 
			sentiment_analysis($msg);
		}
	}
);

$bot->connect;
AnyEvent->condvar->recv;
