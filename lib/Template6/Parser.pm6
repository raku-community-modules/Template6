use v6;

class Template6::Parser;

has @.keywords = 'eq', 'ne', 'lt', 'gt', 'gte', 'lte';

method parse-get ($name) {
  return "\$output ~= \$stash.get('$name');";
}

method parse-set ($name, $op, $value) {
  if ($value ~~ /\"(.*?)\"|\'(.*?)\'/) {
    my $string = ~$0;
    return "\$stash.put('$name', '$string');";
  }
  else
  {
    return "\$stash.put('$name', \$stash.get('$value'));";
  }
}

method parse-for ($left, $op, $right) {
  my $itemname;
  my $loopname;
  if ($op.lc eq '=' | 'in') {
    $itemname = $right;
    $loopname = $left;
  }
  else {
    $itemname = $left;
    $loopname = $right;
  }
  my $function = "for \@(\$stash.get('$itemname')) -> \$$loopname \{\n";
  $function   ~= "\$stash.put('$loopname', \$$loopname);";
  return $function;
}

method !parse-conditional ($name, @stmts is copy) {
  for @stmts -> $stmt is rw {
    if @.keywords.grep($stmt) { next; }
    if $stmt ~~ /^\d+$/ { next; }
    $stmt ~~ s/^(\w+)$/\$stash.get('$0')/;
  }
  my $statement = @stmts.join(' ');
  my $function = "if $statement \{\n";
  return $function;
}

method parse-if (*@stmts) {
  self!parse-conditional('if', @stmts);
}

method parse-unless (*@stmts) {
  self!parse-conditional('unless', @stmts);
}

method parse-elsif (*@stmts) {
  my $function = "\n\}\n";
  $function ~= self!parse-conditional('elsif', @stmts);
  return $function;
}

method parse-else {
  return "\n\}\nelse \{\n";
}

method parse-end {
  return "\n\}\n";
}

method action ($statement) {
  my @stmts = $statement.comb(/\".*?\" | \'.*?\' | \S+/);
  my $name = @stmts.shift.lc;
  my $method = 'parse-' ~ $name;
  if self.can($method) {
    return self."$method"(|@stmts);
  }
  else {
    if (@stmts.elems >= 2 && @stmts[0] eq '=') {
      return self.parse-set($name, |@stmts);
    }
    return self.parse-get($name);
  }
}

method compile ($template) {
  my $script = "return sub (\$context) \{\n my \$stash = \$context.stash;\nmy \$output = '';\n";
  my @segments = $template.split(/\n?'[%' \s* (.*?) \s* '%]'/, :all);
  for @segments -> $segment {
    if $segment ~~ Stringy {
      my $string = $segment.subst('}}}}', '\}\}\}\}', :g);
      $script ~= "\$output ~= Q\{\{\{\{$string\}\}\}\};\n";
    }
    elsif $segment ~~ Match {
      my $statement = ~$segment[0];
      $script ~= self.action($statement);
    }
  }
  $script ~= "return \$output;\n\}";
#  $*ERR.say: "<DEBUG:template>\n$script\n</DEBUG:template>";
  my $function = eval $script;
  return $function;
}

