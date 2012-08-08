#!/usr/bin/perl

# Copyright (c) 2012 Joan Rieu

# CONFIG

$bot_nickname = 'the0hbot';
$server_address = '';
$server_port = 6667;
$server_channel = '';
$owner_type = ''; # nickname / username / hostname
$owner_name = '';
$enemy_nickname = '';

# CODE

use IO::Socket;
use IPC::Cmd qw(run);
use Safe;

my $server_socket = new IO::Socket::INET(
        PeerAddr => $server_address,
        PeerPort => $server_port,
        Proto => 'tcp',
);

die 'Could not connect!' unless $server_socket;

$\ = "\r\n";

print $server_socket "NICK $bot_nickname";
print $server_socket "USER $bot_nickname 0 * :$bot_nickname";

while (<$server_socket>) {

        undef $command_prefix;
        if ($_ =~ s/^:([^ ]+) //) {
                $command_prefix = $1;
                $command_prefix =~ m/^([^!]+)!([^@]+)@(.+)$/;
                %command_sender = ('nickname', $1, 'username', $2, 'hostname', $3);
        }

        $_ =~ m/^([^ ]+)( ([^\r]+))\r?\n$/;
        $command_name = $1;
        $command_parameters = $3;

        if ($command_name eq 'PING') {
                print $server_socket "PONG $command_parameters";
        } elsif ($command_name eq '001') {
                print $server_socket "JOIN $server_channel";
        } elsif ($command_name eq 'PRIVMSG') {

                $command_parameters =~ m/^([^ ]+) :(.+)$/;
                $command_channel = $1;
                $command_channel = $command_sender{'nickname'} if $command_channel eq $bot_nickname;
                $command_text = $2;

                if ($command_text =~ m/^\.0 ([^ ]+)( (.+))?$/) {

                        $usercommand_name = $1;
                        $usercommand_parameters = $3;

                        if ($usercommand_name eq 'echo' and defined $usercommand_parameters) {

                                print $server_socket "PRIVMSG $command_channel :$command_sender{'nickname'} said: $usercommand_parameters";

                        } elsif ($usercommand_name eq 'whoami') {

                                print $server_socket "PRIVMSG $command_channel :$command_sender{'nickname'}: You are $command_sender{'username'} ($command_sender{'hostname'}).";

                        } elsif ($usercommand_name eq 'uname') {

                                run(
                                        command => "uname -a",
                                        verbose => 0,
                                        buffer => \$usercommand_reply
                                );

                                print $server_socket "PRIVMSG $command_channel :$command_sender{'nickname'}: $usercommand_reply";

                        } elsif ($usercommand_name eq 'eval') {

                                $usercommand_reply = (new Safe)->reval($usercommand_parameters);
                                $usercommand_reply =~ s/\r?\n/ /g;
                                print $server_socket "PRIVMSG $command_channel :$command_sender{'nickname'}: $usercommand_reply";

                        } elsif ($usercommand_name =~ m/^bye|restart$/) {

                                if ($command_sender{$owner_type} eq $owner_name) {
                                        $usercommand_reply = 'QUIT';
                                        $usercommand_reply .= " :$usercommand_parameters" unless not defined $usercommand_parameters;
                                        print $server_socket $usercommand_reply;
                                        $server_socket->close();
                                        if ($usercommand_name eq 'restart') {
                                                exec($0);
                                        }
                                        exit;
                                } else {
                                        print $server_socket "PRIVMSG $command_channel :$command_sender{'nickname'}: Can't touch this!";
                                }

                        }

                } elsif ($command_text =~ m/^\01ACTION kicks $bot_nickname(.*)\01$/i) {

                        $suffix = $1;

                        print $server_socket "NICK hammer";
                        print $server_socket "PRIVMSG $command_channel :\01ACTION nails $command_sender{'nickname'}$suffix\01";
                        print $server_socket "NICK $bot_nickname";

                }

        }

        if ($command_sender{'nickname'} eq $enemy_nickname) {

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

                print $server_socket "PRIVMSG $server_channel :\01ACTION $verb $enemy_nickname, $ending!\01";

        }

}

close($server_socket);
die "Socket error!";
