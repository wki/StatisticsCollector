package StatisticsCollector::Schema::Result::TestMe;

use DBIx::Class::Candy
    -components => [qw(InflateColumn::DateTime)];

__PACKAGE__->table_class('StatisticsCollector::Schema::ResultSource::Foo');


=head1 TABLE

virtual_testme (virtual table)

=cut

table 'virtual_testme';

=head1 COLUMNS

=cut

=head2 sensor_id

=cut

column sensor_id => {
    data_type => 'int',
    is_nullable => 0,
};

=head2 name

=cut

column name => {
    data_type => 'text',
    is_nullable => 0,
};



__PACKAGE__->result_source_instance->is_virtual(1);

1;
