use strict;
use warnings;

package OpenAPI::ModelMapper;

$OpenAPI::ModelMapper::VERSION = 'v1.0.0';

use subs qw( build_class fixup_json_ref map_to_type_tiny );

use Carp                  qw( croak );
use Exporter              qw( import );
use File::Spec::Functions qw( catfile );
use File::ShareDir        qw( module_dir );
use JSON::Pointer         ();
use Path::Tiny            qw( path );         # FIXME: try to get rid of Path::Tiny
use Text::Template        ();

our @EXPORT_OK = qw( build_class fixup_json_ref map_to_type_tiny );

sub build_class ( $$$ ) {
  # $name doesn't refer to a package name it is a lookup key
  my ( $root, $name, $tempdir ) = @_;

  # Assume that the ENCODING of the template file (the SOURCE) is UTF-8
  my $template =
       Text::Template->new( ENCODING => 'UTF-8', SOURCE => catfile( module_dir( __PACKAGE__ ), 'Moo-class.tmpl' ) ),
    or croak "Couldn't construct template: $Text::Template::ERROR";

  my $schema           = $root->{ components }->{ schemas }->{ $name };
  my $class_filehandle = path( $tempdir, 'Model' )->mkdir->child( "$name.pm" )->openw_utf8;
  $template->fill_in(
    HASH   => [ { namespace => "Model::$name", isa => \&map_to_type_tiny }, $schema ],
    OUTPUT => $class_filehandle
  ) or croak "Couldn't fill in template: $Text::Template::ERROR";

  # success
  1
}

{
  my $basic_types_map = {
    integer => 'Int',
    string  => 'Str'
    #number => 'Num',
    #boolean => '', # a conflict between JSON::PP::Boolean and Type::Tiny
    #object  => 'HashRef',
  };

  sub map_to_type_tiny ( $ ) {
    my ( $data ) = @_;

    # FIXME: "allOf" not implemented yet
    if ( exists $data->{ anyOf } ) {
      # FIXME: Not properly impelemted. We need a kind of union here
      # ... so we have a multi-type. Hope that it is just a type or null
      return map_to_type_tiny( $data->{ anyOf }->[ 0 ] );
    } elsif ( my $type = $data->{ type } ) {    # Access "type" keyword
      if ( $type eq 'array' ) {
        my $subtype = map_to_type_tiny( $data->{ items } );
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

sub fixup_json_ref ( $;$ ) {
  my ( $root, $curr ) = @_;

  $curr = $root unless @_ == 2;
  if ( ref $curr eq 'ARRAY' ) {
    for my $c ( @$curr ) {
      $c = fixup_json_ref( $root, $c )
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
        $curr->{ $k } = fixup_json_ref( $root, $curr->{ $k } )
      }
    }
  } else {
    # nothing to do
  }

  $curr
}

1
