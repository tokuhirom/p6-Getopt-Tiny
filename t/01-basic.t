use v6;
use Test;
use Getopt::Tiny;

subtest {
    my @i;
    my @args = '-Ilib', '-I', 'blib/lib', 'a', 'b', 'c';
    my @positional = Getopt::Tiny.new()
        .str('I', -> $v { @i.push: $v })
        .parse(@args);
    is @i, <lib blib/lib>;
    is @positional, <a b c>;
}, 'string short';

subtest {
    my @i;
    my @args = '--inc=lib', '--inc', 'blib/lib', 'a', 'b', 'c';
    my @positional = Getopt::Tiny.new()
        .str(Nil, 'inc', -> $v { @i.push: $v })
        .parse(@args);
    is @i, <lib blib/lib>;
    is @positional, <a b c>;
}, 'string short';

subtest {
    my @p;
    my @args = '-p8080', '-p', '9090', 'a', 'b', 'c';
    my @positional = Getopt::Tiny.new()
        .str('p', -> $v { @p.push: $v })
        .parse(@args);
    is @p, [8080, 9090];
    is @positional, <a b c>;
}, 'int short';

subtest {
    my @p;
    my @args = '-p8080', '--', '-p', '9090', 'a', 'b', 'c';
    my @positional = Getopt::Tiny.new()
        .str('p', -> $v { @p.push: $v })
        .parse(@args);
    is @p, [8080];
    is @positional, <-p 9090 a b c>;
}, '-- stops opt parse';

done-testing;
