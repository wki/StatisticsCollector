package StatisticsCollector::Schema::Result::AlarmCondition;
use feature ':5.10';
use DBIx::Class::Candy -components => [ qw(DynamicDefault) ];

table 'alarm_condition';

primary_column alarm_condition_id => {
    data_type => 'int',
    is_auto_increment => 1,
};

#
# a valid likehood mask '%/whatever/temperature'
#
column sensor_mask => {
    data_type => 'text',
    is_nullable => 0,
};

#
# maximum age of measure in minutes
#
column max_measure_age_minutes => {
    data_type => 'int',
    is_nullable => 1,
};

#
# assert that latest value is greater than this
#
column latest_value_gt => {
    data_type => 'int',
    is_nullable => 1,
};

#
# assert that latest value is less than this
#
column latest_value_lt => {
    data_type => 'int',
    is_nullable => 1,
};

#
# assert that minimum value is greater than this
#
column min_value_gt => {
    data_type => 'int',
    is_nullable => 1,
};

#
# assert that maximum value is less than this
#
column max_value_lt => {
    data_type => 'int',
    is_nullable => 1,
};

#
# TODO: do we need a severity (1=INFO/2=WARNING/3=ERROR/4=FATAL) ???
#
column severity_level => {
    data_type => 'int',
    is_nullable => 0,
    default_value => 2,
};

#
# TODO: do we need a specificity (order of testing) ???
#
column specificity => {
    data_type => 'int',
    is_nullable => 0,
    default_value => 0,
    dynamic_default_on_create => \&calculate_specificity_from_mask,
    dynamic_default_on_update => \&calculate_specificity_from_mask,
};

sub calculate_specificity_from_mask {
    my $self = shift;
    
    my $specificity = 8;
    
    given ($self->sensor_mask) {
        $specificity = 7 when m{\A % / [^%]+ \z}xms;
        $specificity = 6 when m{\A [^%]+ / % / [^%]+ \z}xms;
        $specificity = 5 when m{\A [^%]+ / % \z}xms;
        $specificity = 4 when m{\A % / % / [^%]+ \z}xms;
        $specificity = 3 when m{\A % / [^%]+ / % \z}xms;
        $specificity = 2 when m{\A [^%]+ / % / % \z}xms;
        $specificity = 1 when m{\A % / % / % \z}xms;
    }
    
    return $specificity;
}

1;

__END__

order of alarm conditions
-------------------------

most important (most specific)
  8: erlangen/keller/temperatur

medium specific
  7: %/keller/temperatur
  6: erlangen/%/temperatur
  5: erlangen/keller/%

low specific
  4: %/%/temperatur
  3: %/keller/%
  2: erlangen/%/%

unspecific
  1: %/%/%

not defined
  0: ?


testing
-------

- search all alarm conditions with matching masks
- sort by severity (desc) and then by specificity (desc)
- for every severity only keep the first (highest specificity value)
- the highest severity giving an alarm wins
