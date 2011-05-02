#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;

use Hash::Validator::Constraint::Unique;

my $constraint = Hash::Validator::Constraint::Unique->new;

ok($constraint);

is($constraint->is_valid([qw/1 1/]), 0);
is($constraint->is_valid([qw/1 1 2/]), 0);
is($constraint->is_valid([qw/1 2 1/]), 0);
is($constraint->is_valid([qw/1 2 3/]), 1);
