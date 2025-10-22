use strict;
use warnings;

use Test::Lib;
use Test::More import => [ qw( BAIL_OUT require_ok use_ok ) ], tests => 4;
use Test::Fatal          qw( lives_ok );
use Test::File::Contents qw( files_eq_or_diff );
use Test::File::ShareDir ();
use Test::TempDir::Tiny  qw( tempdir );

use File::Spec::Functions qw( catdir catfile );
use YAML::XS              qw( LoadFile );

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

my $class_file;
lives_ok { $class_file = build_class $root, 'Common', tempdir() } 'Successful build';

files_eq_or_diff $class_file, catfile( qw( t lib Model Common.pm ) ), { encoding => 'UTF-8' },
  'Compare with expected file';

require_ok $class_file
