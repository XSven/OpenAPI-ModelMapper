package My::App::DTO::Common;

use Moo;
use MooX::StrictConstructor;
use MooX::TypeTiny;

use Types::Common::Numeric qw( IntRange );
use Types::Common::String  qw( StrLength );
use Types::Standard        qw( Any Defined Enum Int Str Undef );

use namespace::clean -except => [ qw( new ) ];

has environment => ( is => 'ro', isa => Enum[ qw( dev test prod ) ] | Undef );
has user => ( is => 'ro', required => 1, isa => StrLength[ 0, 255 ] );

1
