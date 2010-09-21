package Google::Voice::Call;

use strict;
use warnings;

use base 'Mojo::Base';

__PACKAGE__->attr([qw/ from to rnr_se client /]);

sub new {
    my $self = bless {}, shift;

    $self->from(shift);
    $self->to(shift);
    $self->rnr_se(shift);
    $self->client(shift);

    return $self;
}

sub cancel {
    my $self = shift;
    my ($from, $to) = @_;

    my $json = $self->client->post_form(
        'https://www.google.com/voice/call/cancel/' => {
            forwardingNumber => undef,
            outgoingNumber   => undef,
            cancelType       => 'C2C',
            _rnr_se          => $self->rnr_se
        }
    )->res->json;

    $@ = $json->{data}->{code} and return unless $json->{ok};

    return $json->{ok};
}

1;

=head1 NAME

Google::Voice::Call

=head1 DESCRIPTION

Object representing active phone call

=head1 ATTRIBUTES

=head2 from

Calling from phone number

=head2 to

Calling to phone number

=head1 METHODS

=head2 new

=head2 cancel

Cancel connected phone call

=cut
