use v6;

unit class Template6::Context;

use Template6::Parser;
use Template6::Stash;
use Template6::Provider::File;

has $.service;        ## The parent Service object.
has $.parser;         ## Our Parser object.
has $.stash is rw;    ## Our Stash object.

has %.blocks is rw;   ## Currently known blocks.
has @.block-cache;    ## Known block tree (for nested contexts.)

has %.providers;      ## Providers for templates, based on prefix names.
                      ## Eventually we'll support loading providers
                      ## dynamically, but for now, you need to load it in your
                      ## class, then assign it a prefix.
                      ## Do so by passing a providers variable or using the
                      ## add-provider() method.
                      ## The default provider is Template6::Provider::File
                      ## which loads files from the include-path array.

submethod BUILD (*%args) {
  $!service = %args<service>;
  unless %args<context> :exists {
    %args<context> = self;
  }
  if (%args<parser>) {
    $!parser = %args<parser>;
  }
  else {
    $!parser = Template6::Parser.new(|%args);
  }
  if (%args<stash>) {
    $!stash = %args<stash>;
  }
  else {
    $!stash = Template6::Stash.new(|%args);
  }
  %!providers<file> = Template6::Provider::File.new(|%args);
}

method add-provider ($name, Template6::Provider $object) {
  %!providers{$name} = $object;
}

## A couple of helper methods for the default provider.

method add-path ($path) {
  if %!providers<file> :exists {
    %!providers<file>.add-path($path);
  }
}

method set-extension ($ext) {
  if %!providers<file> :exists {
    %!providers<file>.ext = $ext;
  }
}

method get-template-text ($name is copy) {
  my $prefix;
  my @providers;
  if $name ~~ s/^(\w+)'::'// {
    $prefix = $0;
  }

  if $prefix.defined && (%!providers{$prefix} :exists) {
    @providers = %!providers{$prefix};
  }
  else {
    @providers = @(%!providers.values);
  }
  my $template;
  for @providers -> $provider {
    $template = $provider.fetch($name);
    if $template.defined { last; }
  }
  return $template;
}

method get-template-block ($name) {
  if %.blocks{$name} :exists {
   return %.blocks{$name};
  }
  for @.block-cache -> $known-blocks {
    if $known-blocks{$name} :exists {
      return $known-blocks{$name};
    }
  }

  my $template = self.get-template-text($name);

  ## If we have a template, store it.
  if $template.defined {
    if ($template !~~ Callable) {
      $template = $.parser.compile($template);
    }
    %.blocks{$name} = $template;
  }
  return $template;
}

method process ($name, :$localise=False, *%params) {
  my $template = $name;
  if $template ~~ Str {
    $template = self.get-template-block($template);
    if !$template.defined { die "Invalid template '$name'"; }
  }
  if $localise {
    self.localise(|%params);
  }
  else {
    $.stash.update(|%params);
  }
#  my $context = self; ## Made available for the Template.
#  say "<template>\n$template\n</template>";
#  my $output = eval $template;
  ## New style templates are closures.
  my $output = $template(self);
  if $localise {
    self.delocalise();
  }
  return $output;
}

method localise (*%params) {
  $.stash = $.stash.make-clone(|%params);
}

method delocalise {
  $.stash = $.stash.declone();
}

## End of class.
