package MooseX::DFV;
use Moose;
use Moose::Exporter;
use MooseX::DFV::Results;
use Perl6::Junction qw(any none);
extends 'Data::FormValidator';

our $VERSION = '0.01';

Moose::Exporter->setup_import_methods(as_is=>[qw/profile validate/]);

sub profile {
    my $profile = {@_};
    __PACKAGE__->_check_profile_syntax($profile);
    return $profile;
}

sub validate (@) {
    my ($params,undef,$profile) = @_;
    unless(ref $profile eq 'HASH') {
        confess "expecting a validated profile hash";
    }
    
    return __PACKAGE__->check($params, $profile);
}

# remaining code adapted from DFV
override check => sub {
    my ( $self, $data, $name ) = @_;
    
    # check can be used as a class method for simple cases
    if (not ref $self) {
        my $class = $self;
        $self = {};
        bless $self, $class;
    }

    my $profile;
    if ( ref $name ) {
        $profile = $name;
    } else {
        $self->load_profiles;
        $profile = $self->{profiles}{$name};
        confess "No such profile $name\n" unless $profile;
    }
    confess "input profile must be a hash ref" unless ref $profile eq "HASH";

    # add in defaults from new(), if any
    if ($self->{defaults}) {
        $profile = { %{$self->{defaults}}, %$profile };
    }
    
    # check the profile syntax or die with an error. 
    $self->_check_profile_syntax($profile);

    my $results = MooseX::DFV::Results->new( $profile, $data );

    # As a special case, pass through any defaults for the 'msgs' key.
    $results->msgs($self->{defaults}->{msgs}) if $self->{defaults}->{msgs};

    return $results;
};

# check the profile syntax
override _check_profile_syntax=>sub {
    my ($self, $profile) = @_;

    (ref $profile eq 'HASH') or
        die "Invalid input profile: needs to be a hash reference\n";

    my @invalid;

    # check top level keys
    {
        my @valid_profile_keys = (qw/
            constraint_methods
            constraint_method_regexp_map
            constraint_regexp_map
            constraints
            defaults
            defaults_regexp_map
            dependencies
            dependency_groups
            field_filter_regexp_map
            field_filters
            filters
            missing_optional_valid
            msgs
            optional
            optional_regexp
            require_some
            required
            required_regexp
            untaint_all_constraints
            validator_packages
            untaint_constraint_fields
            untaint_regexp_map
            debug
        /);

        # If any of the keys in the profile are not listed as
        # valid keys here, we die with an error
        for my $key (keys %$profile) {
            push @invalid, $key unless ($key eq any(@valid_profile_keys));
        }

        local $" = ', ';
        if (@invalid) {
            die "Invalid input profile: keys not recognised [@invalid]\n";
        }
    }

    # Check that constraint_methods are always code refs or REs
    {
        # Cases:
        # 1. constraint_methods          => { field      => func() }
        # 2. constraint_methods          => { field      => [ func() ] }
        # 3. constraint_method_regex_map => { qr/^field/ => func()   }
        # 4. constraint_method_regex_map => { qr/^field/ => [ func() ] }
        # 5. constraint_methods => { field => { constraint_method => func() } }

        # Could be improved by also naming the associated key for the bad value.
        for my $key (grep { $profile->{$_} } qw/constraint_methods constraint_method_regexp_map/) {
            for my $val (map { _arrayify($_) } values %{ $profile->{$key} }) {
                if ((ref $val eq 'HASH') and ref $val->{constraint_method} eq none('CODE','Regexp'))  {
                    die "Value for constraint_method within hashref '$val->{constraint_method}' not a code reference or Regexp . Do you need func(), not 'func'?";
                }
                # Cases 1 through 4.
                elsif (ref $val eq none('HASH','CODE','Regexp')) {
                    die "Value for constraint_method '$val' not a code reference or Regexp . Do you need func(), not 'func'?";
                }
                # Case 5.
                else {
                    # We're cool. Nothing to do.
                }
            }
        }
    }

    # Check constraint hash keys
    {
        my @valid_constraint_hash_keys = (qw/
            constraint
            constraint_method
            name
            params
            type
        /);

        my @constraint_hashrefs = grep { ref $_ eq 'HASH' } values %{ $profile->{constraints} }
            if $profile->{constraints};
        push @constraint_hashrefs, grep { ref $_ eq 'HASH' } values %{ $profile->{constraint_regexp_map} }
            if $profile->{constraint_regexp_map};

        for my $href (@constraint_hashrefs) {
            for my $key (keys %$href) {
                push @invalid, $key unless ($key eq any(@valid_constraint_hash_keys));
            }
        }

        if (@invalid) {
            die "Invalid input profile: constraint hashref keys not recognised [@invalid]\n";
        }
    }

    # Check msgs keys
    {
        my @valid_msgs_hash_keys = (qw/
                prefix
                missing
                invalid
                invalid_separator
                invalid_seperator
                format
                constraints
                any_errors
        /);
        if (ref $profile->{msgs} eq 'HASH') {
            for my $key (keys %{ $profile->{msgs} }) {
                push @invalid, $key unless ($key eq any(@valid_msgs_hash_keys));
            }
        }
        if (@invalid) {
            die "Invalid input profile: msgs keys not recognized: [@invalid]\n";
        }
    }

};

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

MooseX::DFV - Data::FormValidator with Moose types and added sugar

=head1 VERSION 0.01

=head1 SYNOPSIS

  use MooseX::DFV;
  use Moose::Util::TypeConstraints;

  my $person_prof = profile (
      required => [qw/salary name/],
      constraints => {
          salary => {
              name => 'Salary',
              type =>  subtype as 'Int'
                       => where { $_ > 10000 },
          },
          name => {
             name => 'Full name',
             type => 'Str',
          },
      }
  );

  my $params = { salary => '20000', name => 'Jim Bob'};

  my $result = validate $params, against => $person_prof;


=head1 DESCRIPTION

This module allows you to use Moose type constraints with 

=head2 EXPORT

=head3 profile

Declare a new DFV profile

 my $profile = profile ( required=>[qw/field1 field2/],
    constraints => {
        field1 => {..}
    },
 );

=head3 validate

Validate parameters against a profile 

  my $result = validate $params, against => $profile_name;

=head1 SEE ALSO

Data::FormValidator Moose::Util::TypeConstraints MooseX::Types

=head1 REPOSITORY

 git://github.com/robinedwards/MooseX-DFV.git

=head1 AUTHOR

Rob Edwards, E<lt>robin.ge@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Rob Edwards

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
