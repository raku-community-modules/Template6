unit class Template6::Stash;

has $.parent is rw;     ## Only used for cloning.
has %!data;                     ## Stores the actual variables.

method put(Str:D $key, $value) {
    %!data{$key} = $value;
}

method lookup(@query, $data) {
    my $element = @query.shift;
    my $found;
    if $data ~~ Hash {
        $found = $_ with $data{$element};
    }
    elsif $data ~~ Array && $element ~~ /^ \d+ $/ {
        if $data.elems >= $element {
            $found = $data[$element];
        }
    }
    elsif $data.can($element) {
        $found = $data."$element"();
    }
    with $found {
        .return unless @query;
        return self.lookup(@query, $_);
    }
}

method get($query, :$strict) {
    .return with %!data{$query};
    if $query.contains('.') {
        my @query = $query.split('.');
        my $value = self.lookup(@query, %!data);
        .return with $value;
    }

    # If nothing was found, and we're not in strict mode, we return the original query.
    $strict ?? Nil !! $query
}

method update(*%hash) {
    for %hash.kv -> $key, $val {
        %!data{$key} = $val;
    }
}

method make-clone(*%params) {
    my $clone = self.clone;
    $clone.parent = self;
    $clone.update(|%params);
    $clone
}

method declone {
    $.parent || self
}

# vim: expandtab shiftwidth=4
