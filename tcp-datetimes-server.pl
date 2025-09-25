#!/usr/bin/perl
use strict;
use warnings;
use IO::Socket::INET;
use POSIX qw(strftime);

# Autoflush for socket
$| = 1;

# Create TCP server socket
my $server = IO::Socket::INET->new(
    LocalPort => 5000,
    Type      => SOCK_STREAM,
    Reuse     => 1,
    Listen    => 5
) or die "Could not create server socket: $!\n";

print "Server listening on port 5000...\n";

while (1) {
    # Accept incoming client connection
    my $client_socket = $server->accept();
    print "Client connected...\n";

    # Fork a child process to handle the client
    my $pid = fork();
    if (!defined $pid) {
        warn "Failed to fork: $!";
        next;
    }

    if ($pid == 0) {
        # Child process
        close $server;  # Child doesn't need the listening socket

        while (1) {
            my $datetime = strftime("%Y-%m-%d %H:%M:%S", localtime);
            print $client_socket "$datetime\n";

            # Check if client is still connected
            my $test = syswrite($client_socket, "");
            last unless defined $test;

            sleep 1;
        }

        print "Client disconnected.\n";
        close $client_socket;
        exit(0);
    } else {
        # Parent process
        close $client_socket;  # Parent doesn't need this socket
    }
}
