package App::Twpin;
our $VERSION = '0.001';
use strict;
use warnings;
use Tie::File;
use Env qw/HOME/;
use Carp qw/carp croak/;
use Encode qw/encode decode/;

#use Term::ANSIColor qw/:constants/;
use File::Spec::Functions;
use base qw/Exporter/;

our @EXPORT      = qw//;
our @EXPORT_OK   = qw/tw_config tw_update tw_load_config tw_list/;
our %EXPORT_TAGS = (all => [qw/tw_config tw_update tw_load_config tw_list/]);

my $config_file = catfile($HOME, '.twpin');

sub tw_config {
    my %args = @_;
    my @array;
    my %has = (user => 0, pass => 0, apiurl => 0);
    tie @array, 'Tie::File', $config_file or croak $!;
    foreach (@array) {
        if (/^user\s*=/) {
            defined $args{user} and $_ = "user = $args{user}";
            $has{user}++;
        } elsif (/^pass\s*=/) {
            defined $args{pass} and $_ = "pass = $args{pass}";
            $has{pass}++;
        } elsif (/^apiurl\s*=/) {
            defined $args{apiurl} and $_ = "apiurl = $args{apiurl}";
            $has{apiurl}++;
        } else {
            croak "bad configuration file";
        }
    }
    foreach (keys %args) {
        !$has{$_} && push @array, "$_ = $args{$_}";
    }
    untie @array;
}

sub tw_update {
    my $twc = shift;
    foreach my $tweet (@_) {
        eval { $twc->update($tweet) };
        if ($@) {
            tw_error_handle($@);
        } else {
            print("status updated\n");
        }
    }
}

sub tw_list {
    my $twc = shift;
    my $statuses;
    eval { $statuses = $twc->friends_timeline() };
    if ($@) {
        tw_error_handle($@);
    }

    foreach my $status (@$statuses) {
        my $create = (split '\+', $status->{created_at}, 2)[0];
        my $text = encode('utf8', $status->{text});
        print "$status->{user}{screen_name}\t$create\n$text\n\n";
    }

}

sub tw_load_config {

    my (%conf, @array);
    tie @array, 'Tie::File', $config_file or croak $!;

    foreach (@array) {
        /^user\s*=\s*(.*?)\s*$/   and $conf{username} = $1 and next;
        /^pass\s*=\s*(.*?)\s*$/   and $conf{password} = $1 and next;
        /^apiurl\s*=\s*(.*?)\s*$/ and $conf{apiurl}   = $1 and next;
    }

    untie @array;
    return %conf;
}

sub tw_error_handle($) {
    my $error = shift;
    if (bless $error && $error->isa('Net::Twitter::Error')) {
        croak $error->error;
    } else {
        croak "Unknow Exception: $error";
    }
}

1;

__END__
