package StatisticsCollector::Model::DB;
use strict;
use warnings;
use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    # schema_class => 'StatisticsCollector::Schema',
    # 
    # connect_info => {
    #     dsn => $ENV{DSN} // 'dbi:Pg:dbname=statistics',
    #     user => 'postgres',
    #     password => '',
    #     pg_enable_utf8 => 1,
    # },
);


=head1 NAME

StatisticsCollector::Model::DB - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

Wolfgang Kinkeldei

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
