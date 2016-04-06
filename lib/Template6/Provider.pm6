use v6;

unit role Template6::Provider;

has @.include-path;
has %.templates;
has $.ext is rw = '.tt';

submethod BUILD (:@path, *%args) {
  if @path {
    @!include-path.splice(@!include-path.elems, 0, @path);
  }
}

method add-path ($path) {
  @.include-path.push: $path;
}

method fetch ($name) {
    ...
}

method store ($name, $template) {
  %.templates{$name} = $template;
}

