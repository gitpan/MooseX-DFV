package MooseX::DFV::Results;
use Moose;
use Moose::Util::TypeConstraints 'find_type_constraint';
use String::CamelCase qw/decamelize/;
extends 'Data::FormValidator::Results';

override _constraint_hash_build => sub {
    my ($self,$constraint_spec,$untaint_this,$force_method_p) = @_;

    die "_constraint_hash_build received wrong number of arguments" unless (scalar @_ == 4);


    my  $c = {
            name        => $constraint_spec,
            constraint  => $constraint_spec,
        };

   # constraints can be passed in directly via hash
    if (ref $c->{constraint} eq 'HASH') {
            $c->{constraint} = ($constraint_spec->{constraint_method} || $constraint_spec->{constraint});
            $c->{name}       = $constraint_spec->{name};
            $c->{params}     = $constraint_spec->{params};
            $c->{is_method}  = 1 if $constraint_spec->{constraint_method};
            $c->{type}       = $constraint_spec->{type}; 
    }

    # Check for regexp constraint
    if ($c->{constraint}and (( ref $c->{constraint} eq 'Regexp')
            or ( $c->{constraint} =~ m@^\s*(/.+/|m(.).+\2)[cgimosx]*\s*$@ ))) {
        $c->{constraint} = _create_sub_from_RE($c->{constraint},$untaint_this,$force_method_p);
    }
    # check for code ref
    elsif (ref $c->{constraint} eq 'CODE') {
        # do nothing, it's already a code ref
    }
    # is a moose type constraint
    elsif (defined $c->{type}){
        $c->{constraint}  = $self->_build_moose_type_constraint($c);
    }
    else {
        # provide a default name for the constraint if we don't have one already
        $c->{name} ||= $c->{constraint};

        #If untaint is turned on call match_* sub directly.
        if ($untaint_this) {
            my $routine = 'match_'.$c->{constraint};
            my $match_sub = *{qualify_to_ref($routine)}{CODE};
            if ($match_sub) {
                $c->{constraint} = $match_sub;
            }
            # If the constraint name starts with RE_, try looking for it in the Regexp::Common package
            elsif ($c->{constraint} =~ m/^RE_/) {
                local $SIG{__DIE__}  = \&confess;
                $c->{is_method} = 1;
                $c->{constraint} = eval 'sub { &_create_regexp_common_constraint(@_)}'
                || die "could not create Regexp::Common constraint: $@";
            } else {
                die "No untainting constraint found named $c->{constraint}";
            }
        }
        else {
            # try to use match_* first
            my $routine = 'match_'.$c->{constraint};
            if (defined *{qualify_to_ref($routine)}{CODE}) {
                local $SIG{__DIE__}  = \&confess;
                $c->{constraint} = eval 'sub { no strict qw/refs/; return defined &{"match_'.$c->{constraint}.'"}(@_)}';
            }
            # match_* doesn't exist; if it is supposed to be from the
            # validator_package(s) there may be only valid_* defined
            elsif (my $valid_sub = *{qualify_to_ref('valid_'.$c->{constraint})}{CODE}) {
                $c->{constraint} = $valid_sub;
            }
            # Load it from Regexp::Common
            elsif ($c->{constraint} =~ m/^RE_/) {
                local $SIG{__DIE__}  = \&confess;
                $c->{is_method} = 1;
                $c->{constraint} = eval 'sub { return defined &_create_regexp_common_constraint(@_)}' ||
                die "could not create Regexp::Common constraint: $@";
            }
            else {
                die "No constraint found named '$c->{name}'";
            }
        }
    }

    # Save the current constraint name for later
    $self->{__CURRENT_CONSTRAINT_NAME} = $c->{name};

    return $c;
};

sub _build_moose_type_constraint {
    my ($self, $c) = @_;

    if (ref $c->{type} eq '') {
        $c->{type} = find_type_constraint($c->{type}); 
        confess "Can't find type constraint '$c->{type}'" unless $c->{type};
    }

	$c->{name} = $c->{type}->name || 'unknown';
	confess "Type '$c->{name}' doesn't provide a check method" unless $c->{type}->can('check');

    $c->{message} ||=  $self->_build_type_message($c);
    
    return sub {
        my ($value) = @_;
        $self->{__CURRENT_CONSTRAINT_NAME} =  ref $c->{type}->message eq 'CODE'
            ? $c->{type}->message->($value) : $c->{message};
        return $c->{type}->check($value);
    };
}

sub _build_type_message {
	my ($self,$c) = @_;
	return $c->{type}->message 
		if $c->{type}->can('message') and $c->{type}->message;

	my $type_lookup = {
		'Int' => 'integer',
		'Bool' => 'boolean',
		'Num' => 'number',
		'Str' => 'string',
	};

	my $type_name = $type_lookup->{$c->{name}} || $c->{name} || 'unknown';

	return "invalid value for an $type_name";
}



1;
