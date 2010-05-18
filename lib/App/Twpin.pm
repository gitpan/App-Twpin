package App::Twpin;
use strict;
use warnings;
use Tie::File;
use Env qw/HOME/;
use FindBin qw/$Bin/;
use Carp qw/carp croak/;
use Scalar::Util qw/blessed/;
use File::Spec::Functions;
use Encode qw/encode decode is_utf8 find_encoding/;
use base qw/Exporter/;

our $VERSION = 0.005;

our @EXPORT = qw//;
our @EXPORT_OK =
  qw/tw_config tw_update tw_load_config tw_list tw_get_follower tw_get_following tw_follow tw_unfollow/;
our %EXPORT_TAGS = (
    all => [
        qw/tw_config tw_update tw_load_config tw_list tw_get_follower tw_get_following tw_follow tw_unfollow/
    ]
);

my $config_file = catfile($HOME, '.twpinrc');
if ($^O eq 'MSWin32') {
	$config_file = catfile($Bin, '.twpinrc');
}

sub tw_config {
    my %args = @_;
    my @array;
    my %has = (user => 0, pass => 0, apiurl => 0, encode => 0);
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
        } elsif (/^encode\s*=/) {
            defined $args{encode} and $_ = "encode = $args{encode}";
            $has{encode}++;
        } elsif (/^\s*$/) {
            next;
        } else {
            croak "bad configuration: '$_' ";
        }
    }
    foreach (keys %args) {
        !$has{$_} && push @array, "$_ = $args{$_}";
    }
    print "configuration updated\n";
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
    my $twc    = shift;
    my $encode = _term_encoding();
    foreach my $tweet (@_) {
        eval { $twc->update(decode($encode, $tweet)) };
        if ($@) {
            _error_handle($@);
        } else {
            print("status updated\n");
        }
    }
}

sub tw_list {
    my $twc = shift;
    my $statuses;
    eval { $statuses = $twc->friends_timeline() };
    _error_handle($@) if ($@);

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
    _error_handle($@) if $@;
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
    _error_handle($@) if $@;
    print scalar @$following, " followings received from twitter\n\n";
    foreach my $friend (@$following) {
        printf("%-15s\t%-15s", _($friend->{name}), _($friend->{screen_name}));
        printf("\t%s", _($friend->{location})) if defined $friend->{location};
        print "\n";
    }
}

sub _error_handle($) {
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
    _error_handle($@) if $@;
    print "OK, you are now following:\n";
    printf("%-15s\t%-15s", _($friend->{name}), _($friend->{screen_name}));
    printf("\t%s", _($friend->{location})) if defined $friend->{location};
    print "\n";
}

sub tw_unfollow {
    my ($twc, $screen_name) = @_;
    eval { $twc->destroy_friend($screen_name) };
    _error_handle($@) if $@;
    print("unfollowed\n");
}

sub _term_encoding {
    my ($encode, @array);
    tie @array, 'Tie::File', $config_file or croak $!;

    foreach (@array) {
        /^encode\s*=\s*(.*?)\s*$/ and $encode = $1 and last;
    }
    return 'utf8' unless defined $encode;
    croak "Unknow encoding $encode" unless ref(find_encoding($encode));
    return $encode;
}

sub _ {
    my $string = shift;
    if (is_utf8($string)) {
        $string = encode _term_encoding(), $string;
    }
    return $string;
}

1;

__END__

=head1 NAME

twpin - Just Another Command Line Twitter Client

=head1 VERSION

version 0.005

=head1 SYNOPSIS
    
    twpin config -u username -p password
    twpin config -a 'http://url/twip'
    twpin update "hello twitter"
    twpin follow perl_api
    twpin status
    twpin help

=head1 DESCRIPTION

C<twpin> is a script for you to access twitter from command line

twip L<http://code.google.com/p/twip/> is a twitter API proxy in PHP. This script is created mainly because I can not find a good twitter client that supports this proxy 

Configration file is located at $HOME/.twpinrc, you can just edit this file and add your username/password there.

By default, the term encoding is set to utf8. If you are using other encodings, set 'encode = STH' in the configuration file(or use 'twpin config -e').

=head1 AUTHOR

woosley.xu<redicaps@gmail.com>

=head1 COPYRIGHT & LICENSE

This software is copyright (c) 2010 by woosley.xu.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.