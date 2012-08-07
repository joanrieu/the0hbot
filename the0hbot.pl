#!/usr/bin/perl

# CONFIG

my $nick = "the0hbot";
my $addr = "irc.afternet.org";
my $port = 6667;
my $channel = "#bottest";

# CODE

use IO::Socket;

my $sock = new IO::Socket::INET(
        PeerAddr => $addr,
        PeerPort => $port,
        Proto => 'tcp',
);

die "Could not connect!" unless $sock;

print $sock "NICK $nick \r\n";
print $sock "USER $nick 0 * :$nick\r\n";

while (<$sock>) {

        print "----\n   Full: $_\n";

        my $prefix = "";
        if ($_ =~ s/^:([^ ]+) //) {
                $prefix = $1;
                print " Prefix: $prefix\n";
        }

        $_ =~ s/\r?\n$//;

        $_ =~ m/^([^ ]+)( (.+))?$/;
        my $command = $1;
        my $params = $3;

        print "Command: $command\n Params: $params\n";

        if ($command eq "PING") {
                print $sock "PONG $params\r\n";
        } elsif ($command eq "001") {
                print $sock "JOIN $channel\r\n";
                $joined = 1;
        } elsif ($command eq "PRIVMSG") {
                $params =~ m/^([^ ]+) :(.+)$/;
                my $channel = $1;
                my $text = $2;
                $prefix =~ m/^([^!]+)!([^@]+)@(.+)$/;
                my %sender = ("nickname", $1, "username", $2, "hostname", $3);
                print $sock "PRIVMSG $channel :$sender{'nickname'} said: $text\r\n"
        }

}

close($sock);

die "Socket error!";
