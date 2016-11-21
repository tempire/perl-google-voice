package Google::Voice::Feed;

use strict;
use warnings;

use Google::Voice::SMS::Message;

use Mojo::Base -base;

use constant FEED_TYPE => {
  2  => 'voicemail',
  10 => 'sms',
  4  => 'recorded',
  7  => 'placed',
  1  => 'received',
  0  => 'missed',
  11 => 'trash',
  10 => 'starred',
};

__PACKAGE__->attr([qw/ xml id type name meta text rnr_se ua /]);

sub new {
  my $self   = bless {}, shift;
  my $xml    = shift;
  my $meta   = shift;
  my $rnr_se = shift;
  my $ua     = shift;

  $self->xml($xml);
  $self->id($xml->attr->{id});
  $self->name($self->_message_name($xml->at('.gc-message-name-link')));
  $self->meta($meta->{messages}->{$self->id});
  $self->type(FEED_TYPE->{$self->meta->{type}});

  $self->text("@{[map $_->text, @{$xml->find('.gc-orig-trans > span')}]}");

  $self->rnr_se($rnr_se);
  $self->ua($ua);

  return $self;
}

sub _message_name {
  my $self = shift;
  my $node = shift;

  return $node->text if $node;

  return '';
}

sub messages {
  my $self = shift;

  # Each text message is a span.gc-message-sms-row
  return
    map Google::Voice::SMS::Message->new($_, $self->meta, $self->rnr_se,
    $self->ua),
    @{$self->xml->find('.gc-message-sms-row')};
}

sub latest { return (shift->messages)[-1] }

sub delete {

  my $self = shift;

  my $json = $self->ua->post(
    'https://www.google.com/voice/inbox/deleteMessages' => form => {
      messages => $self->id,
      trash    => 1,
      _rnr_se  => $self->rnr_se
    }
  )->res->json;

  $@ = $json->{data}->{code} and return unless $json->{ok};

  return $json->{ok};
}

sub download {
  my $self = shift;
  my ($from, $to) = @_;

  my $res = $self->ua->get(
    'https://www.google.com/voice/media/send_voicemail/' . $self->id)->res;

  $@ = $res->message and return if $res->code != 200;

  return $res->content->asset;
}

1;

=head1 NAME

Google::Voice::Feed

=head1 DESCRIPTION

All feeds (voicemail, text, recorded, placed, received, missed, history

=head1 ATTRIBUTES

=head2 id

Unique id

=head2 name

Sender's name

=head2 meta

Metadata hashref

=head2 text (voicemail feed only)

Text transcription of voicemail

=head2 xml

Raw xml

=head1 METHODS

=head2 messages (sms feed only)

List of messages in sms conversation, Google::Voice::SMS::Message objects

=head2 latest (sms feed only)

Most recent sms message

=head2 delete

Remove conversation

=head2 download

Download associated audio (mp3 format)

=cut
