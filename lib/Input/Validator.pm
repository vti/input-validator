package Input::Validator;

use strict;
use warnings;

use base 'Input::Validator::Base';

our $VERSION = '0.001002';

use Input::Validator::Bulk;
use Input::Validator::Condition;
use Input::Validator::Field;
use Input::Validator::Group;

require Carp;

sub BUILD {
    my $self = shift;

    $self->{fields}     = {};
    $self->{conditions} = [];
    $self->{groups}     = [];
    $self->{messages} ||= {};

    $self->{trim} = 1 unless defined $self->{trim};

    $self->{explicit} ||= 0;

    return $self;
}

sub field {
    my $self = shift;

    # Return field if it is already created
    return $self->{fields}->{$_[0]}
      if @_ == 1 && ref($_[0]) ne 'ARRAY' && $self->{fields}->{$_[0]};

    # Accept array or arrayref
    my @names = @_ == 1 && ref($_[0]) eq 'ARRAY' ? @{$_[0]} : @_;

    my $fields = [];
    foreach my $name (@names) {
        my $field = Input::Validator::Field->new(
            name     => $name,
            messages => $self->{messages},
            explicit => $self->{explicit},
        );

        $self->{fields}->{$name} = $field;
        push @$fields, $field;
    }

    return $self->{fields}->{$names[0]} if @names == 1;

    return Input::Validator::Bulk->new(fields => $fields);
}

sub when {
    my $self = shift;

    my $cond = Input::Validator::Condition->new->when(@_);

    push @{$self->{conditions}}, $cond;

    return $cond;
}

sub group {
    my $self   = shift;
    my $name   = shift;
    my $fields = shift;

    if (my ($exists) = grep { $_->name eq $name } @{$self->{groups}}) {
        Carp::croak("Fields of group '$name' already defined.") if $fields;
        return $exists;
    }

    $fields = [map { $self->{fields}->{$_} } @$fields];

    my $group = Input::Validator::Group->new(name => $name, fields => $fields);
    push @{$self->{groups}}, $group;

    return $group;
}

sub has_unknown_params {
    my $self = shift;

    return $self->{has_unknown_params};
}

sub has_errors {
    my $self = shift;

    my $errors = $self->{errors};

    return 1 if $errors && scalar keys %$errors;

    return 0;
}

sub error {
    my $self = shift;
    my ($name, $message) = @_;

    $self->{errors} ||= {};

    $self->{errors}->{$name} = $message;

    return $self;
}

sub errors {
    my $self = shift;

    return $self->{errors};
}

sub clear_errors {
    my $self = shift;

    # Clear field errors
    foreach my $field (CORE::values %{$self->{fields}}) {
        $field->error('');
    }

    # Clear group errors
    foreach my $group (@{$self->{groups}}) {
        $group->error('');
    }

    $self->{errors} = {};
}

sub validate {
    my $self   = shift;
    my $params = shift;

    while (1) {
        $self->clear_errors;

        $self->_flag_unknown($params);

        $self->_populate_fields($params);

        $self->_validate_fields;
        $self->_validate_groups;

        my @conditions =
          grep { !$_->is_matched && $_->match($self->{fields}) }
          @{$self->{conditions}};
        last unless @conditions;

        foreach my $cond (@conditions) {
            $cond->then->($self);
        }
    }

    return $self->has_errors ? 0 : 1;
}

sub _flag_unknown {
    my $self   = shift;
    my $params = shift;

    foreach my $param (keys %$params) {
        if (!defined $self->{fields}->{$param}) {
            $self->{has_unknown_params} = 1;

            if ($self->{explicit}) {
                $self->error($param => $self->{messages}->{'NOT_SPECIFIED'}
                      || 'NOT_SPECIFIED');
            }
        }
    }
}

sub _populate_fields {
    my $self   = shift;
    my $params = shift;

    foreach my $field (CORE::values %{$self->{fields}}) {
        $field->clear_value;

        $field->value($params->{$field->name});
    }
}

sub _validate_fields {
    my $self   = shift;
    my $params = shift;

    foreach my $field (CORE::values %{$self->{fields}}) {
        next if $field->is_valid;

        $self->error($field->name => $field->error) if $field->error;
    }
}

sub _validate_groups {
    my $self = shift;

    foreach my $group (@{$self->{groups}}) {
        next if $group->is_valid;

        $self->error($group->name => $group->error) if $group->error;
    }
}

sub values {
    my $self = shift;

    my $values = {};

    foreach my $field (CORE::values %{$self->{fields}}) {
        $values->{$field->name} = $field->value
          if defined $field->value && !$field->error;
    }

    return $values;
}

1;
__END__

