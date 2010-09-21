package Google::Voice::SMS::Message;

use strict;
use warnings;

use Mojo::ByteStream;

use base 'Mojo::Base';

__PACKAGE__->attr([qw/ text time inbound outbound xml rnr_se client /]);

sub new {
    my $self = bless {}, shift;
    my $xml  = shift;
    my $meta = shift;

    $self->rnr_se(shift);
    $self->client(shift);

    my $from =
      Mojo::ByteStream->new($xml->at('.gc-message-sms-from')->text)->trim;

    my $time =
      Mojo::ByteStream->new($xml->at('.gc-message-sms-time')->text)->trim;

    $self->xml($xml);
    $self->text($xml->at('.gc-message-sms-text')->text);
    $self->time($time);
    $self->inbound($from eq 'Me:');
    $self->outbound($from ne 'Me:');

    return $self;
}

1;

=head1 NAME

Google::Voice::SMS::Message

=head1 DESCRIPTION

One message in an sms conversation

=head1 USAGE

  print "Inbound message" if $sms_message->inbound;
  print $sms_message->text;

=head1 ATTRIBUTES

=head2 text

Text content of message

=head2 inbound

True/false

=head2 outbound

True/false

=head2 xml

Raw xml

=head1 METHODS

=head2 new

=cut
