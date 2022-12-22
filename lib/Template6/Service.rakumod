unit class Template6::Service;

use Template6::Context;

has $.context handles <add-provider add-path set-extension add-template>;
has @.pre-process;
has @.post-process;
has @.wrappers;
has $!reset;

submethod BUILD(*%args) {
    if %args<context> {
        $!context = %args<context>;
    }
    else {
        without %args<service> {
            $_ = self;
        }
        $!context = Template6::Context.new(|%args);
    }
    with %args<reset> {
        $!reset = $_;
    }
}

## Process a template using a data provider.
method process($template, *%params) {
    my $output = '';
    $.context.reset if $!reset;
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
    $output
}

# vim: expandtab shiftwidth=4
