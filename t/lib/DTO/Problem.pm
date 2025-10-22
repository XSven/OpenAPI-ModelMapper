package DTO::Problem;

use Moo;
use MooX::StrictConstructor;
use MooX::TypeTiny;

use Types::Common::Numeric qw( IntRange );
use Types::Common::String  qw( StrLength );
use Types::Standard        qw( Enum HashRef Int Str Undef );

use namespace::clean -except => [ qw( new ) ];

has detail => ( is => 'ro', isa => StrLength[ 0, 1024 ] );
has extensions => ( is => 'ro', isa => HashRef );
has status => ( is => 'ro', isa => IntRange[ 100, 599 ] );
has title => ( is => 'ro', required => 1, isa => StrLength[ 0, 128 ] );

# TO_JSON needs "predicate => 1" for all properties
sub TO_JSON {
  my ( $self ) = @_;
  my $json = {};
  foreach ( qw( detail status title ) ) {
    my $has = 'has_' . $_;
    $json->{ $_ } = $self->$_ if $self->$has
  }
  if ( $self->has_extensions ) {
    my %extensions = %{ $self->extensions };
    @$json{ keys %extensions } = values %extensions
  }
  $json
}

1
