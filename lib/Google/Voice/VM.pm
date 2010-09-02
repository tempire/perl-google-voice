package Google::Voice::VM;

use strict;
use warnings;

use Data::Dumper;

use base 'Mojo::Base';

__PACKAGE__->attr( [ qw/ xml id name meta text rnr_se client / ] );

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

	$self->text(
		"@{[map $_->text, @{$xml->find('.gc-message-message-display > span')}]}"
	);
	
	$self->rnr_se( $rnr_se );
	$self->client( $client );
	
	return $self;
}

sub download {
	my $self = shift;
	my ($from, $to) = @_;

	my $res = $self->client->get(
		'https://www.google.com/voice/media/send_voicemail/' . $self->id
	)->res;

	$@ = $res->message and return if $res->code != 200;

	return $res->content->asset;
}

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

Google::Voice::VM

=head1 DESCRIPTION

Object representing voicemail message

=head1 ATTRIBUTES

=head1 METHODS

=head2 new

=head2 download

Download mp3 audio

=head2 delete

Remove voicemail

=head1 SEE ALSO

L<Mojo::Asset>

=cut
