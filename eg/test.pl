#!/usr/bin/env perl
use v5.42;
use experimental qw(builtin defer keyword_all keyword_any);
use lib "lib";

use Command::MultiRunner;

my $runner = Command::MultiRunner->new;

$runner->add(
    command => ["ls", "-al"],
    stdout => sub ($line) { warn "ls: $line\n" },
);
$runner->add(
    command => ['perl', '-e', 'for (1..5) { warn $_; sleep 1 } exit 1'],
    stdout => sub ($line) { warn "perl: $line\n" },
);

my @exit = $runner->run;

for my ($i, $exit) (indexed @exit) {
    warn "$i: $exit";
}
