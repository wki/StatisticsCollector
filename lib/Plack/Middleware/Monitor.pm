package Plack::Middleware::Monitor;
use Modern::Perl;
use parent 'Plack::Middleware';
# use Plack::Util::Accessor qw(prefix);
use Monitor::Redis;
use Try::Tiny;

sub prepare_app {
    my $self = shift;

    # die 'prefix missing' if !$self->prefix;

    try {
        $self->{_monitor} = Monitor::Redis->new();
        $self->stop;
    };
}

sub call { # stolen from Plack::Middleware::ServerStatus::Lite
    my ($self, $env) = @_;

    my %request_info = map { ($_ => $env->{$_}) }
                       qw(REMOTE_ADDR REQUEST_METHOD REQUEST_URI 
                          SERVER_NAME SERVER_PROTOCOL
                          );

    $self->start(\%request_info);

    my $res;
    try {
        my $app_res = $self->app->($env);
        if (ref $res eq 'ARRAY') {
            $res = $app_res;
            $self->stop;
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
                    $self->stop;
                };
            };
        }
    } catch {
        $self->stop;
    };

    return $res;
}

sub start {
    my ($self, $data) = @_;
    
    try {
        $self->{_monitor}->start($data);
    };
}

sub stop {
    my $self =shift;
    
    try {
        $self->{_monitor}->stop;
    };
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
