#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 6;

use_ok('Hash::Validator::Group');
use_ok('Hash::Validator::Field');

my $foo = Hash::Validator::Field->new(name => 'foo')->value(1);
my $bar = Hash::Validator::Field->new(name => 'bar')->value(2);

my $group = Hash::Validator::Group->new(name => 'group1', fields => [$foo, $bar]);
$group->unique;
ok($group->is_valid);
ok(!$group->error);

$bar->value(1);
$group = Hash::Validator::Group->new(fields => [$foo, $bar]);
$group->unique;
ok(!$group->is_valid);
is($group->error, 'UNIQUE_CONSTRAINT_FAILED');
