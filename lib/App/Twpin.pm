package App::Twpin;
use strict;
use warnings;
use Tie::File;
use Env qw/HOME/;
use Carp qw/carp croak/;
use Scalar::Util qw/blessed/;
use File::Spec::Functions;
use Encode qw/encode decode is_utf8/;
use base qw/Exporter/;

our $VERSION = 0.002;

our @EXPORT = qw//;
our @EXPORT_OK =
  qw/tw_config tw_update tw_load_config tw_list tw_get_follower tw_get_following tw_follow/;
our %EXPORT_TAGS = (
    all => [
        qw/tw_config tw_update tw_load_config tw_list tw_get_follower tw_get_following tw_follow/
    ]
);

my $config_file = catfile($HOME, '.twpinrc');

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
        } elsif (/^\s*$/) {
            next;
        } else {
            croak "bad configuration: '$_' ";
        }
    }
    foreach (keys %args) {
        !$has{$_} && push @array, "$_ = $args{$_}";
    }
    untie @array;
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
    if (!defined $conf{username} || !defined $conf{password}) {
        croak "Error: username or password missing\n";
    }
    return %conf;
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
    tw_error_handle($@) if ($@);

    foreach my $status (@$statuses) {
        my $create = (split '\+', $status->{created_at}, 2)[0];
        print _($status->{user}{screen_name}), "\t", _($create), "\n",
          _($status->{text}), "\n\n";
    }

}

sub tw_get_follower {
    my $twc = shift;
    my $followers;
    eval { $followers = $twc->followers() };
    tw_error_handle($@) if $@;
    print scalar @$followers, " followers received from twitter\n\n";
    foreach my $follower (@$followers) {
        printf("%-15s\t%-15s",
            _($follower->{name}),
            _($follower->{screen_name}));
        printf("\t%s", _($follower->{location}))
          if defined $follower->{location};
        print "\n";
    }
}

sub tw_get_following {
    my $twc = shift;
    my $following;
    eval { $following = $twc->friends() };
    tw_error_handle($@) if $@;
    print scalar @$following, " followings received from twitter\n\n";
    foreach my $friend (@$following) {
        printf("%-15s\t%-15s", _($friend->{name}), _($friend->{screen_name}));
        printf("\t%s", _($friend->{location})) if defined $friend->{location};
        print "\n";
    }
}

sub tw_error_handle($) {
    my $error = shift;
    if (blessed $error && $error->isa('Net::Twitter::Error')) {
        print STDERR $error->error, "\n";
        exit;
    } else {
        croak "Unknow Exception: $error";
    }
}

sub tw_follow {
    my ($twc, $screen_name) = @_;
    my $friend;
    eval { $friend = $twc->create_friend($screen_name) };
    tw_error_handle($@) if $@;
    print "OK, you are now following:\n";
    printf("%-15s\t%-15s", _($friend->{name}), _($friend->{screen_name}));
    printf("\t%s", _($friend->{location})) if defined $friend->{location};
    print "\n";
}

sub _ {
    my $string = shift;
    if (is_utf8($string)) {
        $string = encode 'utf8', $string;
    }
    return $string;
}

1;

__END__
