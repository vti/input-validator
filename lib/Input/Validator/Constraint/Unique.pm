package Input::Validator::Constraint::Unique;

use strict;
use warnings;

use base 'Input::Validator::Constraint';

sub is_multiple {1}

sub is_valid {
    my ($self, $values) = @_;

    my %values = map { $_ => 1 } @$values;

    return 0 unless keys %values == @$values;

    return 1;
}

1;
__END__

=head1 NAME

Input::Validator::Constraint::Unique - Unique constraint

=head1 SYNOPSIS

    $validator->group(all_the_values_are_different => [qw/foo bar baz/])
      ->unique;

=head1 DESCRIPTION

Group constraint that validates that all the values are different.

=head1 METHODS

=head2 C<is_valid>

Validates the constraint.

=head1 SEE ALSO

L<Input::Validator>, L<Input::Constraint>

=cut
