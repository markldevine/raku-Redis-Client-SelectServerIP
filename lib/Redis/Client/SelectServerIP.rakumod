unit    class Redis::Client::SelectServerIP:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use     Data::Dump::Tree;
use     POSIX::getaddrinfo :Get-Addr-Info-IPV4-STREAM-IPAddrs;
use     Redis;

has     $.port = 6379;
#has     @.redis-server-bound-ifs = <127.0.0.1 10.10.105.96 10.11.105.96>;
has     @.redis-server-bound-ifs = <localhost jgstmgtgate1lpv.wmata.local ctstmgtgate1lpv.wmata.local>;
has     $.connection;

submethod TWEAK {
    my $connection;
    for self.redis-server-bound-ifs <-> $bif {
        if $bif ~~ /^<alpha>/ {
            note 'Unable to resolve IP label <' ~ $bif ~ '>' unless my $ipaddr = Get-Addr-Info-IPV4-STREAM-IPAddrs($bif)[0];
            $bif = $ipaddr;
        }
        if try $connection = Redis.new($bif ~ ':' ~ self.port, decode_response => True) {
            $!connection = $connection;
            last;
        }
    }
    die 'No Redis servers available!' without $!connection;
}

=finish
