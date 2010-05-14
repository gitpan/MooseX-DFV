use strict;
use warnings;
use Test::More qw/no_plan/;
use Moose::Util::TypeConstraints;
use_ok('MooseX::DFV');


my $result = MooseX::DFV->check({ test_int => '20', test_int2 => 'twenty' },
    {   required => [qw/test_int test_int2/],
        constraints => {
            test_int => {
                name => 'Test Integer',
                type => subtype as 'Int' => where { $_ > 0 }
            },
            test_int2 => {
                name => 'Test Integer2',
                type => subtype 'PositiveInt' => as 'Int' => where { $_ > 0 }
            }
        },
    });

ok($result->valid('test_int'), 'built in types');
ok($result->invalid('test_int2'), 'built in types');

