use v6;

class Template6::Parser;

has @!keywords = 'eq', 'ne', 'lt', 'gt', 'gte', 'lte';
has $.context;

## Incomplete method, supply the $localline which must define a variable called $template
method !parse-template (@defs is copy, $localline)
{
  my $return = '';
  my $parsing-templates = True;
  my @templates;

  while $parsing-templates && @defs.elems {
    @templates.push: @defs.shift;
    if @defs.elems && @defs[0] eq '+' {
      @defs.shift;
    }
    else {
      $parsing-templates = False;
    }
  }

  $return ~= "my \%localdata;\n";
  while @defs.elems >= 3 {
    my $name  = @defs.shift;
    my $op    = @defs.shift;
    my $value = @defs.shift;
    if ($value ~~ /\"(.*?)\"|\'(.*?)\'/) {
      my $string = ~$0;
      $return ~= "\%localdata<$name> = '$string';\n";
    }
    elsif ($value ~~ /^\d+[\.\d+]?$/) {
      my $number = +$value;
      $return ~= "\%localdata<$name> = $number;\n";
    }
    else {
      $return ~= "\%localdata<$name> = \$stash.get('$value');\n";
    }
  }

  for @templates -> $template is rw {
    $template ~~ s/^[\"|\']//;
    $template ~~ s/[\"|\']$//;
    $return ~= "\{\n my \$tfile = \$stash.get('$template');\n";
    $return ~= $localline;
    $return ~= "if \$template.defined \{ \$output ~= \$template; \}\n";
    $return ~= "\}\n";
  }
  return $return;
}

method parse-insert (*@defs)
{
  my $localline = 'my $template = $context.get-template-text($tfile);'~"\n";
  return self!parse-template(@defs, $localline);
}

method parse-include (*@defs)
{
  my $localline = 'my $template = $context.process($tfile, :localise, |%localdata);'~"\n";
  return self!parse-template(@defs, $localline);
}

method parse-process (*@defs)
{
  my $localline = 'my $template = $context.process($tfile, |%localdata);'~"\n";
  return self!parse-template(@defs, $localline);
}

method parse-get ($name) {
  return "\$output ~= \$stash.get('$name');";
}

method parse-call ($name) {
  return "\$stash.get('$name');";
}

method parse-set (:$default, *@values is copy) {
  my $return = '';
  while @values.elems >= 3 {
    my $name  = @values.shift;
    my $op    = @values.shift;
    my $value = @values.shift;
    if $default {
      $return ~= "if ! \$stash.get('$name', :strict) \{\n";
    }
    if ($value ~~ /\"(.*?)\"|\'(.*?)\'/) {
      my $string = ~$0;
      $return ~= "\$stash.put('$name', '$string');\n";
    }
    elsif ($value ~~ /^\d+[\.\d+]?$/)
    {
      my $number = +$value;
      $return ~= "\$stash.put('$name', $number);\n";
    }
    else
    {
      $return ~= "\$stash.put('$name', \$stash.get('$value'));\n";
    }
    if $default {
      $return ~= "}\n";
    }
  }
  return $return;
}

method parse-default (*@values) {
  return self.parse-set(:default, @values);
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
    if @!keywords.grep($stmt) { next; }
    if $stmt ~~ /^\d+$/ { next; }
    $stmt .= subst(/^(\w+)$/, -> $word { "\$stash.get('$word')" });
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

method parse-elseif (*@stmts) {
  return self.parse-elsif(|@stmts);
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