=head1 NAME

Input::Validator - Input Validator

=head1 SYNOPSIS

    my $validator = Input::Validator->new;

    # Fields
    $validator->field('phone')->required(1)->regexp(qr/^\d+$/);
    $validator->field([qw/firstname lastname/])
      ->each(sub { shift->required(1)->length(3, 20) });

    # Groups
    $validator->field([qw/password confirm_password/])
      ->each(sub { shift->required(1) });
    $validator->group('passwords' => [qw/password confirm_password/])->equal;

    # Conditions
    $validator->field('document');
    $validator->field('number');
    $validator->when('document')->regexp(qr/^1$/)
      ->then(sub { shift->field('number')->required(1) });

    $validator->validate($values_hashref);
    my $errors_hashref = $validator->errors;
    my $pass_error = $validator->group('passwords')->error;
    my $validated_values_hashref = $validator->values;

=head1 DESCRIPTION

Data validator. Validates only the data. B<NO> form generation, B<NO> javascript
generation, B<NO> other stuff that does something else. Only data validation!

=head1 FEATURES

=over 4

    Validates data that is presented as a hash reference

    Multiple values

    Field registration

    Group validation

    Conditional validation

=back

=head1 CONVENTIONS

=over 4

    A value is considered empty when its value is C<undef>, C<''> or
    contains only spaces.

    If a value is not required and during validation is empty there is B<NO>
    error.

    If explicit is set to true, then all values not explicitly required
    generate an error.

    If a value is passed as an array reference and an appropriate field is
    not multiple, than only the first value is taken, otherwise every value of
    the array reference is checked.

=back

=head1 ATTRIBUTES

=head2 C<explicit>

Causes errors to be generated when unknown parameters exist.

=head2 C<has_unknown_params>

Unknown parameters exist in validated parameter hashref.

=head2 C<messages>

    my $validator =
      Input::Validator->new(
        messages => {REQUIRED => 'This field is required'});

Replace default messages.

=head2 C<trim>

Trim field values. B<ON> by default.

=head1 METHODS

=head2 C<new>

    my $validator = Input::Validator->new;

Create a new L<Input::Validator> object.

=head2 C<clear_errors>

    $validator->clear_errors;

Clear errors.

=head2 C<field>

    $validator->field('foo');               # Input::Validator::Field object is returned
    $validator->field('foo');               # Already created field object is returned

    $validator->field(qw/foo bar baz/);     # Input::Validator::Bulk object is returned
    $validator->field([qw/foo bar baz/]);   # Input::Validator::Bulk object is returned

When a single value is passed create L<Input::Validator::Field> object or
return an already created field object.

When an array or an array reference is passed return L<Input::Validator::Bulk> object. You can
call C<each> method to apply setting to multiple fields.

    $validator->field(qw/foo bar baz/)->each(sub { shift->required(1) });

=head2 C<group>

    $validator->field(qw/foo bar/)->each(sub { shift->required(1) });
    $validator->group('all_or_none' => [qw/foo bar/])->equal;

Register a group constraint that will be called on group of fields. If group
validation fails the C<errors> hashref will have the B<group> name with an
appropriate error message, B<NOT> fields' names.

=head2 C<when>

    $validator->field('document');
    $validator->field('number');
    $validator->when('document')->regexp(qr/^1$/)
      ->then(sub { shift->field('number')->required(1) });

Register a condition that is called when some conditions are met. You can do
whatever you want in condition's callback. Validation will be remade.

=head2 C<validate>

    $validator->validate({a => 'b'});
    $validator->validate({a => ['b', 'c']});
    $validator->validate({a => ['b', 'c'], b => 'd'});

Accept and validate a hash reference that represents data that is being
validated. Input values can be either a C<SCALAR> value or an C<ARRAREF> value,
which means that a field has multiple values. In case of an array reference, it
is checked if a field can have multiple values. Otherwise only the first value
is accepted and returned when C<values> method is called.

=head2 C<error>

    $validator->error(foo => 'bar');

Set a custom error.

=head2 C<errors>

    $validator->errors; # {a => 'Required'}

Return a hash reference of errors.

=head2 C<has_errors>

    $validator->has_errors;

Check if there are any errors.

=head2 C<values>

    $validator->values;

Return a hash reference of validated values. Only registered fields are returned,
that means that if some other values were passed to the C<validate> method they
are ignored.

=head1 DEVELOPMENT

=head2 Repository

    http://github.com/vti/input-validator

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 CREDITS

In alphabetical order:

Alex Voronov

Anatoliy Lapitskiy

Glen Hinkle

Naoya Ito

Yaroslav Korshak

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Viacheslav Tykhanovskyi.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
