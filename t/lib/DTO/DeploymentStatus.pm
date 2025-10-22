package DTO::DeploymentStatus;

use Moo;
use MooX::StrictConstructor;
use MooX::TypeTiny;

use Types::Common::String qw( StrLength );
use Types::Standard       qw( Enum Str Undef );

has message => ( is => 'ro', isa => Str );
has status => ( is => 'ro', required => 1, isa => Enum[ qw( triggered pending succeeded service_failed failed ) ] );

1
