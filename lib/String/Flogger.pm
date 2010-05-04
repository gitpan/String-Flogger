use strict;
use warnings;
package String::Flogger;
BEGIN {
  $String::Flogger::VERSION = '1.101240';
}
# ABSTRACT: string munging for loggers

use Params::Util qw(_ARRAYLIKE _CODELIKE);
use Scalar::Util qw(blessed);
use Sub::Exporter::Util ();
use Sub::Exporter -setup => [ flog => Sub::Exporter::Util::curry_method ];


sub _encrefs {
  my ($self, $messages) = @_;
  return map { blessed($_) ? sprintf('obj(%s)', "$_")
             : ref $_      ? $self->_stringify_ref($_)
             : defined $_  ? $_
             :              '{{null}}' }
         map { _CODELIKE($_) ? scalar $_->() : $_ }
         @$messages;
}

my $JSON;
sub _stringify_ref {
  my ($self, $ref) = @_;

  if (ref $ref eq 'SCALAR' or ref $ref eq 'REF') {
    my ($str) = $self->_encrefs([ $$ref ]);
    return "ref($str)";
  }

  require JSON;
  $JSON ||= JSON->new
                ->ascii(1)
                ->canonical(1)
                ->allow_nonref(1)
                ->space_after(1)
                ->convert_blessed(1);

  return '{{' . $JSON->encode($ref) . '}}'
}

sub flog {
  my ($class, $input) = @_;

  my $output;

  if (_CODELIKE($input)) {
    $input = $input->();
  }

  return $input unless ref $input;

  if (_ARRAYLIKE($input)) {
    my ($fmt, @data) = @$input;
    return sprintf $fmt, $class->_encrefs(\@data);
  }

  return $class->_encrefs([ $input ]);
}

1;

__END__
=pod

=head1 NAME

String::Flogger - string munging for loggers

=head1 VERSION

version 1.101240

=head1 SYNOPSIS

  use String::Flogger qw(flog);

  my @inputs = (
    'simple!',

    [ 'slightly %s complex', 'more' ],

    [ 'and inline some data: %s', { look => 'data!' } ],

    [ 'and we can defer evaluation of %s if we want', sub { 'stuff' } ],

    sub { 'while avoiding sprintfiness, if needed' },
  );

  say flog($_) for @inputs;

The above will output:

  simple!

  slightly more complex

  and inline some data: {{{ "look": "data!" }}}

  and we can defer evaluation of stuff if we want

  while avoiding sprintfiness, if needed

=head1 AUTHOR

  Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo SIGNES <rjbs@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

