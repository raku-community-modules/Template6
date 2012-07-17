use v6;

class Template6::Stash;

has $.parent is rw;   ## Only used for cloning.
has %!data;           ## Stores the actual variables.

method put ($key, $value) {
  %!data{$key} = $value;
}

method lookup (@query is rw, $data) {
  my $element = @query.shift;
  my $found;
  if $data ~~ Hash {
    if $data.exists($element) {
      $found = $data{$element};
    }
  }
  elsif $data ~~ Array && $element ~~ /^\d+$/ {
    if $data.elems >= $element {
      $found = $data[$element];
    }
  }
  elsif $data.can($element) {
    $found = $data."$element"();
  }
  if $found.defined {
    if @query.elems > 0 {
      return self.lookup(@query, $found);
    }
    else {
      return $found;
    }
  }
  return;
}

method get ($query) {
  if %!data.exists($query) {
    return %!data{$query};
  }
  elsif ($query ~~ /\./) {
    my @query = $query.split('.');
    my $value = self.lookup(@query, %!data);
    if ($value.defined) {
      return $value;
    }
  }
  ## If nothing was found, we return the original query.
  return $query;
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

