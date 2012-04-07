use strict;
use warnings;
use AnyEvent::Twitter::Stream;
use AnyEvent::HTTP;
use AnyEvent::Twitter;
use Encode qw/encode_utf8 decode_utf8/;
use URI::Escape;

use TwitterTranslate::Config;
my $config = TwitterTranslate::Config->load;

my $bing_url = "http://api.microsofttranslator.com/V2/Ajax.svc/Translate?appId=$config->{bing_appid}&from=en&to=ja&text=";

my $ua = AnyEvent::Twitter->new(
    %{$config->{twitter_app}},
    %{$config->{twitter_ja}},
);

my $cv = AE::cv;
my $listener = AnyEvent::Twitter::Stream->new(
    %{$config->{twitter_app}},
    %{$config->{twitter_en}},
    method  => 'filter',
    follow => $config->{twitter_en}->{user_id}, 
    on_tweet => sub {
        my ($tweet) = @_;

        my $id = $tweet->{id};
        my $user = $tweet->{user}{screen_name};
        my $text = encode_utf8($tweet->{text} || '');
        return unless $id && $user && $text;
        return if($tweet->{user}{id} ne $config->{twitter_en}->{user_id});

        my $url = $bing_url . uri_escape($text);
        http_get $url, sub {
            my $data = shift;
            print "$text\n";
            print " -> $data\n";

#            my $org_url = "https://twitter.com/#!/$user/status/$id";
            my $post = $data . " (\@$user)";
            $ua->post('statuses/update', {
                status => decode_utf8($post),
                in_reply_to_status_id => $id,
            }, sub {
                my ($header, $response, $reason) = @_;
                $cv->end;
            });
            $cv->end;
        };
    },
);
$cv->recv;
