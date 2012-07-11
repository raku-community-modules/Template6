use v6;

class Template6::Parser;

## TODO: Implement a bunch more statements.

method get ($what)
{
  return "\$output ~= \$context.stash.get('$what');";
}

method action ($statement) {
  my @stmts = $statement.comb(/\S+/);
  my $name = @stmts.shift;
  if self.can($name) {
    return self."$name"(@stmts);
  }
  else {
    return self.get($name);
  }
}

method compile ($template is copy) {
  my $script = "return sub (\$context) \{ my \$output = \"";
  $template ~~ s:g/'[%' \s* (.*?) \s* '%]'/";\n{self.action($0)}\n\$output ~= "/;
  $script ~= $template;
  $script ~= "\";\nreturn \$output;\n\}";
#  say "<template>\n$script\n</template>";
  my $function = eval $script;
  return $function;
}

