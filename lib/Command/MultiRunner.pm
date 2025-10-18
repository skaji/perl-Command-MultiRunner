package Command::MultiRunner v0.0.1;
use v5.42;

use Command::Runner::LineBuffer;
use IO::Select;
use POSIX qw(WNOHANG);

sub new ($class) {
    bless { runners => [] }, $class;
}

sub add ($self, %argv) {
    $argv{command} or die "missing command key";
    $argv{stdout} or die "missing stdout key";
    push $self->{runners}->@*, \%argv;
}

sub run ($self) {
    my @runner = $self->{runners}->@*;
    my (@pid, @exit, @stdout);

    for my $runner (@runner) {
        pipe my $stdout_read, my $stdout_write;
        my $pid = fork // die;
        if ($pid) {
            push @pid, $pid;
            push @exit, undef;
            close $stdout_write;
            push @stdout, $stdout_read;
        } else {
            close $stdout_read;
            close $_ for @stdout;
            open STDOUT, ">&", $stdout_write;
            open STDERR, ">&", \*STDOUT;
            my @command = $runner->{command}->@*;
            exec { $command[0] } @command;
            exit 255;
        }
    }

    my @buffer = map { Command::Runner::LineBuffer->new(keep => 0) } @stdout;

    my %stdout_index;
    for my ($index, $stdout) (indexed @stdout) {
        $stdout_index{$stdout} = $index;
    }

    while (1) {
        my @pid2 = grep { defined $_ } @pid;
        my @stdout2 = grep { defined $_ } @stdout;

        if (@pid2 + @stdout2 == 0) {
            last;
        }

        for my ($i, $pid) (indexed @pid) {
            next if !defined $pid;
            my $ret = waitpid $pid, WNOHANG;
            if ($ret == -1) {
                die "waitpid $pid unexpectedly returns -1";
            } elsif ($ret > 0) {
                $pid[$i] = undef;
                $exit[$i] = $?;
            }
        }

        my $select = IO::Select->new(@stdout2);
        for my $stdout ($select->can_read(0.1)) {
            my $index = $stdout_index{$stdout} // die;
            my $buffer = $buffer[$index];
            my $cb = $runner[$index]{stdout};
            my $len = sysread $stdout, my $buf, 64*1024;
            if ($len) {
                $buffer->add($buf);
                my @line = $buffer->get;
                $cb->($_) for @line;
            } else {
                die "sysread $stdout failed $!" if !defined $len;
                my @line = $buffer->get(1);
                $cb->($_) for @line;
                close $stdout;
                $stdout[$index] = undef;
            }
        }
    }
    @exit;
}

__END__

=encoding utf-8

=head1 NAME

Command::MultiRunner - run multiple external programs

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Command::MultiRunner runs multiple external programs.

=head1 COPYRIGHT AND LICENSE

Copyright 2025 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
