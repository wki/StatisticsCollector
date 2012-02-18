package Monitor::Redis;
use Moose;
use RedisDB;
use POSIX 'strftime';
use JSON::XS;
use List::Util qw(min max);
use Time::HiRes qw(gettimeofday tv_interval);
use Try::Tiny;
use namespace::autoclean;

has prefix => (
    is => 'rw',
    isa => 'Str',
    default => 'statistics',
);

has id => (
    is => 'rw',
    isa => 'Str',
    default => sub { $$ },
);

has redis => (
    is => 'rw',
    isa => 'RedisDB',
    default => sub { RedisDB->new() },
    lazy => 1,
);

has is_running => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

has start_timestamp => (
    is => 'rw',
    isa => 'ArrayRef',
    predicate => 'has_start_timestamp',
);

sub process_key {
    my $self = shift;

    return join(':', $self->prefix, 'processes');
}

sub worker_key {
    my $self = shift;
    my $worker = shift // $self->id;

    return join(':', $self->prefix, 'worker', $worker);
}

sub minute_key {
    my $self = shift;

    return join(':', $self->prefix, strftime('%Y-%m-%d_%H:%M', localtime(time)));
}

sub DEMOLISH {
    my $self = shift;

    $self->redis->zrem($self->process_key, $self->id);
    $self->redis->del($self->worker_key);
}

sub start {
    my ($self, $data) = @_;

    $self->is_running(1);
    $self->start_timestamp( [gettimeofday] );

    $self->redis->set($self->worker_key, encode_json $data);
    $self->redis->expire($self->worker_key, 15 * 60); # keep for 15 minutes
    $self->redis->zadd($self->process_key, 1, $self->id);
}

sub stop {
    my $self = shift;

    $self->is_running(0);
    $self->_cleanup_process_list;
    my $status = $self->_determine_process_status;
    $self->redis->set($self->minute_key, encode_json $status);
    $self->redis->expire($self->minute_key, 24 * 60 * 60); # keep for 24 hours --> 300 KB memory
}

sub _cleanup_process_list {
    my $self = shift;
    
    my $processes = $self->redis->zrangebyscore($self->process_key, 0, 1);
    if ($processes && ref $processes eq 'ARRAY') {
        foreach my $process (@$processes) {
            if (!$self->redis->exists($self->worker_key($process))) {
                $self->redis->zrem($self->process_key, $process);
            }
        }
    }
}

sub _determine_process_status {
    my $self = shift;
    
    my $nr_running = $self->redis->zcount($self->process_key, 1, 1);
    $self->redis->zadd($self->process_key, 0, $self->id);
    my $nr_workers = $self->redis->zcard($self->process_key);

    my $status;
    try { $status = decode_json $self->redis->get($self->minute_key) };
    $status //= {};

    $status->{min_nr_running} = min($nr_running, $status->{min_nr_running} // ());
    $status->{max_nr_running} = max($nr_running, $status->{max_nr_running} // ());
    $status->{min_nr_workers} = min($nr_workers, $status->{min_nr_workers} // ());
    $status->{max_nr_workers} = max($nr_workers, $status->{max_nr_workers} // ());
    
    if ($self->has_start_timestamp) {
        my $elapsed = tv_interval($self->start_timestamp, [gettimeofday]);
        $status->{min_runtime} = min($elapsed, $status->{min_runtime} // ());
        $status->{max_runtime} = max($elapsed, $status->{max_runtime} // ());
        $status->{nr_requests}++;
    }
    
    return $status;
}

__PACKAGE__->meta->make_immutable;

1;
