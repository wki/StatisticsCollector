#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install;
use Module::Install::Catalyst; # Complain loudly if you don't have
                               # Catalyst::Devel installed or haven't said
                               # 'make dist' to create a standalone tarball.

name 'StatisticsCollector';
all_from 'lib/StatisticsCollector.pm';

requires 'Catalyst::Runtime' => '5.90003';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'Catalyst::Action::REST';
requires 'Moose';
requires 'namespace::autoclean';
requires 'Config::General';
requires 'Proc::Class';
requires 'DBIx::Class::DeploymentHandler';
requires 'Catalyst::View::ByCode';
requires 'Catalyst::Controller::Combine';
requires 'Imager';
requires 'Imager::Graph';

test_requires 'Test::More' => '0.88';
test_requires 'Test::Exception';
test_requires 'Test::DBIx::Class';

catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
