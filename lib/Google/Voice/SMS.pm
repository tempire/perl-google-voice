package Google::Voice::SMS;

use strict;
use warnings;

use Data::Dumper;
use Google::Voice::SMS::Message;

use base 'Mojo::Base';

__PACKAGE__->attr( [ qw/ xml id name meta rnr_se client / ] );

sub new {
	my $self = bless {}, shift;
	my $xml = shift;
	my $meta = shift;
	my $rnr_se = shift;
	my $client = shift;

	$self->xml( $xml );
	$self->id( $xml->attrs->{id} );
	$self->name( $xml->at('.gc-message-name-link')->text );
	$self->meta( $meta->{messages}->{ $self->id } );
	$self->rnr_se( $rnr_se );
	$self->client( $client );
	
	return $self;
}

sub messages {
	my $self = shift;
	
	# Each text message is a span.gc-message-sms-row
	return map
		Google::Voice::SMS::Message->new(
			$_, $self->meta, $self->rnr_se, $self->client
		),
		@{$self->xml->find('.gc-message-sms-row')};
}

sub latest { return (shift->messages)[-1] }

sub delete {
	my $self = shift;

	my $json = $self->client->post_form(
		'https://www.google.com/voice/inbox/deleteMessages' => {
			messages => $self->id,
			trash => 1,
			_rnr_se => $self->rnr_se
		}
	)->res->json;

	$@ = $json->{data}->{code} and return unless $json->{ok};
	
	return $json->{ok};
}

1;

=head1 NAME

Google::Voice::SMS

=head1 DESCRIPTION

SMS conversation

=head1 ATTRIBUTES

=head2 id

Unique id

=head2 name

Sender's name

=head2 meta

Metadata hashref

=head2 xml

Raw xml

=head1 METHODS

=head2 messages

List of messages in sms conversation, Google::Voice::SMS::Message objects

=head2 latest

Most recent sms message

=head2 delete

Remove conversation

=cut
