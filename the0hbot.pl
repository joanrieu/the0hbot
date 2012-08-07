#!/usr/bin/perl

# Copyright (c) 2012 Joan Rieu

# CONFIG

$nick = 'the0hbot';
$addr = '';
$port = 6667;
$channel = '';
$owner_type = ''; # nickname / username / hostname
$owner = '';
$enemy = 'fBot';

# CODE

use IO::Socket;

my $sock = new IO::Socket::INET(
        PeerAddr => $addr,
        PeerPort => $port,
        Proto => 'tcp',
);

die 'Could not connect!' unless $sock;

$\ = "\r\n";

print $sock "NICK $nick";
print $sock "USER $nick 0 * :$nick";

while (<$sock>) {

        undef $prefix;
        if ($_ =~ s/^:([^ ]+) //) {
                $prefix = $1;
                $prefix =~ m/^([^!]+)!([^@]+)@(.+)$/;
                %sender = ('nickname', $1, 'username', $2, 'hostname', $3);
        }

        $_ =~ m/^([^ ]+)( ([^\r]+))\r?\n$/;
        $command = $1;
        $params = $3;

        if ($command eq 'PING') {
                print $sock "PONG $params";
        } elsif ($command eq '001') {
                print $sock "JOIN $channel";
                $joined = 1;
        } elsif ($command eq 'PRIVMSG') {

                $params =~ m/^([^ ]+) :(.+)$/;
                $channel = $1;
                $text = $2;

                if ($text =~ m/^\.0 ([^ ]+)( (.+))?$/) {

                        $usercommand = $1;
                        $userparams = $3;

                        if ($usercommand eq 'echo' and defined $userparams) {

                                print $sock "PRIVMSG $channel :$sender{'nickname'} said: $userparams";

                        } elsif ($usercommand eq 'whoami') {

                                print $sock "PRIVMSG $channel :$sender{'nickname'}: You are $sender{'username'} ($sender{'hostname'}).";

                        } elsif ($usercommand =~ m/^bye|restart$/) {

                                if ($sender{$owner_type} eq $owner) {
                                        $quit = 'QUIT';
                                        $quit .= " :$userparams" unless not defined $userparams;
                                        print $sock $quit;
                                        $sock->close();
                                        if ($usercommand eq 'restart') {
                                                exec($0);
                                        }
                                        exit;
                                } else {
                                        print $sock "PRIVMSG $channel :$sender{'nickname'}: Can't touch this!";
                                }

                        }

                } elsif ($text =~ m/^\01ACTION kicks $nick(.*)\01$/i) {

                        $suffix = $1;

                        print $sock "NICK hammer";
                        print $sock "PRIVMSG $channel :\01ACTION nails $sender{'nickname'}$suffix\01";
                        print $sock "NICK $nick";

                }

        }

        if ($sender{'nickname'} eq $enemy) {

                @verbs = (
                        'kicks',
                        'smashes',
                        'punches',
                        'destroys'
                );

                @endings = (
                        'it\'s super efficient',
                        'so hard it\'s gonna explode',
                        'badly',
                        'yay'
                );

                $verb = $verbs[rand() * scalar @verbs];
                $ending = $endings[rand() * scalar @endings];

                print $sock "PRIVMSG $channel :\01ACTION $verb $enemy, $ending!\01";

        }

}

close($sock);

die "Socket error!";
