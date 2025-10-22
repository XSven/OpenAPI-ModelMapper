use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT note explain use_ok ) ], tests => 1;

use File::Spec::Functions qw( catdir catfile );
use Text::Template        ();
use YAML::XS              qw( LoadFile );
use Test::TempDir::Tiny   qw( tempdir );
use Test::File::ShareDir  ();

my $module;

BEGIN {
  $module = 'OpenAPI::ModelMapper';
  Test::File::ShareDir->import( -share => { -module => { $module => catdir( qw(  share templates ) ) } } );
  use_ok $module, 'build_class', 'fixup_json_ref' or BAIL_OUT "Cannot load module '$module'!"
}

my $root = do {
  local $YAML::XS::Boolean = 'JSON::PP'; ## no critic ( ProhibitPackageVars )
  fixup_json_ref( LoadFile( catfile( qw( t data schemas.yml ) ) ) )
};
note explain $root;

my $tempdir = tempdir;
build_class $root, 'Common', $tempdir;
