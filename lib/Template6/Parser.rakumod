unit class Template6::Parser;

has @!keywords = 'eq', 'ne', 'lt', 'gt', 'gte', 'lte';
has $.context;

## Incomplete method, supply the $localline which must define a variable called $template
method !parse-template(@defs is copy, $localline) {
    my $return = '';
    my $parsing-templates = True;
    my @templates;

    while $parsing-templates && @defs {
        @templates.push: @defs.shift;
        if @defs && @defs[0] eq '+' {
            @defs.shift;
        }
        else {
            $parsing-templates = False;
        }
    }
    $return ~= "my \%localdata;\n";
    for @defs -> $name, $op, $value {
        given $value {
            when / \" (.*?) \" | \' (.*?) \' / {
                $return ~= "\%localdata<$name> = '$0';\n";
            }
            when /^ \d+ [\.\d+]? $/ {
                $return ~= "\%localdata<$name> = $value.Numeric();\n";
            }    
            default {
                $return ~= "\%localdata<$name> = \$stash.get('$value');\n";
            }
        }
    }

    for @templates -> $template is rw {
        $template ~~ s/^[\"|\']//;
        $template ~~ s/[\"|\']$//;
        $return ~= "\{\n my \$tfile = \$stash.get('$template');\n";
        $return ~= $localline;
        $return ~= "with \$template \{ \$output ~= \$_; \}\n";
        $return ~= "\}\n";
    }
    $return
}

method parse-insert(*@defs) {
    my $localline = 'my $template = $context.get-template-text($tfile);' ~ "\n";
    self!parse-template(@defs, $localline)
}

method parse-include(*@defs) {
    my $localline = 'my $template = $context.process($tfile, :localise, |%localdata);' ~ "\n";
    self!parse-template(@defs, $localline)
}

method parse-process(*@defs) {
    my $localline = 'my $template = $context.process($tfile, |%localdata);' ~ "\n";
    self!parse-template(@defs, $localline)
}

method parse-get(Str:D $name) {
    "\$output ~= \$stash.get('$name');"
}

method parse-call(Str:D $name) {
    "\$stash.get('$name');"
}

method parse-set(:$default, *@values is copy) {
    my $return = '';
    for @values -> $name, $op, $value {
        if $default {
            $return ~= "if ! \$stash.get('$name', :strict) \{\n";
        }
        given $value {
            when / \" (.*?) \" | \' (.*?) \' / {
                $return ~= "\$stash.put('$name', '$0');\n";
            }
            when /^ \d+ [\.\d+]? $/ {
                $return ~= "\$stash.put('$name', $value.Numeric());\n";
            }
            default {
                $return ~= "\$stash.put('$name', \$stash.get('$value'));\n";
            }
        }
        if $default {
            $return ~= "}\n";
        }
    }
    $return
}

method parse-default(*@values) {
    self.parse-set(:default, @values)
}

method parse-for($left, $op, $right) {
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
    "for \@(\$stash.get('$itemname')) -> \$$loopname \{\n"
      ~ "\$stash.put('$loopname', \$$loopname);"
}

method !parse-conditional(Str:D $name, @stmts is copy) {
    for @stmts -> $stmt is rw {
        next if @!keywords.grep($stmt);
        next if $stmt ~~ /^ \d+ $/;
        $stmt .= subst(/^ (\w+) $/, -> $word { "\$stash.get('$word')" });
    }
    my $statement = @stmts.join(' ');
    "$name $statement \{\n"
}

method parse-if(*@stmts) {
    self!parse-conditional('if', @stmts)
}

method parse-unless(*@stmts) {
    self!parse-conditional('unless', @stmts)
}

method parse-elsif(*@stmts) {
    "\n\}\n" ~ self!parse-conditional('elsif', @stmts)
}

method parse-elseif(*@stmts) {
    self.parse-elsif(|@stmts)
}

method parse-else() {
    "\n\}\nelse \{\n"
}

method parse-end {
    "\n\}\n"
}

method remove-comment(*@tokens --> List) {
    @tokens.toggle(* ne '#').cache
}

method action($statement) {
    my @stmts = $statement
      .lines
      .map({ self.remove-comment(.comb(/ \" .*? \" | \' .*? \' | \S+ /)) })
      .flat;
    return '' unless @stmts;

    my $name = @stmts.shift.lc;
    my $method = 'parse-' ~ $name;
    self.can($method)
      ?? self."$method"(|@stmts)
      !! @stmts.elems >= 2 && @stmts[0] eq '='
        ?? self.parse-set($name, |@stmts)
        !! self.parse-get($name)
}

method compile($template) {
    my $script = "return sub (\$context) \{\n my \$stash = \$context.stash;\nmy \$output = '';\n";
    my @segments = $template.split(/ \n? '[%' $<comment-signature>=(\#?) \s* $<tokens>=(.*?) \s* '%]' /, :v);
    for @segments -> $segment {
        if $segment ~~ Stringy {
            my $string = $segment.subst('}}}}', '\}\}\}\}', :g);
            $script ~= "\$output ~= Q\{\{\{\{$string\}\}\}\};\n";
        }
        elsif $segment ~~ Match && !~$segment<comment-signature> {
            my $statement = ~$segment<tokens>;
            $script ~= self.action($statement);
        }
    }
    $script ~= "return \$output;\n\}";
#    $*ERR.say: "<DEBUG:template>\n$script\n</DEBUG:template>";
    $script.subst( / 'my %localdata;' /, '', :nd(2..*) ).EVAL
}

# vim: expandtab shiftwidth=4
