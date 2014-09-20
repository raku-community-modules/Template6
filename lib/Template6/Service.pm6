use v6;

class Template6::Service;

use Template6::Context;

has $.context handles <add-provider add-path set-extension>;
has @.pre-process;
has @.post-process;
has @.wrappers;
has $!reset;

submethod BUILD (*%args) {
  if %args<context> {
    $!context = %args<context>;
  }
  else {
    unless %args<service> :exists {
      %args<service> = self;
    }
    $!context = Template6::Context.new(|%args);
  }
  if %args<reset> :exists {
    $!reset = %args<reset>;
  }
}

## Process a template using a data provider.
method process ($template, *%params) {
  my $output = '';
  if $!reset { $.context.reset(); }
  %params<template> = $template;
  ## First, anything in our pre-process queue.
  for @.pre-process -> $pre-template {
    $output ~= $.context.process($pre-template, |%params);
  }
  ## Next our main template.
  ## TODO: an equivilent to the PROCESS options from TT2.
  my $procout = $.context.process($template, |%params);
  if $procout.defined {
    for @.wrappers -> $wrapper {
      $procout = $.context.process($wrapper, content => $procout, |%params );
    }
    $output ~= $procout;
  }
  ## Next, our post-process queue.
  for @.post-process -> $post-template {
    $output ~= $.context.process($post-template, |%params);
  }
  return $output;
}

## End of class.
