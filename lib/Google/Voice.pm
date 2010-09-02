package Google::Voice;

use strict;
use warnings;

use Mojo::Client;
use Mojo::JSON;
use IO::Socket::SSL;
use Data::Dumper;

use Google::Voice::SMS;
use Google::Voice::VM;
use Google::Voice::Call;

use base 'Mojo::Base';

__PACKAGE__->attr( [ qw/ client rnr_se / ] );

sub new {
	my $self = bless {}, shift;

	$self->client( Mojo::Client->new );

	return $self;
}

sub login {
	my $self = shift;
	my ($user, $pass) = @_;
	my $c = $self->client;

	# GALX value
	my $el = $c->get('https://www.google.com/accounts/ServiceLogin')
		->res->dom->at('input[name="GALX"]');
	
	my $galx = $el->attrs->{value} if $el;

	$c->post_form('https://www.google.com/accounts/ServiceLoginAuth', {
		Email => $user,
		Passwd => $pass,
		GALX => $galx,
	} );
	
	# rnr_se required for subsequent requests
	$c->max_redirects(3); # 3 redirects before rnr_se is available
	$el = $c->get('https://www.google.com/voice/inbox')
		->res->dom->at('input[name="_rnr_se"]');

	# Login not accepted
	return unless $el;
	
	$self->rnr_se( $el->attrs->{value} );

	return $self;
}

sub send_sms {
	my $self = shift;
	my $c = $self->client;
	my ($phone, $content) = @_;
	
	my $json = $c->post_form(
		'https://www.google.com/voice/b/0/sms/send', {
			id => undef,
			phoneNumber => $phone,
			text => $content || '',
			_rnr_se => $self->rnr_se
		}
	)->res->json;

	$@ = $json->{data}->{code} and return unless $json->{ok};
	
	return $json->{ok};
}

# sms meta->type == 10
sub sms_inbox {
	my $self = shift;
	my $c = $self->client;
	
	# Multiple conversations
	my $inbox = $c->get('https://www.google.com/voice/inbox/recent/sms/')
		->res->dom;

	# metadata
	my $meta = Mojo::JSON->new->decode(
		$inbox->at('response > json')->text );
	
	# content
	my $xml = Mojo::DOM->new->parse(
		$inbox->at('response > html')->text );

	# Each sms conversation in a span.gc-message
	return map
		Google::Voice::SMS->new( $_, $meta, $self->rnr_se, $c ),
		@{$xml->find('.gc-message')};
}

# voicemail meta->type == 2
sub voicemail_inbox {
	my $self = shift;
	my $c = $self->{client};
	
	my $inbox = $c->get('https://www.google.com/voice/inbox/recent/voicemail/')
		->res->dom;

	# metadata
	my $meta = Mojo::JSON->new->decode(
		$inbox->at('response > json')->text );
	
	# content
	my $xml = Mojo::DOM->new->parse(
		$inbox->at('response > html')->text );

	# Each voicemail in a span.gc-message
	return map
		Google::Voice::VM->new( $_, $meta, $self->rnr_se, $c ),
		@{$xml->find('.gc-message')};
}

sub call {
	my $self = shift;
	my ($from, $to) = @_;

	my $json = $self->client->post_form(
		'https://www.google.com/voice/call/connect' => {
			forwardingNumber => $from,
			outgoingNumber => $to,
			phoneType => 1,
			remember => 0,
			_rnr_se => $self->rnr_se
		}
	)->res->json;

	$@ = $json->{error} and return unless $json->{ok};

	return Google::Voice::Call->new( @_, $self->rnr_se, $self->client );
}

1;

=head1 NAME

Google::Voice

=head1 DESCRIPTION

google.com/voice services

=head1 USAGE

	my $g = Google::Voice->new->login('username', 'password');

	# Send sms
	$g->send_sms(5555555555 => 'Hello friend!');

	# Print all messages in sms inbox
	print "$_->{name}, $_->{text}\n" foreach $g->sms_inbox;

	# Error code from google on fail
	print $@ if ! $g->send_sms('invalid phone' => 'text message');

=head1 METHODS

=head2 new

Create object

=head2 login

Login.  Returns object on success, false on failure.

=head2 send_sms

Send SMS message.  Returns true/false.

=head2 sms_inbox

List of sms messages

=head2 voicemail_inbox

List of voicemail messages

=head2 call

Connect two phone numbers

=head1 SEE ALSO

L<Mojo::Client>

=head1 VERSION

0.01

=head1 AUTHOR

Glen Hinkle tempire@cpan.org

=cut
