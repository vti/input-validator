#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;

use Hash::Validator::Constraint;

my $constraint = Hash::Validator::Constraint->new;

ok($constraint);

is($constraint->is_valid(), 0);
