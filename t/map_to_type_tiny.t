use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT explain is note use_ok ) ], tests => 8;

use File::Spec::Functions qw( catfile );
use YAML::XS              qw( LoadFile );

my $module;

BEGIN {
  $module = 'OpenAPI::ModelMapper';
  use_ok $module, 'map_to_type_tiny' or BAIL_OUT "Cannot load module '$module'!";
}

my $schemas = do {
  local $YAML::XS::Boolean = 'JSON::PP'; ## no critic ( ProhibitPackageVars )
  LoadFile( catfile( qw( t data schemas.yml ) ) )->{ components }->{ schemas }
};
#note explain $schemas;

is map_to_type_tiny( $schemas->{ Basic } ),       'Str',                                 'Only basic type';
is map_to_type_tiny( $schemas->{ Nullable } ),    'Int | Undef',                         'Nullable basic type';
is map_to_type_tiny( $schemas->{ SortOrder } ),   'Enum[ qw( asc desc ) ]',              'String enum';
is map_to_type_tiny( $schemas->{ Environment } ), 'Enum[ qw( dev test prod ) ] | Undef', 'Nullable string enum';
is map_to_type_tiny( $schemas->{ Password } ),    'StrLength[ 8 ]',      'String with min length restriction';
is map_to_type_tiny( $schemas->{ Initials } ),    'StrLength[ 0, 3 ]',   'String with max length restriction';
is map_to_type_tiny( $schemas->{ Fullname } ),    'StrLength[ 1, 255 ]', 'String with min and max length restrictions';
