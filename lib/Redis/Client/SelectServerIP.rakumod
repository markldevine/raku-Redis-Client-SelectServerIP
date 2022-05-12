unit    class Redis::Client::SelectServerIP:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use     Redis;

has     $.port = 6379;
has     @.redis-server-bound-ifs = <127.0.0.1 10.10.105.96 10.11.105.96>;
has     $.connection;

submethod TWEAK {
    my $connection;
    for self.redis-server-bound-ifs -> $bif {
        if try $connection = Redis.new($bif ~ ':' ~ self.port, decode_response => True) {
            $!connection = $connection;
            last;
        }
    }
    die 'No Redis servers available!' without $!connection;
}

=finish

my $redis = Redis::Client::SelectServerIP.new.connection;
.say for $redis.smembers('fg:st:lc:tst').list.sort({ $^a.fc cmp $^b.fc });


subset CSpec where * ~~ List|Array|Async::Command;

has UInt    $.batch is rw = 16;
has CSpec   %.command is required;
has Promise @!promises;
has Real    $.default-time-out is DEPRECATED("'time-out'") = 0.0;
has Real    $.time-out where $_ >= 0.0;
has Real    $.delay where $_ >= 0.0 = 0.0,
has UInt    $.attempts where $_ >= 1   = 1;
has         %!result;
has Promise $!master-promise;

submethod TWEAK {
    without $!time-out {
        if $!default-time-out > 0.0 {
            $!time-out = $!default-time-out without $!time-out;
        }
        $!time-out = 0.0 without $!time-out;
    }
}

method sow () {
    $!master-promise = start {
        for %!command.keys -> $unique-id {
            if %!command{$unique-id}.WHAT ~~ Async::Command {
                %!command{$unique-id}.unique-id = $unique-id without %!command{$unique-id}.unique-id;
                push @!promises, start %!command{$unique-id}.run(:time-out($!time-out), :$!delay, :$!attempts);
            }
            else {
                my Async::Command $cmd .= new(:command(|%!command{$unique-id}), :$unique-id, :$!time-out);
                push @!promises, start $cmd.run(:$!delay, :$!attempts);
            }
            if @!promises == $!batch {
                my @reorg-promises;
                await Promise.anyof(@!promises);
                for @!promises -> $promise {
                    if $promise.status ~~ /^Kept$/ {
                        %!result{$promise.result.unique-id} = $promise.result;
                    }
                    else {
                        @reorg-promises.append: $promise;
                    }
                }
                @!promises = @reorg-promises;
            }
        }
        my @results = await @!promises;
        for @results -> $result {
            %!result{$result.unique-id} = $result;
        }
    }
    self;
}

method reap () {
    await $!master-promise;
    return %!result;
}

=finish
