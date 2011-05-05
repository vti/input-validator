package Input::Validator::Condition;

use strict;
use warnings;

use base 'Input::Validator::Base';

use Input::Validator::ConstraintBuilder;

sub BUILD {
    my $self = shift;

    $self->{then} ||= sub { };
    $self->{bulks} ||= [];

    return $self;
}

sub regexp { shift->constraint('regexp' => @_) }
sub length { shift->constraint('length' => @_) }

sub when {
    my $self = shift;
    my $fields = ref $_[0] eq 'ARRAY' ? shift : [@_];

    my $bulk = {fields => $fields, constraints => []};
    push @{$self->{bulks}}, $bulk;

    return $self;
}

sub then {
    my $self = shift;

    return $self->{then} unless @_;

    $self->{then} = $_[0];

    return $self;
}

sub constraint {
    my $self = shift;

    my $constraint = Input::Validator::ConstraintBuilder->build(@_);

    my $bulk = $self->{bulks}->[-1];
    push @{$bulk->{constraints}}, $constraint;

    return $self;
}

sub is_matched { shift->{matched} }

sub match {
    my $self   = shift;
    my $params = shift;

    foreach my $bulk (@{$self->{bulks}}) {
        foreach my $name (@{$bulk->{fields}}) {
            my $field = $params->{$name};

            # No field
            return 0 unless $field;

            # Field has already an error
            return 0 if $field->error;

            my $values = $field->value;
            $values = [$values] unless ref($values) eq 'ARRAY';

            foreach my $value (@$values) {
                return 0 unless defined($value) && $value ne '';

                foreach my $c (@{$bulk->{constraints}}) {
                    my ($ok, $error) = $c->is_valid($value);
                    return 0 unless $ok;
                }
            }
        }
    }

    $self->{matched} = 1;

    return 1;
}

1;
__END__

=head1 NAME

Input::Validator::Condition - Condition object

=head1 SYNOPSIS

    $validator->when('document')->regexp(qr/^1$/)
      ->then(sub { shift->field('number')->required(1) });

=head1 DESCRIPTION

Condition object.

=head1 ATTRIBUTES

=head2 C<then>

    $condition->then(sub { ... });

Holds callback that is called when conditions is matched.

=head1 METHODS

=head2 C<constraint>

    $condition->consraint(length => [1, 3]);

Adds a constraint.

=head2 C<length>

Shortcut

    $condition->consraint(length => @_);

=head2 C<match>

    my $matched = $condition->match;

Check whether conditions is matched.

=head2 C<regexp>

Shortcut

    $condition->consraint(regexp => @_);

=head2 C<when>

    $condition->when('foo');
    $condition->when(qw/foo bar/);
    $condition->when([qw/foo bar baz/]);

Adds fields which values are checked to match the condition.

=head1 SEE ALSO

L<Input::Validator>, L<Input::Validator::Field>, L<Input::Validator::Constraint>

=cut
