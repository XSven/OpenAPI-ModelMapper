use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT explain is note require_ok ) ], tests => 9;

use File::Spec::Functions qw( catfile );

my $class;

BEGIN {
  $class = 'OpenAPI::ModelMapper';
  require_ok $class, 'map_to_type_tiny' or BAIL_OUT "Cannot load class '$class'!";
}

my $self    = $class->load_spec_file( catfile( qw( t data schemas.yml ) ) );
my $schemas = $self->spec->{ components }->{ schemas };
#note explain $schemas;
my $code = $class->can( '_map_to_type_tiny' );
is $code->( $schemas->{ BasicString } ),  'Str',                                 'Only basic type';
is $code->( $schemas->{ BasicInteger } ), 'Int',                                 'Only basic type';
is $code->( $schemas->{ Nullable } ),     'Int | Undef',                         'Nullable basic type';
is $code->( $schemas->{ SortOrder } ),    'Enum[ qw( asc desc ) ]',              'String enum';
is $code->( $schemas->{ Environment } ),  'Enum[ qw( dev test prod ) ] | Undef', 'Nullable string enum';
is $code->( $schemas->{ Password } ),     'StrLength[ 8 ]',                      'String with min length restriction';
is $code->( $schemas->{ Initials } ),     'StrLength[ 0, 3 ]',                   'String with max length restriction';
is $code->( $schemas->{ Fullname } ),     'StrLength[ 1, 255 ]', 'String with min and max length restrictions';
