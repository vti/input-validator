package Input::Validator::Field;

use strict;
use warnings;

use base 'Input::Validator::Base';

use Input::Validator::Bulk;
use Input::Validator::ConstraintBuilder;

our $AUTOLOAD;

sub BUILD {
    my $self = shift;

    $self->{constraints} ||= [];
    $self->{messages}    ||= {};

    $self->{trim} = 1 unless defined $self->{trim};

    return $self;
}

sub name {
    my $self = shift;

    return $self->{name} unless @_;

    $self->{name} = $_[0];

    return $self;
}

sub required {
    my $self = shift;

    return $self->{required} unless @_;

    $self->{required} = $_[0];

    return $self;
}

sub inflate {
    my $self = shift;

    return $self->{inflate} unless @_;

    $self->{inflate} = $_[0];

    return $self;
}

sub deflate {
    my $self = shift;

    return $self->{deflate} unless @_;

    $self->{deflate} = $_[0];

    return $self;
}

sub trim {
    my $self = shift;

    return $self->{trim} unless @_;

    $self->{trim} = $_[0];

    return $self;
}

sub error {
    my $self = shift;

    return $self->{error} unless @_;

    $self->{error} = $_[0];

    return $self;
}

sub constraint {
    my $self = shift;

    my $constraint = Input::Validator::ConstraintBuilder->build(@_);

    push @{$self->{constraints}}, $constraint;

    return $self;
}

sub message {
    my $self    = shift;
    my $message = shift;

    $self->{message} = $message if defined $message;

    return $self;

}

sub _message {
    my $self    = shift;
    my $message = shift;
    my $params  = shift || [];

    return sprintf($self->{message}, @$params) if $self->{message};

    return $self->{messages}->{$message} || $message;
}

sub multiple {
    my $self = shift;

    return $self->{multiple} unless @_;

    $self->{multiple} = [splice @_, 0, 2];

    return $self;
}

sub value {
    my $self = shift;

    return $self->{value} unless @_;

    my $value = shift;

    return unless defined $value;

    if ($self->multiple) {
        $self->{value} = ref($value) eq 'ARRAY' ? $value : [$value];
    }
    else {
        $self->{value} = ref($value) eq 'ARRAY' ? $value->[0] : $value;
    }

    return $self unless $self->trim;

    foreach ($self->multiple ? @{$self->{value}} : $self->{value}) {
        s/^\s+//;
        s/\s+$//;
    }

    return $self;
}

sub is_valid {
    my ($self) = @_;

    $self->error('');

    $self->error($self->_message('REQUIRED')), return 0
      if $self->required && $self->is_empty;

    return 1 if $self->is_empty;

    my @values = $self->multiple ? @{$self->value} : $self->value;

    @values = map { &{$self->inflate} } @values if $self->inflate;

    if (my $multiple = $self->multiple) {
        my ($min, $max) = @$multiple;

        $self->error($self->_message('NOT_ENOUGH')), return 0
          if @values < $min;
        $self->error($self->_message('TOO_MUCH')), return 0
          if defined $max ? @values > $max : $min != 1 && @values != $min;
    }

    foreach my $c (@{$self->{constraints}}) {
        if ($c->is_multiple) {
            my ($ok, $error) = $c->is_valid([@values]);

            unless ($ok) {
                $self->error($self->_message($c->error, $error));
                return 0;
            }
        }
        else {
            foreach my $value (@values) {
                my ($ok, $error) = $c->is_valid($value);

                unless ($ok) {
                    $self->error($self->_message($c->error, $error));
                    return 0;
                }
            }
        }
    }

    @values = map { &{$self->deflate} } @values if $self->deflate;

    $self->value($self->multiple ? \@values : $values[0]);

    return 1;
}

sub clear_error {
    my $self = shift;

    delete $self->{error};
}

sub clear_value {
    my $self = shift;

    delete $self->{value};
}

sub each {
    my $self = shift;

    my $bulk = Input::Validator::Bulk->new(fields => [$self]);
    return $bulk->each(@_);
}

sub is_defined {
    my ($self) = @_;

    return defined $self->value ? 1 : 0;
}

sub is_empty {
    my ($self) = @_;

    return 1 unless $self->is_defined;

    if (ref $self->value eq 'ARRAY') {
        return @{$self->value} == 0;
    }

    return $self->value eq '' ? 1 : 0;
}

sub AUTOLOAD {
    my $self = shift;

    my $method = $AUTOLOAD;

    return if $method =~ /^[A-Z]+?$/;
    return if $method =~ /^_/;
    return if $method =~ /(?:\:*?)DESTROY$/;

    $method = (split '::' => $method)[-1];

    return $self->constraint($method => @_);
}

1;
__END__

=head1 NAME

Input::Validator::Field - Field object

=head1 SYNOPSIS

    $validator->field('foo');
    $validator->field(qw/foo bar/);
    $validator->field([qw/foo bar baz/]);

=head1 DESCRIPTION

Field object. Used internally.

=head1 ATTRIBUTES

=head2 C<messages>

Error messages.

=head2 C<deflate>

    $field->deflate(sub { s/foo/bar/ });

Use this when you want to change value of field after validation.

=head2 C<error>

    $field->error('Invalid input');
    my $error = $field->error;

Field error.

=head2 C<each>

    $field->each(sub { shift->required(1) });

Each method as described in L<Input::Validator::Bulk>. Added here for
convenience.

=head2 C<inflate>

    $field->inflate(sub { s/foo/bar/ });

Use this when you want to change value of field before validation.

=head2 C<multiple>

    $field->multiple(1);

Field can have multiple values. Use this when you want to allow array reference
as a value.

    $field->multiple(2, 5);

If you want to control how many multiple values there can be set C<min> and
C<max> values.

    $field->multiple(10);

When C<max> value is omitted and is not C<1> (because it doesn't make sense),
number of values must be equal to this value.

=head2 C<name>

    $field->name('foo');
    my $name = $field->name;

Field's name.

=head2 C<required>

    $field->required(1);

Whether field is required or not. See L<Input::Validator> documentation what is
an empty field.

=head2 C<trim>

    $field->trim(1);

Whether field's value should be trimmed before validation. It is B<ON> by
default.

=head1 METHODS

=head2 C<callback>

Shortcut

    $field->constraint(callback => sub { ... });

=head2 C<clear_error>

    $field->clear_value;

Clears field's error.

=head2 C<clear_value>

    $field->clear_value;

Clears field's value.

=head2 C<constraint>

    $field->constraint(length => [1, 2]);

Adds a new field's constraint.

=head2 C<is_defined>

    my $defined = $field->is_defined;

Checks whether field's value is defined.

=head2 C<is_empty>

    my $empty = $field->is_empty;

Checks whether field's value is empty.

=head2 C<is_valid>

Checks whether all field's constraints are valid.

=head2 C<message>

Holds error message.

=head2 C<value>

    my $value = $field->value;
    $field->value('foo')

Set or get field's value.

=head1 SEE ALSO

L<Input::Validator>, L<Input::Validator::Constraint>.

=cut
