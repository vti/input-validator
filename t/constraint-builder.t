#!/usr/bin/env perl

package CustomConstraint;
use base 'Hash::Validator::Constraint::In';

package main;

use strict;
use warnings;

use Test::More tests => 4;

use Hash::Validator::ConstraintBuilder;

my $constraint = Hash::Validator::ConstraintBuilder->build('in');
ok($constraint);
ok($constraint->isa('Hash::Validator::Constraint::In'));

$constraint = Hash::Validator::ConstraintBuilder->build('CustomConstraint');
ok($constraint);
ok($constraint->isa('CustomConstraint'));
