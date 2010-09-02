Requires only Mojolicious & IO::Socket::SSL

	use Google::Voice;
	
	my $g = Google::Voice->new->login( 'user', 'pass' );
	
	# sms conversation
	foreach my $sms ( $g->sms_inbox ) {
		print $sms->name;
		print $_->time , ':', $_->text, "\n" foreach $sms->messages;
		
		$sms->delete;
	}
	
	$g->send_sms( '+15555555555' => 'Hello friend!' );
	
	# connect call & cancel it
	my $call = $g->call( '+15555555555' => '+14444444444' );
	$call->cancel;
	
	# voicemail
	foreach my $vm ( $g->voicemail_inbox ) {
	
		# name & transcribed text
		print $vm->name;
		print $vm->text;
	
		# store message
		$vm->download->move_to('/directory/' . $vm->id . "/vm.mp3');
	
		$vm->delete;
	}
