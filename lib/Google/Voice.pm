package Google::Voice;

use strict;
use warnings;

use Mojo::UserAgent;
use Mojo::JSON;
use IO::Socket::SSL 1.37;

use Google::Voice::Feed;
use Google::Voice::Call;

use Mojo::Base -base;

our $VERSION = 0.06;

__PACKAGE__->attr([qw/ ua rnr_se /]);

sub new {
    my $self = bless {}, shift;

    $self->ua(Mojo::UserAgent->new);

    return $self;
}

sub login {
    my $self = shift;
    my ($user, $pass) = @_;
    my $c = $self->ua;

    $c->max_redirects(6);    # Google seems to like redirects everywhere

    # GALX value
    my $el =
      $c->get('https://accounts.google.com/ServiceLogin')
      ->res->dom->at('input[name="GALX"]');

    my $galx = $el->attr->{value} if $el;

    $c->post(
        'https://accounts.google.com/ServiceLogin',
        form => {   Email  => $user,
            Passwd => $pass,
            GALX   => $galx,
        }
    );

    # rnr_se required for subsequent requests
    $el =
      $c->get('https://www.google.com/voice#inbox')
      ->res->dom->at('input[name="_rnr_se"]');

    # Login not accepted
    return unless $el;

    $self->rnr_se($el->attr->{value});

    return $self;
}

sub send_sms {
    my $self = shift;
    my $c    = $self->ua;
    my ($phone, $content) = @_;

    my $json = $c->post(
        'https://www.google.com/voice/b/0/sms/send',
        form => {   id          => undef,
            phoneNumber => $phone,
            text        => $content || '',
            _rnr_se     => $self->rnr_se
        }
    )->res->json;

    $@ = $json->{data}->{code} and return unless $json->{ok};

    return $json->{ok};
}

for my $feed (
    qw/ all starred spam trash voicemail
    sms recorded placed received missed /
  )
{

    no strict 'refs';
    *{"Google::Voice::${feed}"} = sub {
        shift->feed('https://www.google.com/voice/inbox/recent/' . $feed);
    };
}

sub feed {
    my $self = shift;
    my $url  = shift;

    my $c = $self->ua;

    # Multiple conversations
    my $inbox = $c->get($url)->res->dom;

    # metadata
    my $meta = Mojo::JSON->new->decode($inbox->at('response > json')->text);

    # content
    my $xml = Mojo::DOM->new->parse($inbox->at('response > html')->text);

    # Each conversation in a span.gc-message
    return map
      Google::Voice::Feed->new($_, $meta, $self->rnr_se, $c),
      @{$xml->find('.gc-message')};
}

sub call {
    my $self = shift;
    my ($from, $to) = @_;

    my $json = $self->ua->post(
        'https://www.google.com/voice/call/connect',
        form => {
            forwardingNumber => $from,
            outgoingNumber   => $to,
            phoneType        => 1,
            remember         => 0,
            _rnr_se          => $self->rnr_se
        }
    )->res->json;

    $@ = $json->{error} and return unless $json->{ok};

    return Google::Voice::Call->new(@_, $self->rnr_se, $self->ua);
}

1;

=head1 NAME

Google::Voice - Easy interface for google voice

=head1 DESCRIPTION

Easy interface for google voice

=head1 USAGE

    use Google::Voice;

    my $g = Google::Voice->new->login('username', 'password');

    # Send sms
    $g->send_sms(5555555555 => 'Hello friend!');

    # Error code from google on fail
    print $@ if !$g->send_sms('invalid phone' => 'text message');

    # connect call & cancel it
    my $call = $g->call('+15555555555' => '+14444444444');
    $call->cancel;


    # Print all sms conversations
    foreach my $sms ($g->sms) {
        print $sms->name;
        print $_->time, ':', $_->text, "\n" foreach $sms->messages;

        # Delete conversation
        $sms->delete;
    }

    # loop through voicemail messages
    foreach my $vm ($g->voicemail) {

        # Name, number, and transcribed text
        print $vm->name . "\n";
        print $vm->meta->{phoneNumber} . "\n";
        print $vm->text . "\n";

        # Download mp3
        $vm->download->move_to($vm->id . '.mp3');

        # Delete
        $vm->delete;
    }

=head1 METHODS

=head2 new

Create object

=head2 login

Login.  Returns object on success, false on failure.

=head2 call

Connect two phone numbers

=head2 send_sms

Send SMS message.  Returns true/false.

=head2 sms

List of SMS messages

=head2 voicemail

List of voicemail messages

=head2 recorded

List of recorded calls

=head2 placed

List of placed calls

=head2 received

List of placed calls

=head2 missed

List of missed calls

=head2 starred

List of starred items (call, sms, or voicemail)

=head2 spam

List of items marked as spam (call, sms, or voicemail)

=head2 all

List of all items (call, sms, or voicemail)

=head1 SEE ALSO

L<Mojo::UserAgent>, L<Mojo::DOM>

=head1 DEVELOPMENT

L<http://github.com/tempire/perl-google-voice>

=head1 AUTHOR

Glen Hinkle tempire@cpan.org

=head1 CREDITS

David Jones

Graham Forest

=cut
