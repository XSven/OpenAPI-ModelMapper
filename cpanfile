use strict;
use warnings;

on configure => sub {
  requires 'ExtUtils::MakeMaker'           => '6.76';    # Offers the RECURSIVE_TEST_FILES feature
  requires 'ExtUtils::MakeMaker::CPANfile' => '0';       # Needs at least ExtUtils::MakeMaker 6.52
  requires 'File::ShareDir::Install'       => '0';
  requires 'File::Spec'                    => '0';
  requires 'strict'                        => '0';
  requires 'warnings'                      => '0'
};

on runtime => sub {
  requires 'Carp'           => '0';
  requires 'Exporter'       => '0';
  requires 'JSON::Pointer'  => '0';
  requires 'Path::Tiny'     => '0';
  requires 'Text::Template' => '0';
  requires 'strict'         => '0';
  requires 'warnings'       => '0'
};

on test => sub {
  requires 'Test::Fatal'          => '0';
  requires 'Test::File::Contents' => '0';
  requires 'Test::File::ShareDir' => '0';
  requires 'Test::Lib'            => '0';
  requires 'Test::More'           => '1.001005';    # Subtests accept args
  requires 'Test::TempDir::Tiny'  => '0';
  requires 'Moo'                  => '0';
  requires 'Type::Tiny'           => '0';
  requires 'YAML::XS'             => '0.67'
}
