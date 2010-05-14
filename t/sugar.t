use strict;
use warnings;
use Test::More qw/no_plan/;
use Moose::Util::TypeConstraints;
use MooseX::DFV;
use Data::Dumper;

my $testform = profile (
    required => [qw/test_int test_int2 less_than_four less_than_five/],
    constraints => {
        test_int => {
            type => 'Int',
            name => 'Test Integer',
        },
        test_int2 => {
            type => 'Int',
            name => 'Test Integer2',
        },
        less_than_four => {
            name => 'An int less than four',
            type => subtype 'LessThanFour'
                     => as 'Int'
                     => where { $_ < 4 }
        },
        less_than_five => {
            name => 'An int less than five',
            type => subtype as 'Int'
                     => where { $_ < 5 }
        }
    }
);


my $params = { test_int => '20', test_int2 => 'twenty', less_than_four => 3, less_than_five => 4};

my $result = validate $params, against => $testform;

ok($result->valid('test_int'), 'built in types');
ok($result->invalid('test_int2'), 'built in types');
ok($result->valid('less_than_four'), 'bui');
ok($result->valid('less_than_five'), 'bui');
