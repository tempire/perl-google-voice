use strict;
use warnings;

use Test::More;
use Test::Mojo;
use Google::Voice;

plan skip_all => 'Set TEST_ONLINE environment variable to enable tests. '
  . 'Requires an active Google Voice account. '
  . 'See t/voice.t to set appropriate environment variables.'
  unless $ENV{TEST_ONLINE};

warn
  'NOTE: Environment variables must be set in t/voice.t for tests to succeed';

plan tests => 50;

# Full name on account
my $name  = $ENV{GVNAME};
my @auth  = ($ENV{GVUSER}, $ENV{GVPASS});
my $phone = $ENV{GVPHONE};                  # format: +15555555555

# Lastest voicemail
my $vm_name  = $ENV{EXISTING_VOICEMAIL_NAME};
my $vm_phone = $ENV{EXISTING_VOICEMAIL_PHONE};    # format: +15555555555

# Latest recording
my $rec_name  = $ENV{EXISTING_RECORDED_NAME};
my $rec_phone = $ENV{EXISTING_RECORDED_PHONE};    # format: +15555555555

# Real phone numbers to place sample call - real phones may ring
my $from_phone = $ENV{FROM_PHONE};                # format: +15555555555
my $to_phone   = $ENV{TO_PHONE};                  # format: +15555555555


# Login
ok !Google::Voice->new->login, 'no auth';
ok my $g = Google::Voice->new->login(@auth), 'correct auth';

# voicemail inbox
ok my $vm = ($g->voicemail)[0], 'voicemail inbox';
is $vm->name, $vm_name, 'name';
is $vm->meta->{phoneNumber}, $vm_phone, 'phone';
like $vm->text, qr/^[\w\s\.',]+$/, 'transcription';

# download voicemail
ok my $asset = $vm->download, 'voicemail';
ok $asset->size, $asset->size . ' bytes';

# sms
ok !$g->send_sms('invalid #' => 'message'), 'sms fail';
is $@, 20, 'error';
ok $g->send_sms($phone => 'A'), 'sms';

# sms inbox
ok my $conv = ($g->sms)[0], 'sms inbox';
like $conv->id, qr/^\w{40}$/, 'id';
is $conv->name, $name, 'name';
is $conv->meta->{phoneNumber}, $phone, 'phone';

# two messages in conversation
my @m = $conv->messages;
cmp_ok @m, '>=', 2, 'at least 2 messages';

ok $m[0]->inbound, 'inbound';
ok !$m[0]->outbound, 'not inbound';
like $m[0]->time, qr/^\d{1,2}:\d{2} \w{2}$/, 'time';
is $m[0]->text, 'A', 'text';

ok $m[1]->outbound, 'outbound';
ok !$m[1]->inbound, 'not inbound';
like $m[1]->time, qr/^\d{1,2}:\d{2} \w{2}$/, 'time';
is $m[1]->text, 'A', 'text';

ok $conv->latest->outbound, 'latest message';

# delete conversation
my $id = $conv->id;
ok $conv->delete, 'delete';
isnt + ($g->sms)[0]->id, $id, 'deleted';

# call
ok !$g->call('invalid #' => 'invalid #'), 'invalid phone numbers';
is $@, 'Cannot complete call.', 'error';
ok my $call = $g->call($from_phone => $to_phone), 'call';
ok $call->cancel, 'cancel';

# special feeds
ok + ($g->all)[0],  'all feed';
ok + ($g->spam)[0], 'spam feed';

# all other feeds
for my $feed (qw/ recorded placed received missed starred trash /) {
    ok my $node = ($g->$feed)[0], "$feed feed item";
    is $node->type, $feed, 'type';
}

# call recording
ok my $node = ($g->recorded)[0], 'recorded calls';
is $node->name, $rec_name, 'name';
is $node->meta->{phoneNumber}, $rec_phone, 'phone';

# download recording
ok $asset = $node->download, 'recording';
ok $asset->size, $asset->size . ' bytes';
