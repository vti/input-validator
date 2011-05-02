package Hash::Validator::Constraint::Subset;

use strict;
use warnings;

use base 'Hash::Validator::Constraint';

sub is_valid {
    my ($self, $values) = @_;

    $values = [$values] unless ref $values eq 'ARRAY';

    foreach my $value (@$values) {
        return 0 unless grep { $value eq $_ } @{$self->args};
    }

    return 1;
}

1;
__END__

=head1 NAME

Hash::Validator::Constraint::Subset - Subset constraint

=head1 SYNOPSIS

    $validator->field('tags')->constraint(subset => [qw/foo bar baz/]);

=head1 DESCRIPTION

Checks whether the value is a subset of the provided array reference values.

=head1 METHODS

=head2 C<is_valid>

Validates the constraint.

=head1 SEE ALSO

L<Hash::Validator>, L<Hash::Constraint>

=cut
