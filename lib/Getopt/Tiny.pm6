use v6;
unit class Getopt::Tiny;

use Pod::To::Text;

my class X::Usage is Exception {
    has $.message;
    method new(Str $message) {
        self.bless(message => $message)
    }
}

my class IntOption {
    has $.short;
    has $.long;
    has $.callback;

    method usage() {
        if $.short.defined {
            return "-{$.short}=Int"
        }
        if $.long.defined {
            return "--{$.long}=Int"
        }
        return '';
    }

    method match($a) {
        if $.short.defined {
            return True if self!match-short($a);
        }
        if $.long.defined {
            return True if self!match-long($a);
        }
        return False;
    }

    method !match-long($a) {
        my $opt = $.long;

        my $val = do {
            if $a[0] eq "--$opt" {
                $a.shift;
                if $a.elems == 0 {
                    X::Usage.new("--$opt requires integer parameter").throw;
                }
                $a.shift;
            } elsif $a[0] ~~ /^\-\-$opt\=(.*)$/ { # -h=3
                my $val = $/[0].Str;
                $a.shift;
                $val;
            } else {
                return False;
            }
        };

        unless $val ~~ /^<[0..9]>+$/ {
            X::Usage.new("-$opt requires int parameter, but got $val").throw;
        }
        $.callback($val.Int);
        True
    }

    method !match-short($a) {
        my $opt = $.short;

        my $val = do {
            if $a[0] eq "-$opt" {
                $a.shift;
                if $a.elems == 0 {
                    X::Usage.new("-$opt requires int parameter").throw;
                }
                $a.shift;
            } elsif $a[0] ~~ /^\-$opt(.*)$/ { # -h=3
                my $val = $/[0].Str;
                $a.shift;
                $val;
            } else {
                return False;
            }
        };

        unless $val ~~ /^<[0..9]>+$/ {
            X::Usage.new("-$opt requires int parameter, but got $val").throw;
        }
        my $cb = $.callback; # this assign is workaround for perl6 bug
        $cb($val.Int);
        True
    }
}

my class StrOption {
    has $.short;
    has $.long;
    has $.callback;

    method usage() {
        if $.short.defined {
            return "-{$.short}=Str"
        }
        if $.long.defined {
            return "--{$.long}=Str"
        }
        return '';
    }

    method match($a) {
        if $.short.defined {
            return True if self!match-short($a);
        }
        if $.long.defined {
            return True if self!match-long($a);
        }
        return False;
    }

    method !match-long($a) {
        my $opt = $.long;

        my $val = do {
            if $a[0] eq "--$opt" {
                $a.shift;
                if $a.elems == 0 {
                    X::Usage.new("--$opt requires string parameter").throw;
                }
                $a.shift;
            } elsif $a[0] ~~ /^\-\-$opt\=(.*)$/ { # -h=3
                my $val = $/[0].Str;
                $a.shift;
                $val;
            } else {
                return False;
            }
        };

        my $cb = $.callback;
        $cb($val);
        True
    }

    method !match-short($a) {
        my $opt = $.short;

        my $val = do {
            if $a[0] eq "-$opt" {
                $a.shift;
                if $a.elems == 0 {
                    X::Usage.new("-$opt requires string parameter").throw;
                }
                $a.shift;
            } elsif $a[0] ~~ /^\-$opt(.*)$/ { # -h=3
                my $val = $/[0].Str;
                $a.shift;
                $val;
            } else {
                return False;
            }
        };

        my $cb = $.callback; # this assign is workaround for perl6 bug
        $cb($val);
        True
    }
}

