use Template6::Provider;

unit class Template6::Provider::File does Template6::Provider;

## TODO: Implement 'absolute', 'relative', etc. options.
## TODO: Pre-compiled templates?

method fetch(Str:D $name) {
    .return with %.templates{$name};
    for @.include-path -> $path {
        my $io = $path.IO.add($name).extension($.ext, :0parts);
        return %.templates{$name} = $io.slurp if $io.f;
    }
}

# vim: expandtab shiftwidth=4
