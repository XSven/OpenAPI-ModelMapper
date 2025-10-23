# Prefer numeric version for backwards compatibility
BEGIN { require 5.010_001 }; ## no critic ( RequireUseStrict, RequireUseWarnings )
use strict;
use warnings;

package OpenAPI::ModelMapper;

$OpenAPI::ModelMapper::VERSION = 'v1.0.0';

use subs qw( _fixup_json_ref _map_to_type_tiny );

use Carp                  qw( croak );
use File::Spec::Functions qw( catfile );
use File::ShareDir        qw( module_dir );
use JSON::Pointer         ();
use YAML::XS              qw( LoadFile );
use Path::Tiny            qw( path );         # FIXME: try to get rid of Path::Tiny
use Text::Template        ();

sub load_spec_file {
  my ( $class, $spec_file ) = @_;

  my $spec = do {
    local $YAML::XS::Boolean = 'JSON::PP'; ## no critic ( ProhibitPackageVars )
    _fixup_json_ref( LoadFile( $spec_file ) )
  };

  bless { spec_file => $spec_file, spec => $spec, object_system => 'Moo', prefix => 'My::App' }, $class
}

sub object_system {
  my ( $self ) = @_;

  $self->{ object_system }
}

sub prefix {
  my ( $self ) = @_;

  $self->{ prefix }
}

sub spec {
  my ( $self ) = @_;

  $self->{ spec }
}

sub generate_class {
  # $name doesn't refer to a package name it is a lookup key
  my ( $self, $name, $tempdir ) = @_;

  my $schema = $self->spec->{ components }->{ schemas }->{ $name };
  croak "No schema with name '$name' found in 'components/schemas' subsection"
    unless defined $schema;

  # Assume that the ENCODING of the template file (the SOURCE) is UTF-8
  my $template = Text::Template->new(
    ENCODING => 'UTF-8',
    SOURCE   => catfile( module_dir( __PACKAGE__ ), $self->object_system . '-DTO-class.tmpl' )
  ) or croak "Couldn't construct template: $Text::Template::ERROR";

  my $class_file = path( $tempdir, split( '::', $self->prefix ), 'DTO' )->mkdir->child( "$name.pm" );
  # On purpose overwrite existing class file
  my $class_filehandle = $class_file->openw_utf8;
  $template->fill_in(
    HASH   => [ { namespace => $self->prefix . "::DTO::$name", isa => \&_map_to_type_tiny }, $schema ],
    OUTPUT => $class_filehandle
  ) or croak "Couldn't fill in template: $Text::Template::ERROR";

  # success
  $class_file->stringify
}

{
  my $basic_types_map = {
    integer => 'Int',
    string  => 'Str'
    #number => 'Num',
    #boolean => '', # a conflict between JSON::PP::Boolean and Type::Tiny
    #object  => 'HashRef',
  };

  sub _map_to_type_tiny ( $ ) {
    my ( $data ) = @_;

    # FIXME: "allOf" not implemented yet
    if ( exists $data->{ anyOf } ) {
      # FIXME: Not properly impelemted. We need a kind of union here
      # ... so we have a multi-type. Hope that it is just a type or null
      return _map_to_type_tiny( $data->{ anyOf }->[ 0 ] );
    } elsif ( my $type = $data->{ type } ) {    # Access "type" keyword
      if ( $type eq 'array' ) {
        my $subtype = _map_to_type_tiny( $data->{ items } );
        return "ArrayRef[ $subtype ]"
      } elsif ( defined( my $target_type = $basic_types_map->{ $type } ) ) {
        if ( $type eq 'string' ) {
          my $min_length = $data->{ minLength };
          my $max_length = $data->{ maxLength };
          if ( defined $min_length or defined $max_length ) {
            $target_type = 'StrLength[ ' . ( defined $min_length ? $min_length : '0' );
            $target_type .= ", $max_length" if defined $max_length;
            $target_type .= ' ]'
          }
        } elsif ( $type eq 'integer' ) {
          my $minimum = $data->{ minimum };
          my $maximum = $data->{ maximum };
          if ( defined $minimum or defined $maximum ) {
            $target_type = 'IntRange[ ' . ( defined $minimum ? $minimum : '0' );
            $target_type .= ", $maximum" if defined $maximum;
            $target_type .= ' ]'
          }
        }
        # TODO: Modify target type if type-specific keywords are present
        if ( my $enum_values = $data->{ enum } ) {
          # FIXME: Will work only for bareword enum values.
          $target_type = sprintf 'Enum[ qw( %s ) ]', join( ' ', grep { defined } @$enum_values )
        }
        $target_type .= ' | Undef' if $data->{ nullable };
        return $target_type
      } else {
        croak "Unknown type '$type'"
      }
    }
  }
}

sub _fixup_json_ref ( $;$ ) {
  my ( $root, $curr ) = @_;

  $curr = $root unless @_ == 2;
  if ( ref $curr eq 'ARRAY' ) {
    for my $c ( @$curr ) {
      $c = _fixup_json_ref( $root, $c )
    }
  } elsif ( ref $curr eq 'HASH' ) {
    for my $k ( sort keys %$curr ) {
      if ( $k eq '$ref' ) {
        my $ref = $curr->{ $k };
        # https://github.com/zigorou/perl-json-pointer/issues/10
        $ref =~ s/\A#//;

        my ( $name ) = ( $ref =~ m/\/([^\/]+)\z/ );

        $curr = JSON::Pointer->get( $root, $ref, 1 );

        # Guard against duplicate references to the same data structure (?!)
        croak "two names for $ref: $curr->{ __name } and $name"
          if exists $curr->{ __name } and $name ne $curr->{ __name };

        $curr->{ __name } = $name;

      } else {
        $curr->{ $k } = _fixup_json_ref( $root, $curr->{ $k } )
      }
    }
  } else {
    # nothing to do
  }

  $curr
}

1
