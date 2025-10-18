[![Actions Status](https://github.com/skaji/perl-Command-MultiRunner/actions/workflows/test.yml/badge.svg)](https://github.com/skaji/perl-Command-MultiRunner/actions)

# NAME

Command::MultiRunner - run multiple external programs

# SYNOPSIS

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

# DESCRIPTION

Command::MultiRunner runs multiple external programs.

# COPYRIGHT AND LICENSE

Copyright 2025 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
