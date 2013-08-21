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
  $config->define("message3=s");
  $config->define("message4=s");
  $config->define("message5=s");
  $config->define("message6=s");
  $config->define("message7=s");
  $config->define("message8=s");
  $config->define("message9=s");
  
  # read configuration file
  my $configuration_file = $ENV{"HOME"} . "/.config/perl-google-voice/perl-google-voice.conf";
  print "$configuration_file]\n";
  $config->file($configuration_file);
  
  my $google_login = $config->get("google_login");
  my $google_password = $config->get("google_password");
  my $phone_number = $config->get("phone_number");
  
  my $message1 = $config->get("message1");
  my $message2 = $config->get("message2");
  print "[$google_login][$google_password][$phone_number]\n";
  
  my $g = Google::Voice->new->login($google_login, $google_password);
  my $message = chomp(my $date = `date`);
  
  my @messages_que;

  push @messages_que, [ '9094479170' => $message1 ];
  push @messages_que, [ '9094479170' => $message2 ];

foreach my $message (@messages_que) {
    $g->send_sms(${$message}[0] => ${$message}[1]);
}
