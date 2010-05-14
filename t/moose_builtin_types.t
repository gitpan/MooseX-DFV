use strict;
use warnings;
use Test::More qw/no_plan/;
use_ok('MooseX::DFV');

my $result = MooseX::DFV->check({ test_int => '20', test_int2 => 'twenty' },
    {   required => [qw/test_int test_int2/],
        constraints => {
            test_int => {
                type => 'Int',
                name => 'Test Integer',
            },
            test_int2 => {
                type => 'Int',
                name => 'Test Integer2',
            }
        },
    });


ok($result->valid('test_int'), 'built in types');
ok($result->invalid('test_int2'), 'built in types');
