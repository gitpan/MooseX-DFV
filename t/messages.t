use strict;
use warnings;
use Test::More qw/no_plan/;
use Moose::Util::TypeConstraints;
use Data::Dumper;
use_ok('MooseX::DFV');

my $results = MooseX::DFV->check({ test_int => '20', test_int2 => 'twenty', test_int3=>'ff' },
    {   required => [qw/test_int test_int2 test_int3/],
        constraints => {
            test_int => {
                type => subtype as 'Int' => where { $_ > 0 }
            },
            test_int2 => {
                type => subtype 'PositiveInt' => as 'Int' => where { $_ > 0 } => message sub{"custom message"}
            },
            test_int3 => {
                type => 'Int',
            }
        },
    });

ok(defined $results);

ok ( !$results->has_missing, 'no missing');

# Print the name of invalid fields
if (ok($results->has_invalid)) {
    my @invalid =  $results->invalid;
        my $r = $results->invalid($invalid[0]);
		is($r->[0], 'invalid value for an integer');

        $r = $results->invalid($invalid[1]);
		is($r->[0], 'custom message');
}

ok(!$results->has_unknown, 'no unknown');

my ($field) = $results->valid();
is ($field, 'test_int');

