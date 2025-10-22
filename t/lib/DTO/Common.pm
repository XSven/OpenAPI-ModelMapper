package DTO::Common;

use Moo;
use MooX::StrictConstructor;
use MooX::TypeTiny;

use Types::Common::String qw( StrLength );
use Types::Standard       qw( Enum Str Undef );

has environment => ( is => 'ro', isa => Enum[ qw( dev test prod ) ] | Undef );
has user => ( is => 'ro', required => 1, isa => StrLength[ 0, 255 ] );

1
