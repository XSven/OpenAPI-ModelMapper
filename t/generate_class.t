use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT isa_ok require_ok ) ], tests => 11;
use Test::Fatal          qw( dies_ok lives_ok );
use Test::File::Contents qw( files_eq_or_diff );
use Test::File::ShareDir ();
use Test::TempDir::Tiny  qw( tempdir );

use File::Spec::Functions qw( catdir catfile );

my $class;

BEGIN {
  $class = 'OpenAPI::ModelMapper';
  Test::File::ShareDir->import( -share => { -module => { $class => catdir( qw(  share templates ) ) } } );
  require_ok $class or BAIL_OUT "Cannot load class '$class'!"
}

my $self          = $class->load_spec_file( catfile( qw( t data schemas.yml ) ) );
my $object_system = 'Moo';

dies_ok { $self->generate_class( 'Unknown', $object_system, '' ) } 'Unknown schema name';

for my $name ( qw ( Common DeploymentStatus Problem ) ) {
  my $class_file;
  lives_ok { $class_file = $self->generate_class( $name, tempdir() ) }
  "Class file for '$name' schema successfully generated";

  files_eq_or_diff $class_file,
    catfile( qw( t data ), $self->object_system, split( '::', $self->prefix ), 'DTO', $name . '.pm' ),
    { encoding => 'UTF-8' },
    'Compare with expected class file';

  require_ok $class_file
}
