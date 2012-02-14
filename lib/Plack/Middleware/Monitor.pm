package Plack::Middleware::Monitor;
use Modern::Perl;
use parent 'Plack::Middleware';
use Plack::Util::Accessor qw(base_dir);
use Monitor;
use Try::Tiny;
use Time::HiRes qw(gettimeofday tv_interval);

sub prepare_app {
    my $self = shift;

    die 'base_dir missing' if !$self->base_dir;

    $self->{_monitor} = Monitor->new( filename => "${\$self->base_dir}/status_$$.yml" );
    $self->set_state('_');
}

sub call { # stolen from Plack::Middleware::ServerStatus::Lite
    my ($self, $env) = @_;

    $self->set_state('A', $env);

    my $res;
    try {
        my $app_res = $self->app->($env);
        if (ref $res eq 'ARRAY') {
            $res = $app_res;
            $self->set_state('_');
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
                    $self->set_state('_');
                };
            };
        }
    } catch {
        $self->set_state('_');
    };

    return $res;
}


sub set_state {
    my $self = shift;
    my $flag = shift || '_';

    my $last_status = $self->{_monitor}->load;
    
    $last_status->{pid}  = $$;
    $last_status->{flag} = $flag;
    
    if (my $env = shift) {
        $last_status->{$_} = $env->{$_}
            for qw(REQUEST_METHOD REQUEST_URI SERVER_PROTOCOL);
    }

    if ($flag eq 'A') {
        $last_status->{started} = [gettimeofday];

        ### TODO: check nr workers
    } elsif ($flag eq '_') {
        if ($last_status->{started}) {
            $last_status->{runtime} = tv_interval($last_status->{started}, [gettimeofday]);
        }
    }

    $self->{_monitor}->save($last_status);
}

1;
