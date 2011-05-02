#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 3;

use Hash::Validator::Constraint::Callback;

my $constraint = Hash::Validator::Constraint::Callback->new(
    args => sub {
        my $value = shift;

        return 1 if $value =~ m/^\d+$/;

        return 0;
    }
);

ok($constraint);

ok(!$constraint->is_valid('hello'));
ok($constraint->is_valid(123));
