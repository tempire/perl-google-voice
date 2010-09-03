package Google::Voice;

use strict;
use warnings;

use Mojo::Client;
use Mojo::JSON;
use IO::Socket::SSL;
use Data::Dumper;

use Google::Voice::Feed;
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
	$c->max_redirects(4); # 3-4 redirects before rnr_se is available
	$el = $c->get('https://www.google.com/voice#inbox')
		->res->dom->at('input[name="_rnr_se"]');
	
	# Login not accepted
	return unless $el;
	
	$self->rnr_se( $el->attrs->{value} );

	return $self;
}

sub logout {
	my $self = shift;
	my $c = $self->client;
	
	$c->max_redirects(0);
	
	return 1 if $c->get('https://www.google.com/voice/account/signout')
		->res->cookie('gv')->value eq 'EXPIRED';
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

for my $feed ( qw/ voicemail sms recorded placed received missed / ) {
	no strict 'refs';
	*{"Google::Voice::${feed}"} = sub {
		shift->feed( 'https://www.google.com/voice/inbox/recent/' . $feed );
	};
}

sub feed {
	my $self = shift;
	my $url = shift;

	my $c = $self->client;
	
	# Multiple conversations
	my $inbox = $c->get( $url )->res->dom;

	# metadata
	my $meta = Mojo::JSON->new->decode(
		$inbox->at('response > json')->text );
	
	# content
	my $xml = Mojo::DOM->new->parse(
		$inbox->at('response > html')->text );

	# Each conversation in a span.gc-message
	return map
		Google::Voice::Feed->new( $_, $meta, $self->rnr_se, $c ),
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

	# Error code from google on fail
	print $@ if ! $g->send_sms('invalid phone' => 'text message');
	
	# Print all sms conversations
	foreach my $sms ( $g->sms ) {
	    print $sms->name;
	    print $_->time , ':', $_->text, "\n" foreach $sms->messages;
	}

	# connect call & cancel it
	my $call = $g->call( '+15555555555' => '+14444444444' );
	$call->cancel;

=head1 METHODS

=head2 new

Create object

=head2 login

Login.  Returns object on success, false on failure.

=head2 logout

Logout

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

=head2 call

Connect two phone numbers

=head1 SEE ALSO

L<Mojo::Client>

=head1 VERSION

0.01

=head1 AUTHOR

Glen Hinkle tempire@cpan.org

=cut
