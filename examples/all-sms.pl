#!/usr/bin/env perl

use warnings;
use strict;

use Google::Voice;
use AppConfig;

# create a new AppConfig object
my $config = AppConfig->new;

# define a new variable
$config->define("google_login=s");
$config->define("google_password=s");
$config->define("phone_number=s");

$config->define("message1=s");
$config->define("message2=s");

# read configuration file
my $configuration_file = $ENV{"HOME"} . "/.config/perl-google-voice/perl-google-voice.conf";
print "$configuration_file]\n";
$config->file($configuration_file);

my $google_login = $config->get("google_login");
my $google_password = $config->get("google_password");
my $phone_number = $config->get("phone_number");

my $g = Google::Voice->new->login($google_login, $google_password);

# Print all sms conversations
print "HELLO";
foreach my $sms ($g->sms) {
    print $sms->name;
    print $_->time, ':', $_->text, "\n" foreach $sms->messages;
    
    # Delete conversation
    # $sms->delete;
}
