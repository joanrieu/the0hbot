#!/usr/bin/perl

# CONFIG

my $nick = "the0hbot";
my $addr = "localhost";
my $port = 6667;

# CODE

use IO::Socket;

my $sock = new IO::Socket::INET(
        PeerAddr => $addr,
        PeerPort => $port,
        Proto => 'tcp',
);

die "Could not connect!" unless $sock;

my $state = AUTH;

my $data;

while ($state ne QUIT) {

        while ($state ne IDLE) {
                if ($state eq AUTH) {
                        print $sock "NICK $nick \r\n";
                        print $sock "USER $nick 0 * :$nick\r\n";
                        $state = IDLE;
                } elsif ($state eq PONG) {
                        print $sock "PONG $data\r\n";
                        $state = IDLE;
                }
        }

        die "Socket error!" unless $data = <$sock>;

        $data =~ s/^:[^ ]+ //;
        $data =~ s/\r?\n$//;

        $data =~ m/^([^ ]+)( (.+))?$/;
        my $command = $1;
        $data = $3;

        print "Command: $command\n Params: $data\n";

        if ($command eq "PING") {
                $state = PONG;
        }

}

close($sock);
