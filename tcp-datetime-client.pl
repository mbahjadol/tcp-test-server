#!/usr/bin/perl
use strict;
use warnings;
use IO::Socket::INET;
use POSIX qw(strftime);
use Time::HiRes qw(sleep);

# Server configuration
my $server_host = 'container-a';  # Change to server IP if needed
my $server_port = 5000;
my $retry_delay = 3;            # Seconds between retries

# Loop to keep retrying connection
while (1) {
    print "Attempting to connect to $server_host:$server_port...\n";

    my $socket = IO::Socket::INET->new(
        PeerHost => $server_host,
        PeerPort => $server_port,
        Proto    => 'tcp',
        Timeout  => 5
    );

    if (!$socket) {
        if ($! =~ /timed out/i) {
            print "Connection attempt timed out. Retrying in $retry_delay seconds...\n";
        } elsif ($! =~ /refused/i) {
            print "Connection refused by server. Retrying in $retry_delay seconds...\n";
        } else {
            print "Connection failed: $!. Retrying in $retry_delay seconds...\n";
        }
        sleep($retry_delay);
        next;
    }

    print "Connected to server.\n";

    # Read data from server
    while (my $line = <$socket>) {
        chomp $line;
        print "Received: $line\n";
    }

    print "Disconnected from server. Reconnecting in $retry_delay seconds...\n";
    close $socket;
    sleep($retry_delay);
}