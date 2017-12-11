#!perl -T

use strict;
use warnings;

use Test::More;
use lib 't';
use Util;

prep_environment();

my @tests = (
    [ qw/Sue/ ],
    [ qw/boy -i/ ], # case-insensitive is handled correctly with --match
    [ qw/ll+ -Q/ ], # quotemeta        is handled correctly with --match
    [ qw/gon -w/ ], # words            is handled correctly with --match
);

plan tests => @tests + 2;

test_match( @{$_} ) for @tests;

# Giving only the --match argument (and no other args) should not result in an error.
run_ack( '--match', 'Sue' );

subtest 'Not giving a regex when piping into ack should result in an error' => sub {
    plan tests => 3;

    # Not giving a regex when piping into ack should result in an error.
    my ($stdout, $stderr) = pipe_into_ack_with_stderr( 't/text/amontillado.txt', '--perl' );
    isnt( get_rc(), 0, 'ack should return an error when piped into without a regex' );
    is_empty_array( $stdout, 'ack should return no STDOUT when piped into without a regex' );
    is( scalar @{$stderr}, 1, 'ack should return one line of error message when piped into without a regex' ) or diag(explain($stderr));
};

done_testing();

exit 0;

# Call ack normally and compare output to calling with --match regex.
#
# Due to 2 calls to run_ack, this sub runs altogether 3 tests.
sub test_match {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $regex = shift;
    my @args  = @_;
    push @args, '--sort-files';

    return subtest "test_match( @args )" => sub {
        my @files = ( 't/text' );
        my @results_normal = run_ack( @args, $regex, @files );
        my @results_match  = run_ack( @args, @files, '--match', $regex );

        return sets_match( \@results_normal, \@results_match, "Same output for regex '$regex'." );
    };
}