my class BoolOption {
    has $.short;
    has $.long;
    has $.callback;

    method usage() {
        if $.short.defined {
            return "-{$.short}"
        }
        if $.long.defined {
            return "--{$.long}"
        }
        return '';
    }

    method match($a) {
        if $.short.defined {
            return True if self!match-short($a);
        }
        if $.long.defined {
            return True if self!match-long($a);
        }
        return False;
    }

    method !match-long($a) {
        my $opt = $.long;
        my $cb = $.callback;

        if $a[0] eq "--$opt" {
            $a.shift;
            $cb(True);
            False;
        } elsif $a[0] eq "--no-$opt" {
            $a.shift;
            $cb(False);
            False;
        } else {
            return False;
        }
    }

    method !match-short($a) {
        my $opt = $.short;
        my $cb = $.callback; # workaround

        if $a[0] eq "-$opt" {
            $a.shift;
            $cb(True);
            True
        } else {
            return False;
        }
    }
}

has $!options = [];

multi method str(Str $opt, $callback) {
    my $type = $opt.chars == 1 ?? 'short' !! 'long';
    $!options.append: StrOption.new(
        |($type    => $opt),
        callback => $callback,
    );
    self;
}

multi method str($short, $long, $callback) {
    $!options.append: StrOption.new(
        short    => $short,
        long     => $long,
        callback => $callback,
    );
    self;
}

multi method bool(Str $opt, $callback) {
    my $type = $opt.chars == 1 ?? 'short' !! 'long';
    $!options.append: BoolOption.new(
        |($type    => $opt),
        callback => $callback,
    );
    self;
}

multi method bool($short, $long, $callback) {
    $!options.append: BoolOption.new(
        short    => $short,
        long     => $long,
        callback => $callback,
    );
    self;
}

multi method int(Str $opt, $callback) {
    my $type = $opt.chars == 1 ?? 'short' !! 'long';
    $!options.append: IntOption.new(
        |($type    => $opt),
        callback => $callback,
    );
    self;
}

multi method int($short, $long, $callback) {
    if $short.defined {
        $!options.append: IntOption.new(
            short    => $short,
            callback => $callback,
        );
    }
    if $long.defined {
        $!options.append: IntOption.new(
            long     => $long,
            callback => $callback,
        );
    }
    self;
}

my sub pod2usage($pod) {
    given $pod {
        when Pod::Block::Named {
            for 0..^$pod.contents.elems-1 -> $i {
                if $pod.contents[$i] ~~ Pod::Heading && pod2text($pod.contents[$i].contents) eq 'SYNOPSIS' {
                    return pod2text($pod.contents[$i+1]);
                }
            }
        }
        when Array {
            for @$_ {
                my $got = pod2usage($_);
                return $got if $got;
            }
        }
    }
}

method print-usage(Str $msg='') {
    say "$msg\n" if $msg;

    my $pod = callframe(callframe().level).my<$=pod>;
    my $usage = pod2usage($pod);
    if $usage {
        say "\nUsage:\n$usage\n";
        exit 1;
    }

    my $prog-name = $*PROGRAM-NAME eq '-e'
        ?? '-e "..."'
        !! $*PROGRAM-NAME;

    # I want to show more verbose usage message. patches welcome.
    say("Usage; $prog-name " ~ @$!options.map({ .usage }).join(" "));

    exit 1
}

method parse($args is copy) {
    my @positional;

    LOOP: while +@$args {
        if $args[0] eq '--' {
            $args.shift;
            @positional.append: @$args;
            last;
        }

        for @$!options -> $opt {
            if $opt.match($args) {
                next LOOP
            }
        }
        CATCH {
            when X::Usage {
                self.print-usage($_.message);
            }
        }

        if $args[0] eq '-h' || $args[0] eq '--help' {
            self.print-usage();
        }

        @positional.push: $args.shift;
    }

    $PROCESS::ARGFILES = IO::ArgFiles.new(:args(@positional));

    return @positional;
}

=begin pod

=head1 NAME

Getopt::Tiny - blah blah blah

=head1 SYNOPSIS

  use Getopt::Tiny;

=head1 DESCRIPTION

Getopt::Tiny is ...

=head1 COPYRIGHT AND LICENSE

Copyright 2015 Tokuhiro Matsuno <tokuhirom@gmail.com>

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
