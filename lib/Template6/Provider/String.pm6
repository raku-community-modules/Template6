use v6;

use Template6::Provider;

unit class Template6::Provider::String does Template6::Provider;

method fetch ($name) {
  if %.templates{$name} :exists {
    return %.templates{$name};
  }
  return;
}

