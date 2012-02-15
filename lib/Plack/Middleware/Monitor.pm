package Plack::Middleware::Monitor;
use Modern::Perl;
use parent 'Plack::Middleware';
use Plack::Util::Accessor qw(prefix);
use Path::Class;
# use Monitor;
use RedisDB;
use POSIX 'strftime';
use Try::Tiny;
use List::Util qw(min max);
use JSON::XS;
use Time::HiRes qw(gettimeofday tv_interval);

### will never get called.
sub DESTROY {
    my $self = shift;

    my $redis  = $self->{_redis};
    my $prefix = $self->prefix;

    my $process_key = "$prefix:processes";
    my $worker_key = "$prefix:worker:$$";
    
    $redis->zrem($process_key, $$);
    $redis->del($worker_key);
}

sub prepare_app {
    my $self = shift;

    die 'prefix missing' if !$self->prefix;

    $self->{_redis} = RedisDB->new();
    $self->set_state_stop;
}

sub call { # stolen from Plack::Middleware::ServerStatus::Lite
    my ($self, $env) = @_;

    $self->set_state_start($env);

    my $res;
    try {
        my $app_res = $self->app->($env);
        if (ref $res eq 'ARRAY') {
            $res = $app_res;
            $self->set_state_stop;
        } else {
            $res = sub {
                my $respond = shift;

                my $writer;
                try {
                    $app_res->(sub { return $writer = $respond->(@_) });
                } catch {
                    $writer->close if $writer;
                    die $_;
                } finally {
                    $self->set_state_stop;
                };
            };
        }
    } catch {
        $self->set_state_stop;
    };

    return $res;
}


# sub set_state {
#     my $self = shift;
#     my $flag = shift || '_';
#
#     my $last_status = $self->{_monitor}->load;
#
#     $last_status->{pid}  = $$;
#     $last_status->{flag} = $flag;
#
#     if (my $env = shift) {
#         $last_status->{$_} = $env->{$_}
#             for qw(REQUEST_METHOD REQUEST_URI SERVER_PROTOCOL);
#     }
#
#     if ($flag eq 'A') {
#         $last_status->{started} = [gettimeofday];
#     } elsif ($flag eq '_') {
#         if ($last_status->{started}) {
#             $last_status->{runtime} = tv_interval($last_status->{started}, [gettimeofday]);
#         }
#     }
#
#     $self->{_monitor}->save($last_status);
#
#     $self->count_active_processes if $flags eq 'A';
# }

sub set_state_stop {
    my $self = shift;
    my %attrs = @_;

    my $redis  = $self->{_redis};
    my $prefix = $self->prefix;
    my $now    = strftime('%Y-%m-%d_%H:%M', localtime(time));

    my $worker_key  = "$prefix:worker:$$";
    my $process_key = "$prefix:processes";
    my $minute_key  = "$prefix:$now";

    my $nr_running = $redis->zcount($process_key, 1, 1);
    $redis->zadd($process_key, 0, $$);
    my $nr_workers = $redis->zcard($process_key);

    my $request;
    try { $request = decode_json $redis->get($worker_key) };
    $request //= {};
    
    my $status;
    try { $status = decode_json $redis->get($minute_key) };
    $status //= {};

    $status->{min_nr_running} = min($nr_running, $status->{min_nr_running} // ());
    $status->{max_nr_running} = max($nr_running, $status->{max_nr_running} // ());
    $status->{min_nr_workers} = min($nr_workers, $status->{min_nr_workers} // ());
    $status->{max_nr_workers} = max($nr_workers, $status->{max_nr_workers} // ());
    $status->{nr_requests}++;
    
    if (exists($request->{started})) {
        my $elapsed = tv_interval($request->{started}, [gettimeofday]);
        $status->{min_runtime} = min($elapsed, $status->{min_runtime} // ());
        $status->{max_runtime} = max($elapsed, $status->{max_runtime} // ());
    }

    $redis->set($minute_key, encode_json $status);
}

sub set_state_start {
    my ($self, $env) = @_;

    my $redis  = $self->{_redis};
    my $prefix = $self->prefix;

    my $worker_key  = "$prefix:worker:$$";
    my $process_key = "$prefix:processes";

    my %request = map { ($_ => $env->{$_}) }
                 qw(REQUEST_METHOD REQUEST_URI SERVER_PROTOCOL);

    $request{started} = [gettimeofday];
    $redis->set($worker_key, encode_json \%request);
    $redis->zadd($process_key, 1, $$);
}

1;

__END__

Storage in Redis: All keys prefixed with a constant word identifying the server

  processes        :: sorted set pid => 0/1
    + set to 1 if flag 'A'
    + set to 0 if flag '_'

  worker:<pid>     :: JSON Structure for this worker
    + set with request info if flag 'A'

  yyyy-mm-dd_hh:mm :: Statistics for this minute ()
    + updated if flag '_' -- before process list is updated
