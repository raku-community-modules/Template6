unit class Template6::Parser;

my @keywords = 'eq', 'ne', 'lt', 'gt', 'gte', 'lte';
has $.context;
has %!directive-handlers =
    insert => -> *@defs {
        my $localline = 'my $template = $context.get-template-text($tfile);' ~ "\n";
        parse-template(@defs, $localline)
    },
    include => -> *@defs {
        my $localline = 'my $template = $context.process($tfile, :localise, |%localdata);' ~ "\n";
        parse-template(@defs, $localline)
    },
    process => -> *@defs {
        my $localline = 'my $template = $context.process($tfile, |%localdata);' ~ "\n";
        parse-template(@defs, $localline)
    },
    call => -> Str:D $name {
        q:to/RAKU/
        $stash.get('\qq[$name]');
        RAKU
    },
    get => &parse-get,
    set => &parse-set,
    default => -> *@values {
        parse-set(:default, @values)
    },
    for => -> $left, $op, $right {
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
    },
    if => -> *@stmts {
        parse-conditional('if', @stmts)
    },
    unless => -> *@stmts {
        parse-conditional('unless', @stmts)
    },
    |(<elseif elsif> X=> -> *@stmts {
        "\n}\n" ~ parse-conditional('elsif', @stmts)
    }),
    else => -> {
        q:b[\n} else {\n]
    },
    end => -> {
        "\n}\n"
    };

## Incomplete method, supply the $localline which must define a variable called $template
sub parse-template(@defs is copy, $localline) {
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
    $return ~= q:to/RAKU/;
    my %localdata;

    RAKU
    for @defs -> $name, $op, $value {
        $return ~= do given $value {
            when / \" (.*?) \" | \' (.*?) \' / {
                q:to/RAKU/
                %localdata<\qq[$name]> = '\qq[$0]';
                
                RAKU
            }
            when /^ \d+ ['.' \d+]? $/ {
                q:to/RAKU/
                %localdata<\qq[$name]> = '\qq[$value.Numeric()]';
                
                RAKU
            }    
            default {
                q:to/RAKU/
                %localdata<\qq[$name]> = $stash.get('\qq[$value]');
                
                RAKU
            }
        }
    }

    for @templates -> $template is rw {
        $template ~~ s/^[\"|\']//;
        $template ~~ s/[\"|\']$//;
        $return ~= q:to/RAKU/;
        {
            my $tfile = $stash.get('\qq[$template]');

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

sub parse-get(Str:D $name) {
    q:to/RAKU/
    $output ~= $stash.get('\qq[$name]');
    RAKU
}

sub parse-set(:$default, *@values is copy) {
    my $return = '';
    for @values -> $name, $op, $value {
        if $default {
            $return ~= q:to/RAKU/;
            unless $stash.get('\qq[$name]', :strict) {

            RAKU
        }
        $return ~= do given $value {
            when / \" (.*?) \" | \' (.*?) \' / {
                q:to/RAKU/
                $stash.put('\qq[$name]', '\qq[$0]');

                RAKU
            }
            when /^ \d+ ['.' \d+]? $/ {
                q:to/RAKU/
                stash.put('\qq[$name]', \qq[$value.Numeric()]);

                RAKU
            }
            default {
                q:to/RAKU/
                $stash.put('\qq[$name]', $stash.get('\qq[$value]'));

                RAKU
            }
        }
        if $default {
            $return ~= q:to/RAKU/;
            }

            RAKU
        }
    }
    $return
}

sub parse-conditional(Str:D $name, @tokens is copy) {
    for @tokens -> $token is rw {
        next if $token (elem) @keywords;
        next if $token ~~ /^ \d+ ['.' \d+]? $/; # TODO probably all numbers are good to go, not just integers
        $token .= subst(/^ (\w+) $/, -> $word { "\$stash.get('$word', :strict)" });
    }
    my $statement = @tokens.join(' ');
    "$name $statement \{\n"
}

sub remove-comment(*@tokens --> List) {
    @tokens.toggle(* ne '#').cache
}

method !action($statement) {
    my @stmts = $statement
      .lines
      .map({ remove-comment(.comb(/ \" .*? \" | \' .*? \' | \S+ /)) })
      .flat;
    return '' unless @stmts;

    my $name = @stmts.shift.lc;
    $name (elem) %!directive-handlers
      ?? %!directive-handlers{$name}(|@stmts)
      !! @stmts.elems >= 2 && @stmts[0] eq '='
        ?? parse-set($name, |@stmts)
        !! parse-get($name)
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
    my @segments = $template.split(/ \n? '[%' $<comment-signature>=('#'?) \s* $<tokens>=(.*?) \s* '%]' /, :v);
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
            $script ~= self!action($statement);
        }
    }
    $script ~= q:to/RAKU/;
        return $output;
    }
    RAKU
#    $*ERR.say: "<DEBUG:template>\n$script\n</DEBUG:template>";
    $script.subst( / 'my %localdata;' /, '', :nd(2..*) ).EVAL
}

# vim: expandtab shiftwidth=4
