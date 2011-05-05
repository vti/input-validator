package Input::Validator::ConstraintBuilder;

use strict;
use warnings;

use String::CamelCase ();
use Class::Load ();

sub build {
    my $self = shift;
    my $name = shift;

    my $class =
        $name =~ m/[A-Z]/
      ? $name
      : "Input::Validator::Constraint::"
      . String::CamelCase::camelize($name);

    Class::Load::load_class($class);

    return $class->new(args => @_ > 1 ? [@_] : ($_[0] || []));
}

1;
__END__

=head1 NAME

Input::Validator::ConstraintBuilder - Constraint factory

=head1 SYNOPSIS

    $field->constraint(length => [1, 2]);

=head1 DESCRIPTION

A factory class for constraints. Build a new object.

=head1 METHODS

=head2 C<build>

    Input::Validator::ConstraintBuilder->build('length' => [1, 3]);

Build a new constraint object passing all additional parameters.

=cut
