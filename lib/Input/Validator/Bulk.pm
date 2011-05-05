package Input::Validator::Bulk;

use strict;
use warnings;

use base 'Input::Validator::Base';

sub BUILD {
    my $self = shift;

    $self->{fields} ||= [];

    return $self;
}

sub each {
    my $self = shift;
    my $cb   = shift;

    foreach my $field (@{$self->{fields}}) {
        $cb->($field);
    }

    return $self;
}

1;
__END__

=head1 NAME

Input::Validator::Bulk - Internal object for multiple fields processing

=head1 SYNOPSIS

    $validator->field(qw/foo bar/)->each(sub { shift->required(1) });

=head1 DESCRIPTION

Bulk object. Holds multiple fields that were created by L<Input::Validator>.

=head1 METHODS

=head2 C<each>

    $bulk->each(sub { shift->required(1) });

Every field is passed to this callback as the first parameter.

=head1 SEE ALSO

L<Input::Validator>

=cut
