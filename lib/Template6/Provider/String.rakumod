use Template6::Provider;

unit class Template6::Provider::String does Template6::Provider;

method fetch(Str:D $name) {
    %.templates{$name} // Nil
}

# vim: expandtab shiftwidth=4
