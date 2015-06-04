use v6;

unit class Template6;

use Template6::Service;

has $.service handles <process context add-path set-extension add-provider>;

submethod BUILD (*%args) {
  if (%args<service>) {
    $!service = %args<service>;
  }
  else {
    $!service = Template6::Service.new(|%args);
  }
}

## End of class.

