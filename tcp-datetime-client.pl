#!/usr/bin/perl
use strict;
use warnings;
use IO::Socket::INET;
use IO::Select;

# Read host and port from command-line
my ($server_host, $server_port) = @ARGV;

unless ($server_host && $server_port =~ /^\d+$/) {
    die "Usage: $0 <host> <port>\nExample: $0 127.0.0.1 5000\n";
}

my $retry_delay = 3;       # Seconds between retries
my $read_timeout = 10;     # Seconds to wait for server data
my $log_file = "tcp_client_log.txt";

open my $logfh, '>>', $log_file or die "Cannot open log file: $!\n";
$logfh->autoflush(1);

while (1) {
    print "Attempting to connect to $server_host:$server_port...\n";

    my $socket = IO::Socket::INET->new(
        PeerHost => $server_host,
        PeerPort => $server_port,
        Proto    => 'tcp',
        Timeout  => 5
    );

    if (!$socket) {
        my $err_msg;
        if ($! =~ /timed out/i) {
            $err_msg = "Connection attempt timed out.";
        } elsif ($! =~ /refused/i) {
            $err_msg = "Connection refused by server.";
        } else {
            $err_msg = "Connection failed: $!";
        }
        print "$err_msg Retrying in $retry_delay seconds...\n";
        print $logfh "$err_msg\n";
        sleep($retry_delay);
        next;
    }

    print "Connected to server.\n";
    print $logfh "Connected to $server_host:$server_port\n";

    my $selector = IO::Select->new($socket);

    while (1) {
        if ($selector->can_read($read_timeout)) {
            my $line = <$socket>;
            unless (defined $line) {
                print "Server closed connection.\n";
                print $logfh "Server closed connection.\n";
                last;
            }
            chomp $line;
            print "Received: $line\n";
            print $logfh "$line\n";
        } else {
            print "Read timeout: no data from server in $read_timeout seconds.\n";
            print $logfh "Read timeout: no data from server.\n";
            last;
        }
    }

    print "Disconnected. Reconnecting in $retry_delay seconds...\n";
    print $logfh "Disconnected from server.\n";
    close $socket;
    sleep($retry_delay);
}

close $logfh;