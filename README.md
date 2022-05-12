[Redis::Client::SelectServerIP](https://github.com/markldevine/raku-Redis-Client-SelectServerIP/README.md)
================
From a list of Redis IPs, establish a connection.

SYNOPSIS
========

    my $redis = Redis::Client::SelectServerIP.new.connection;
    .say for $redis.smembers('fg:st:lc:tst').list.sort({ $^a.fc cmp $^b.fc });

AUTHOR
======
Mark Devine <mark@markdevine.com>
