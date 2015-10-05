use v6;

use Test;
use Getopt::Tiny;

subtest {
    my $opts;
    get-options(
        $opts,
        <I=s@>,
        ['-Ilib', '-I', 't/lib']
    );
    is-deeply $opts, {I => ['lib', 't/lib']};
}, 'short-str-array';

subtest {
    my $opts;
    get-options(
        $opts,
        <p|port=i>,
        ['-p3']
    );
    is-deeply $opts, {:p(3)};
}, 'short-int-array';

done-testing;
