use strict;
use warnings;

use Test::More;
use Test::Mojo;
use Data::Dumper;
use Google::Voice;

my $name = $ENV{GVNAME};
my @auth = ($ENV{GVUSER}, $ENV{GVPASS});
my $phone = $ENV{GVPHONE};

my $vm_name = $ENV{EXISTING_VOICEMAIL_NAME};
my $vm_phone = $ENV{EXISTING_VOICEMAIL_PHONE};

my $from_phone = $ENV{FROM_PHONE};
my $to_phone = $ENV{TO_PHONE};

# Login
ok ! Google::Voice->new->login, 'no auth';
ok my $g = Google::Voice->new->login( @auth ), 'correct auth';

# voicemail inbox
ok my $vm = ($g->voicemail_inbox)[0], 'voicemail inbox';
is $vm->name, $vm_name, 'name';
is $vm->meta->{phoneNumber}, $vm_phone, 'phone';
like $vm->text, qr/^[\w\s\.',]+$/, 'transcription';

# download voicemail
ok my $asset = $vm->download, 'voicemail';
ok $asset->size, $asset->size . ' bytes';

# sms
ok ! $g->send_sms( 'invalid #' => 'message' ), 'sms fail';
is $@, 20, 'error';
ok $g->send_sms( $phone => 'A' ), 'sms';

# sms inbox
ok my $conv = ($g->sms_inbox)[0], 'sms inbox';
like $conv->id, qr/^\w{40}$/, 'id';
is $conv->name, $name, 'name';
is $conv->meta->{phoneNumber}, $phone, 'phone';

# two messages in conversation
my @m = $conv->messages;
cmp_ok @m, '>=', 2, 'at least 2 messages';

ok $m[0]->inbound, 'inbound';
ok ! $m[0]->outbound, 'not inbound';
like $m[0]->time, qr/^\d{1,2}:\d{2} \w{2}$/, 'time';
is $m[0]->text, 'A', 'text';

ok $m[1]->outbound, 'outbound';
ok ! $m[1]->inbound, 'not inbound';
like $m[1]->time, qr/^\d{1,2}:\d{2} \w{2}$/, 'time';
is $m[1]->text, 'A', 'text';

ok $conv->latest->outbound, 'latest message';

# delete conversation
my $id = $conv->id;
#ok $g->delete( $conv ), 'delete';
ok $conv->delete, 'delete';
isnt +($g->sms_inbox)[0]->id, $id, 'deleted';

# call
ok ! $g->call('invalid #' => 'invalid #'), 'invalid phone numbers';
is $@, 'Cannot complete call.', 'error';
ok my $call = $g->call($from_phone => $to_phone), 'call';
ok $call->cancel, 'cancel';

done_testing;
