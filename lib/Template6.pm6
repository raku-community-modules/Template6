use v6;

class Template6;

use Template6::Service;

has $.service handles <process context>;

submethod BUILD (*%args) {
  if (%args<service>) {
    $!service = %args<service>;
  }
  else {
    $!service = Template6::Service.new(|%args);
  }
}

## End of class.

