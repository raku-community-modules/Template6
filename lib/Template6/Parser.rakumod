unit class Template6::Parser;

my @keywords = 'eq', 'ne', 'lt', 'gt', 'gte', 'lte';
subset ControlState of Str where * (elem) <conditional for>;

has $.context;
has %!directive-handlers =
    insert => (-> @, **@defs {
        my $localline = 'my $template = $context.get-template-text($tfile);' ~ "\n";
        parse-template(@, @defs, $localline)
    }, True),
    include => (-> @, **@defs {
        my $localline = 'my $template = $context.process($tfile, :localise, |%localdata);' ~ "\n";
        parse-template(@, @defs, $localline)
    }, False),
    process => (-> @, **@defs {
        my $localline = 'my $template = $context.process($tfile, |%localdata);' ~ "\n";
        parse-template(@, @defs, $localline)
    }, False),
    call => (-> @, Str:D $name {
        q:to/RAKU/
        $stash.get('\qq[$name]');
        RAKU
    }, True),
    get => (&parse-get, True),
    set => (&parse-set, False),
    default => (-> @, **@values {
        parse-set(@, :default, @values);
    }, False),
    for => (-> @control-stack, $left, $op, $right {
        @control-stack.unshift('for');
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
        q:to/RAKU/
        for @($stash.get('\qq[$itemname]', :strict)) -> $\qq[$loopname] {
            $stash.put('\qq[$loopname]', $\qq[$loopname]);
        RAKU
    }, False),
    if => (-> @control-stack, **@stmts {
        parse-conditional(@control-stack, 'if', @stmts)
    }, False),
    unless => (-> @control-stack, **@stmts {
        parse-conditional(@control-stack, 'unless', @stmts)
    }, False),
    |(<elseif elsif> X=> $(-> @control-stack, **@stmts {
        "\n}\n" ~ parse-conditional(@control-stack, 'elsif', @stmts)
    }, False)),
    else => (-> @ {
        q:b[\n} else {\n]
    }, False),
    end => (-> @control-stack {
        my ControlState $closed-directive = @control-stack.shift;
        "\n}\n"
    }, False);

sub extract-template-names(@tokens) {
    my @templates;
    my $parsing-templates = True;
    while $parsing-templates && @tokens {
        @templates.push: @tokens.shift;
        if @tokens && @tokens[0] eq '+' {
            @tokens.shift;
        }
        else {
            $parsing-templates = False;
        }
    }
    @templates
}

sub resolve-value($value) {
    given $value {
            when / \" (.*?) \" | \' (.*?) \' / {
                "'$0'"
            }
            when /^ \d+ ['.' \d+]? $/ {
                "'$value.Numeric()'"
            }    
            default {
                q[$stash.get('\qq[$value]')]
            }
        }
}

## Incomplete method, supply the $localline which must define a variable called $template
sub parse-template(@, @defs is copy, $localline) {
    my $return = '';
    my @templates = extract-template-names(@defs);
    $return ~= q:to/RAKU/;
    my %localdata;

    RAKU
    for @defs -> $name, $op, $value {
        $return ~= q:to/RAKU/
            %localdata<\qq[$name]> = \qq[&resolve-value($value)];
                
        RAKU
    }

    for @templates -> $template {
        $return ~= q:to/RAKU/;
        {
            my $tfile = \qq[&resolve-value($template)];

        RAKU
        $return ~= $localline;
        $return ~= q:to/RAKU/;
            with $template { $output ~= $_; }

        RAKU
        $return ~= q:to/RAKU/;
        }

        RAKU
    }
    $return
}

sub parse-get(@, Str:D $name) {
    q:to/RAKU/
    $output ~= $stash.get('\qq[$name]');
    RAKU
}

sub parse-set(@, :$default, *@values is copy) {
    my $return = '';
    for @values -> $name, $op, $value {
        if $default {
            $return ~= q:to/RAKU/;
            unless $stash.get('\qq[$name]', :strict) {

            RAKU
        }
        $return ~= q:to/RAKU/;
            $stash.put('\qq[$name]', \qq[&resolve-value($value)]);

        RAKU
        if $default {
            $return ~= q:to/RAKU/;
            }

            RAKU
        }
    }
    $return
}

sub parse-conditional(@control-stack, Str:D $name, @tokens is copy) {
    @control-stack.unshift('conditional');
    for @tokens -> $token is rw {
        next if $token (elem) @keywords;
        # TODO probably all numbers are good to go, not just integers
        next if $token ~~ /^ \d+ ['.' \d+]? $/;
        # If the token is a string, we need to resolve it to a stash lookup.
        next if $token ~~ / \" .*? \" | \' .*? \' /;

        $token .= subst(/^ ([\w|\-|.]+) $/, -> $word { "\$stash.get('$word', :strict)" });
    }
    my $statement = @tokens.join(' ');
    "$name $statement \{\n"
}

sub remove-comment(*@tokens --> List) {
    @tokens.toggle(* ne '#').cache
}

method !action(@control-stack, $statement, $prefix-linebreak) {
    my @stmts = $statement
      .lines
      .map({ remove-comment(.comb(/ \" .*? \" | \' .*? \' | \S+ /)) })
      .flat;
    return '' unless @stmts;

    
    my $name = @stmts.shift.lc;
    my $current-directive = %!directive-handlers{$name};
    without $current-directive {
        @stmts.unshift($name);
        $_ = @stmts.elems >= 3 && @stmts[1] eq '='
            ?? %!directive-handlers<set>
            !! %!directive-handlers<get>;
    }

    my $result;
    if $prefix-linebreak && $current-directive[1] {
        $result ~= q:to/RAKU/;
        $output ~= Q<\qq[$prefix-linebreak]>;
        RAKU
    }
    $result ~= $current-directive[0](@control-stack, |@stmts);
    $result
}

method get-safe-delimiter($raw-text) {
    my Set() $raw-words = $raw-text.words;
    (1..*).map('END' ~ *).first(* !(elem) $raw-words)
}

method compile($template) {
    my $script = q:to/RAKU/;
    return sub ($context) {
        my $stash = $context.stash;
        my $output = '';

    RAKU
    my @control-stack of ControlState;
    my @segments = $template.split(/ $<prefix-linebreak>=(\n?) '[%' $<comment-signature>=('#'?) \s* $<tokens>=(.*?) \s* '%]' /, :v);
    for @segments -> $segment {
        if $segment ~~ Stringy {
            my $safe-delimiter = self.get-safe-delimiter($segment);
            # Please do not change the string generation logic
            # without paying attention to the implications and
            # changing the test cases appropriately
            my $new-part = q:to/RAKU/;
            $output ~= Q:to/\qq[$safe-delimiter]/.chomp;
            \qq[$segment]
            \qq[$safe-delimiter]
            RAKU
            $script ~= $new-part;
        }
        elsif $segment ~~ Match && !~$segment<comment-signature> {
            my $statement = ~$segment<tokens>;
            $script ~= self!action(@control-stack, $statement, ~$segment<prefix-linebreak>);
        }
    }
    $script ~= q:to/RAKU/;
        return $output;
    }
    RAKU
    #note "<DEBUG:template>\n$script\n</DEBUG:template>";
    $script.subst( / 'my %localdata;' /, '', :nd(2..*) ).EVAL
}

# vim: expandtab shiftwidth=4
