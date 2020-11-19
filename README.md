# Template6: A Template Engine for Raku #

Inspired by Template Toolkit from Perl,
Template6 is a simple template engine designed to be
a content-neutral template language.

I also intend to borrow features and ideas from
my own Flower and Garden projects.

This project does not intend to create an exact clone of
Template Toolkit. Some features from TT are not planned for
inclusion, and likewise, some feature will be included that
are not in TT. Not all features will work the same either.

## Currently implemented features

*    GET and SET statements, including implicit versions.

     * [% get varname %]
     * [% varname %]
     * [% set varname = value %]
     * [% varname = value %]

*    FOR statement.

     This replaces the FOREACH statement in TT2.
     It can be used in one of four ways:

     * [% for listname as itemname %]
     * [% for listname -> itemname %]
     * [% for itemname in listname %]
     * [% for itemname = listname %]

     If used with Hashes, you'll need to query the .key or .value accessors.

*    IF/ELSIF/ELSE/UNLESS statements.

     These are very simplistic at the moment, but work for basic tests.

*    Querying nested data structures using a simple dot operator syntax.
*    CALL and DEFAULT statements.
*    INSERT, INCLUDE and PROCESS statements.

## Differences with Template Toolkit

 * You should use explicit quotes, including in INSERT/INCLUDE/PROCESS directives.
 * All statement directives are case insensitive.
 * There are no plans for the INTERPOLATE option/style.
 * Anything not yet implemented (see TODO below.)

## Caveats

 * Whitespace control is not implemented, so some things are fairly odd. See TODO.
 * A lot of little nit-picky stuff, likely related to the whitespace issue.

## TODO

### Short Term Goals

 * WRAPPER statement
 * block statements
 * given/when statements
 * Add 'absolute' and 'relative' options to Template6::Provider::File
 * Whitespace control
 * Precompiled/cached templates
 * Tag styles (limited to definable start_tag and end_tag)

### Long Term Goals

 * Filters
 * Variable interpolation (in strings, variable names, etc.)
 * Capture of directive output
 * Directive comments
 * Side-effect notation
 * Multiple directives in a single statement tag set
 * Macros, plugins, etc.

## Possible future directions

I would also like to investigate the potential for an alternative to Template6::Parser that
generates Raku closures without the use of eval. This would be far trickier, and would not
be compatible with the precompiled templates, but would be an interesting exercise nonetheless.

## Author

This was build by Timothy Totten. You can find me on #raku with the nickname supernovus.

## License

Artistic License 2.0

