# Template6: A Template Engine for Perl 6 #

Inspired by Template Toolkit from Perl 5,
Template6 is a simple template engine designed to be
a content-neutral template language.

Eventually, I intend for this to be as powerful as
Template Toolkit, but for now I'm keeping it simple
and leaving it capable of easily adding new functionality.

I also intend to borrow features and ideas from
my own Flower and Garden projects.

## Currently implemented features

*    get and set statements, including implicit versions.

     * [% get varname %]
     * [% varname %]
     * [% set varname = value %]
     * [% varname = value %]

*    for statement.

     This replaces the FOREACH statement in TT2.
     It can be used in one of four ways:
     * [% for listname as itemname %]
     * [% for listname -> itemname %]
     * [% for itemname in listname %]
     * [% for itemname = listname %]
     If used with Hashes, you'll need to query the .key or .value accessors.

*    if/elsif/else/unless statements.

     These are very simplistic at the moment, but work for basic tests.

*    Querying nested data structures using a simple dot operator syntax.

## TODO

### Short Term Goals

 * call and default statements
 * insert, include, process and wrapper statements
 * block statements
 * given/when statements

### Medium Term Goals

 * Whitespace control
 * Precompiled/cached templates
 * Tag styles (limited to definable start_tag and end_tag)
 * Capture of directive output
 * Filters

### Long Term Goals

 * Directive comments
 * Side-effect notation
 * Multiple directives in a single statement tag set

## Possible future directions

I would also like to investigate the potential for an alternative to Template6::Parser that
generates Perl 6 closures without the use of eval. This would be far trickier, and would not
be compatible with the precompiled templates, but would be an interesting exercise nonetheless.

## Author

This was build by Timothy Totten. You can find me on #perl6 with the nickname supernovus.

## License

Artistic License 2.0

