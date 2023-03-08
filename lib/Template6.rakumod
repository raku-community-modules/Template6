unit class Template6;

use Template6::Service;

has $.service handles <process context add-path set-extension add-template add-provider>;

submethod BUILD (*%args) {
    $!service = %args<service> || Template6::Service.new(|%args);
}

=begin pod

=head1 NAME

Template6 - A Template Engine for Raku

=head1 SYNOPSIS

=begin code :lang<raku>

use Template6;

=end code

=head1 DESCRIPTION

Inspired by Template Toolkit from Perl,
Template6 is a simple template engine designed to be
a content-neutral template language.

I also intend to borrow features and ideas from
my own Flower and Garden projects.

This project does not intend to create an exact clone of
Template Toolkit. Some features from TT are not planned for
inclusion, and likewise, some feature will be included that
are not in TT. Not all features will work the same either.

=head2 Currently implemented features

=head3 GET and SET statements, including implicit versions.

=item [% get varname %]
=item [% varname %]
=item [% set varname = value %]
=item [% varname = value %]

=head3 FOR statement.

This replaces the FOREACH statement in TT2.
It can be used in one of four ways:

=item [% for listname as itemname %]
=item [% for listname -> itemname %]
=item [% for itemname in listname %]
=item [% for itemname = listname %]

If used with Hashes, you'll need to query the .key or .value accessors.

=head3 IF/ELSIF/ELSE/UNLESS statements.

These are very simplistic at the moment, but work for basic tests.

=item Querying nested data structures using a simple dot operator syntax.
=item CALL and DEFAULT statements.
=item INSERT, INCLUDE and PROCESS statements.

=head2 Differences with Template Toolkit

=item You should use explicit quotes, including in INSERT/INCLUDE/PROCESS directives.
=item UNLESS-ELSE is not supported - Raku also doesn't support this syntax
=item All statement directives are case insensitive.
=item There are no plans for the INTERPOLATE option/style.
=item Anything not yet implemented (see TODO below.)

=head2 Caveats

=item Whitespace control is not implemented, so some things are fairly odd. See TODO.
=item A lot of little nit-picky stuff, likely related to the whitespace issue.

=head2 TODO

=head3 Short Term Goals

=item WRAPPER statement
=item block statements
=item given/when statements
=item Add 'absolute' and 'relative' options to Template6::Provider::File
=item Whitespace control
=item Precompiled/cached templates
=item Tag styles (limited to definable start_tag and end_tag)

=head3 Long Term Goals

=item Filters
=item Variable interpolation (in strings, variable names, etc.)
=item Capture of directive output
=item Directive comments
=item Side-effect notation
=item Multiple directives in a single statement tag set
=item Macros, plugins, etc.

=head2 Possible future directions

I would also like to investigate the potential for an alternative to
Template6::Parser that generates Raku closures without the use of EVAL.
This would be far trickier, and would not be compatible with the
precompiled templates, but would be an interesting exercise nonetheless.

=head1 AUTHOR

Timothy Totten

=head1 COPYRIGHT AND LICENSE

Copyright 2012 - 2017 Timothy Totten

Copyright 2018 - 2023 Raku Community

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

# vim: expandtab shiftwidth=4
