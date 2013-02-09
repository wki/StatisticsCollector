#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install;
use Module::Install::Catalyst; # Complain loudly if you don't have
                               # Catalyst::Devel installed or haven't said
                               # 'make dist' to create a standalone tarball.

name 'StatisticsCollector';
all_from 'lib/StatisticsCollector.pm';

requires 'namespace::autoclean';
requires 'Modern::Perl';
requires 'Catalyst::Runtime' => '5.90003';
requires 'Catalyst::Devel';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'Catalyst::Action::REST';
requires 'Moose';
requires 'Config::General';
requires 'DBIx::Class::DeploymentHandler';
requires 'DBIx::Class::Migration';
requires 'DBIx::Class::Candy';
requires 'DBD::Pg';
requires 'DateTime::Format::Pg';
requires 'Catalyst::View::ByCode';
requires 'Catalyst::Controller::Combine';
requires 'Catalyst::Model::DBIC::Schema';
requires 'HTML::FormFu';
requires 'Catalyst::Controller::HTML::FormFu';
requires 'HTML::FormFu::Model::DBIC';
requries 'MooseX::NonMoose';

# scripts need
requires 'MooseX::Getopt';
requires 'MooseX::Types';

# graph generation
requires 'Imager';         # requires freetype, giflib, libpng, jpeg
requires 'Imager::Graph';

# for CSS generation
requires 'CSS::Minifier::XS';
requires 'Proc::Class';

# for JS generation
requires 'JavaScript::Minifier::XS';

# deployment
requires 'Plack::Builder';
requires 'Plack::Middleware::Runtime';
requires 'Plack::Middleware::ServerStatus::Lite';

test_requires 'Test::More' => '0.88';
test_requires 'Test::Exception';
test_requires 'Test::DBIx::Class';

catalyst_ignore('.*');
catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
