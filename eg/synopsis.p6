use v6;

use Getopt::Tiny;

my Str $e;
my Str $host = '127.0.0.1';
my int $port = 5000;

my @args = Getopt::Tiny.new()
    .str('e',         -> $v { $e = $v })
    .str('I',         -> $v { @*INC.push: $v })
    .int('p', 'port', -> $v { $port = $v })
    .str('h', 'host', -> $v { $host = $v })
    .parse(@*ARGS);

@args.perl.say;
