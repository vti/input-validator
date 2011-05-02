#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 24;

use Hash::Validator::Condition;
use Hash::Validator::Field;

my $condition = Hash::Validator::Condition->new;
$condition->when('bar');

my $foo = Hash::Validator::Field->new(name => 'foo');
my $bar = Hash::Validator::Field->new(name => 'bar');

ok(!$condition->match({}));
ok(!$condition->match({bar => $bar}));
$bar->value('');
ok(!$condition->match({bar => $bar}));
$bar->value('foo');
ok($condition->match({bar => $bar}));

$condition = Hash::Validator::Condition->new;
$condition->when([qw/foo bar/]);

$foo = Hash::Validator::Field->new(name => 'foo');
$bar = Hash::Validator::Field->new(name => 'bar');

ok(!$condition->match({}));
$foo->value('bar');
ok(!$condition->match({foo => $foo}));
$bar->value('foo');
ok(!$condition->match({bar => $bar}));
ok($condition->match({foo => $foo, bar => $bar}));
$foo->multiple(1)->value([qw/bar baz/]);
ok($condition->match({foo => $foo, bar => $bar}));

$foo = Hash::Validator::Field->new(name => 'foo');
$bar = Hash::Validator::Field->new(name => 'bar');

ok(!$condition->match({}));
$foo->value('bar');
ok(!$condition->match({foo => $foo}));
$bar->value('foo');
ok(!$condition->match({bar => $bar}));
ok($condition->match({foo => $foo, bar => $bar}));
$foo->multiple(1)->value(qw/bar baz/);
ok($condition->match({foo => $foo, bar => $bar}));

$condition = Hash::Validator::Condition->new;
$condition->when('foo')->regexp(qr/^\d+$/)->length(1, 3);

$foo = Hash::Validator::Field->new(name => 'foo');
$bar = Hash::Validator::Field->new(name => 'bar');

ok(!$condition->match({}));
$foo->value('bar');
ok(!$condition->match({foo => $foo}));
$foo->value(1234);
ok(!$condition->match({foo => $foo}));
$foo->value(123);
ok($condition->match({foo => $foo}));

$condition = Hash::Validator::Condition->new;
$condition->when('foo')->regexp(qr/^\d+$/)->length(1, 3);

$foo = Hash::Validator::Field->new(name => 'foo');
$bar = Hash::Validator::Field->new(name => 'bar');

$foo->error('Required');
ok(!$condition->match({foo => $foo}));
$foo->clear_error;

$condition = Hash::Validator::Condition->new;
$condition->when('foo')->regexp(qr/^\d+$/)->length(1, 3)->when('bar')
  ->regexp(qr/^\d+$/);
 
$foo = Hash::Validator::Field->new(name => 'foo');
$bar = Hash::Validator::Field->new(name => 'bar');

ok(!$condition->match({}));
$foo->value('bar');
$bar->value('foo');
ok(!$condition->match({foo => $foo, bar => $bar}));
$foo->value('barr');
$bar->value('foo');
ok(!$condition->match({foo => $foo, bar => $bar}));
$foo->value(123);
$bar->value('foo');
ok(!$condition->match({foo => $foo, bar => $bar}));
$foo->value(123);
$bar->value(123);
ok($condition->match({foo => $foo, bar => $bar}));
