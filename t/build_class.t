use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT note explain use_ok ) ], tests => 1;

use Path::Tiny          qw( path );
use Text::Template      ();
use YAML::XS            qw( LoadFile );
use Test::TempDir::Tiny qw( tempdir );

my $module;

BEGIN {
  $module = 'OpenAPI::ModelMapper';
  use_ok $module, 'build_class', 'fixup_json_ref'  or BAIL_OUT "Cannot load module '$module'!";
}

my $template = Text::Template->new( ENCODING => 'UTF-8', SOURCE => path( qw( t data Moo_class.tmpl ) ) ),
  or BAIL_OUT "Couldn't construct template: $Text::Template::ERROR";

my $root = do {
  local $YAML::XS::Boolean = 'JSON::PP';
  fixup_json_ref( LoadFile( path( qw( t data schemas.yml ) ) ) )
};
note explain $root;

my $tempdir = tempdir;
build_class $root, 'Common', $tempdir;
