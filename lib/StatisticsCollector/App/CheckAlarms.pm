package StatisticsCollector::App::CheckAlarms;
use Modern::Perl;
use Moose;
use Try::Tiny;
use DateTime;

extends 'StatisticsCollector::App';
with 'StatisticsCollector::Role::Schema';

my $DEFAULT_EMAIL = 'wolfgang@kinkeldei.de';
my $RE_NOTIFY_AGE = 3600;

=head1 NAME

StatisticsCollector::App::CheckAlarms - Check if sensor alarms are changing

=head1 SYNOPSIS

    StatisticsCollector::App::CheckAlarms->new_with_options->run();

=head1 DESCRIPTION

This is the class behind a shell-executable script to check alarms

=head1 METHODS

=cut

=head2 run

called from L<StatisticsCollector::App> in order to run the script

=cut

sub run {
    my $self = shift;

    my $alarms_to_notify =
        $self->resultset('Alarm')
             ->check_and_update
             ->need_notification;

    my %alarms_for_person; # { person_email => { new, open, closed } }
    while (my $alarm = $alarms_to_notify->next) {
        my $status = $alarm->get_column('status');
        my $mailto = $alarm->alarm_condition->notify_email // $DEFAULT_EMAIL;

        $self->log_debug($status,
                         $alarm->ending_at // $alarm->starting_at,
                         $alarm->sensor->name,
                         '-->', $mailto
                         );

        push @{$alarms_for_person{$mailto}->{$status}}, $alarm;
    }
    
    $self->notify_alarms_for_person_if_needed($_, $alarms_for_person{$_})
        for keys %alarms_for_person;
}

sub notify_alarms_for_person_if_needed {
    my ($self, $person_email, $alarms) = @_;
    
    if ($self->must_notify($alarms)) {
        $self->log_dryrun("would notify '$person_email'") and return;
        $self->notify_alarms_for_person($person_email, $alarms);
        $self->save_alarm_notification($alarms);
    } else {
        $self->log("no need to notify '$person_email'");
    }
}

sub must_notify {
    my ($self, $alarms) = @_;
    
    return 1 if exists $alarms->{new} || exists $alarms->{closed};
    return   if !exists $alarms->{open}; # should never happen
    return grep { 
                my $age = $_->get_column('notify_age');

                !$age || $age > $RE_NOTIFY_AGE
           }
           @{$alarms->{open}};
}

sub _shorten {
    my $text = shift;
    my $length = shift // 20;
    
    substr($text,$length) = '...' if length $text > $length;
    
    return $text;
}

sub notify_alarms_for_person {
    my ($self, $person_email, $alarms) = @_;
    
    my @mail_lines;
    foreach my $state (qw(closed new open)) {
        next if !exists $alarms->{$state};
        
        my $s = scalar @{$alarms->{$state}} > 1 ? 's' : '';
        push @mail_lines,
             "$state Alarm$s:",
             (
                map {
                    my $at        = $_->ending_at // $_->starting_at;
                    my $sensor    = _shorten($_->sensor->name, 25);
                    my $condition = _shorten($_->alarm_condition->name, 16);
                 
                    sprintf('  %-30s %s %s - %s',
                            $sensor,
                            $at->ymd, $at->hms,
                            $condition)
                } @{$alarms->{$state}}
             ),
             '';
    }
    
    my $mail_text = <<MAIL;
Hello Statistics-Collector,

There are some alarm changes you should know:

${\join("\n", @mail_lines)}

please visit the statistics-collector website to see more.

Regards, the alarm-watcher

MAIL

    say "mailto: $person_email";
    say $mail_text;
}

sub save_alarm_notification {
    my ($self, $alarms) = @_;
    
    my @alarm_ids =
        map { $_->alarm_id }
        map { @$_ }
        values %{$alarms};
    
    $self->resultset('Alarm')
         ->search( { alarm_id => { -in => \@alarm_ids } } )
         ->update( { last_notified_at => DateTime->now( time_zone => 'local' ) } );
}

__PACKAGE__->meta->make_immutable;

1;

=head1 SEE ALSO

L<StatisticsCollector>

=head1 AUTHOR

Wolfgang Kinkeldei

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
