use v6;

use Template6::Provider;

unit class Template6::Provider::File does Template6::Provider;

## TODO: Implement 'absolute', 'relative', etc. options.
## TODO: Pre-compiled templates?

method fetch ($name) {
  if %.templates{$name} :exists {
    return %.templates{$name};
  }
  for @.include-path -> $path {
    my $file = "$path/$name"~$.ext;
    if $file.IO ~~ :f {
      my $template = slurp $file;
      %.templates{$name} = $template;
      return $template;
    }
  }
  return;
}

