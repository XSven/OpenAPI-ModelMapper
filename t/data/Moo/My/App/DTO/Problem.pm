package My::App::DTO::Problem;

use Moo;
use MooX::StrictConstructor;
use MooX::TypeTiny;

use Types::Common::Numeric qw( IntRange );
use Types::Common::String  qw( StrLength );
use Types::Standard        qw( Enum Int Str Undef );

use namespace::clean -except => [ qw( new ) ];

has detail => ( is => 'ro', isa => StrLength[ 0, 1024 ] );
has status => ( is => 'ro', isa => IntRange[ 100, 599 ] );
has title => ( is => 'ro', required => 1, isa => StrLength[ 0, 128 ] );

1
