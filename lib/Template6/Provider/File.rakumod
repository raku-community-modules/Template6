use Template6::Provider;

unit class Template6::Provider::File does Template6::Provider;

## TODO: Implement 'absolute', 'relative', etc. options.
## TODO: Pre-compiled templates?

method fetch(Str:D $name) {
    if %.templates{$name}:exists {
        %.templates{$name};
    }
    for @.include-path -> $path {
        my $io = "$path/$name$.ext".IO;
        return %.templates{$name} = $io.slurp
          if $io.f;
    }
}

# vim: expandtab shiftwidth=4
