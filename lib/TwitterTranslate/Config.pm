package TwitterTranslate::Config;
use strict;
use warnings;
use File::Spec;
use Carp ();

sub load {
    my $fname = File::Spec->catfile('.', 'config.pl');
    my $config = do $fname;
    Carp::croak("$fname: $@") if $@;
    Carp::croak("$fname: $!") unless defined $config;
    unless ( ref($config) eq 'HASH' ) {
        Carp::croak("$fname does not return HashRef.");
    }
    return $config;
}

1;
