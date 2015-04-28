# Google Voice library for Perl

 - No parsing required - all data available in perl objects
 - Only two pre-requisites:
    - Mojolicious
    - IO::Socket::SSL


## Install

curl -L cpanmin.us | perl - Google::Voice

<a href="https://metacpan.org/module/Google::Voice">https://metacpan.org/module/Google::Voice</a>

## Example

    use Google::Voice;

    my $g = Google::Voice->new->login('username', 'password');

    # Send sms
    $g->send_sms(5555555555 => 'Hello friend!');

    # Error code from google on fail
    print $@ if ! $g->send_sms('invalid phone' => 'text message');

    # connect call & cancel it
    my $call = $g->call( '+15555555555' => '+14444444444' );
    $call->cancel;


    # sms conversation
    foreach my $sms ( $g->sms ) {
        print $sms->name;
        print $_->time , ':', $_->text, "\n" foreach $sms->messages;

        $sms->delete;
    }

    # loop through voicemail messages
    foreach my $vm ( $g->voicemail ) {

        # Name, number, and transcribed text
        print $vm->name . "\n";
        print $vm->meta->{phoneNumber} . "\n";
        print $vm->text . "\n";

        # Download mp3
        $vm->download->move_to( $vm->id . '.mp3' );

        # Delete
        $vm->delete;
    }

    # Delete Forever messages in Trash from Larry
    foreach my $msg ($g->search('Larry')) {

       next unless $msg->meta->{isTrash};

       print $msg->name . "\n";
       print "Labels: ", join(", ", @{$msg->meta->{labels}}), "\n";

       # Delete Forever
       $msg->deleteforever;
    }

