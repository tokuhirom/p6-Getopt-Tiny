use v6;
unit class Getopt::Tiny;

has $!matcher = [];

method !long($opt, $type-name, $re, $callback, $coerece) {
    my sub call($val is rw) {
        if $re.defined {
            unless $val ~~ $re {
                self.usage("--$opt requires $type-name parameter, but got $val");
            }
        }
        if $coerece.defined {
            $val = $coerece($val);
        }
        $callback($val);
        True
    };
    $!matcher.append: -> $a {
        if $a[0] eq "--$opt" {
            $a.shift;
            if $a.elems == 0 {
                self.usage("--$opt requires $type-name parameter");
            }
            call($a.shift);
        } elsif $a[0] ~~ /^\-\-$opt\=(.*)$/ { # -h=3
            my $val = $/[0].Str;
            $a.shift;
            call($val);
        } else {
            False;
        }
    };
}

method !short($opt, $type-name, $re, $callback, $coerece) {
    my sub call($val is rw) {
        if $re.defined {
            unless $val ~~ $re {
                self.usage("-$opt requires $type-name parameter, but got $val");
            }
        }
        if $coerece.defined {
            $val = $coerece($val);
        }
        $callback($val);
        True
    };
    $!matcher.append: -> $a {
        if $a[0] eq "-$opt" {
            $a.shift;
            if $a.elems == 0 {
                self.usage("-$opt requires $type-name parameter");
            }
            call($a.shift);
        } elsif $a[0] ~~ /^\-$opt(.*)$/ { # -h=3
            my $val = $/[0].Str;
            $a.shift;
            call($val);
        } else {
            False;
        }
    };
}

multi method str(Str $opt, $callback) {
    if $opt.chars == 1 {
        self.str($opt, Nil, $callback);
    } else {
        self.str(Nil, $opt, $callback);
    }
    self;
}

multi method str($short, $long, $callback) {
    self!short($short, 'str', Nil, $callback, Nil) if $short;
    self!long($long, 'str', Nil, $callback, Nil) if $long;
    self;
}

multi method int(Str $opt, $callback) {
    if $opt.elems == 1 {
        self.int($opt, Nil, $callback);
    } else {
        self.int(Nil, $opt, $callback);
    }
    self;
}

multi method int($short, $long, $callback) {
    self!short($short, 'int', rx/^<[0..9]>+$/, $callback, -> $v { $v.Int }) if $short;
    self!long($long, 'int', rx/^<[0..9]>+$/, $callback, -> $v { $v.Int }) if $long;
    self;
}

method usage(Str $msg='') {
    # TODO: auto gen
    say $msg if $msg;

    say q:to:c/EOF/;

        crustup -e 'sub ($env) { 200, [], ['OK'] }'
        crustup app.psgi

        OPTIONS:

            --port={PORT}
            --host={HOST}
            -Ilib

    EOF

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
        if $args[0] eq '-h' || $args[0] eq '--help' {
            self.usage();
            exit 1;
        }

        for @$!matcher -> $matcher {
            if $matcher($args) {
                next LOOP
            }
        }

        @positional.push: $args.shift;
    }

    # $PROCESS::ARGFILES = IO::ArgFiles.new(:args($args));

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
