use v6;

class Template6::Provider::File;

has @.include-path;
has %.templates;
has $.ext is rw = '.tt';

## TODO: Implement 'absolute', 'relative', etc. options.
## TODO: Pre-compiled templates?

submethod BUILD (:@path, *%args) {
  if @path {
    @!include-path.splice(@!include-path.elems, 0, @path);
  }
}

method add-path ($path) {
  @.include-path.push: $path;
}

method fetch ($name) {
  if %.templates.exists($name) {
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

method store ($name, $template) {
  %.templates{$name} = $template;
}

