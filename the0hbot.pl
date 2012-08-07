#!/usr/bin/perl

# Copyright (c) 2012 Joan Rieu

# CONFIG

$nick = 'the0hbot';
$addr = '';
$port = 6667;
$channel = '';
$owner_type = ''; # nickname / username / hostname
$owner = '';

# CODE

use IO::Socket;

my $sock = new IO::Socket::INET(
        PeerAddr => $addr,
        PeerPort => $port,
        Proto => 'tcp',
);

die 'Could not connect!' unless $sock;

print $sock "NICK $nick \r\n";
print $sock "USER $nick 0 * :$nick\r\n";

while (<$sock>) {

        print "----\n   Full: $_\n";

        undef $prefix;
        if ($_ =~ s/^:([^ ]+) //) {
                $prefix = $1;
                print " Prefix: $prefix\n";
        }

        $_ =~ s/\r?\n$//;

        $_ =~ m/^([^ ]+)( (.+))?$/;
        $command = $1;
        $params = $3;

        print "Command: $command\n Params: $params\n";

        if ($command eq 'PING') {
                print $sock "PONG $params\r\n";
        } elsif ($command eq '001') {
                print $sock "JOIN $channel\r\n";
                $joined = 1;
        } elsif ($command eq 'PRIVMSG') {

                $params =~ m/^([^ ]+) :(.+)$/;
                $channel = $1;
                $text = $2;

                $prefix =~ m/^([^!]+)!([^@]+)@(.+)$/;
                %sender = ('nickname', $1, 'username', $2, 'hostname', $3);

                if ($text =~ m/^\.0 ([^ ]+)( (.+))?$/) {

                        $usercommand = $1;
                        $userparams = $3;

                        if ($usercommand eq 'echo') {
                                print $sock "PRIVMSG $channel :$sender{'nickname'} said: $userparams\r\n";
                        } elsif ($usercommand eq 'bye' and $sender{$owner_type} eq $owner) {
                                if (defined $userparams) {
                                        print $sock "QUIT :$userparams\r\n";
                                } else {
                                        print $sock "QUIT\r\n";
                                }
                                $sock->close();
                                exit;
                        } elsif ($usercommand eq 'bye') {
                                print $sock "PRIVMSG $channel :$sender{'nickname'}: Can't touch this!\r\n";
                        }

                }

        }

}

close($sock);

die "Socket error!";
