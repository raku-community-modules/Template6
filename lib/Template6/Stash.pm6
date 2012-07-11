use v6;

class Template6::Stash;

has $.parent is rw;   ## Only used for cloning.
has %!data;           ## Stores the actual variables.

method put ($key, $value) {
  %!data{$key} = $value;
}

method get ($query) {
  ## TODO: Advanced queries.
  if %!data.exists($query) {
    return %!data{$query};
  }
  return;
}

method update (*%hash) {
  for %hash.kv -> $key, $val {
    %!data{$key} = $val;
  }
}

method make-clone (*%params) {
  my $clone = self.clone;
  $clone.parent = self;
  $clone.update(|%params);
  return $clone;
}

method declone {
  if $.parent {
    return $.parent;
  }
  return self;
}

## End of class.

