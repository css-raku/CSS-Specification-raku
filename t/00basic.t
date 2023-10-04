#!/usr/bin/env perl6

use Test;

use CSS::Grammar::Test;

use CSS::Specification;
use CSS::Specification::Actions;

lives-ok {require CSS::Grammar:ver(v0.3.0..*) }, "CSS::Grammar version";

my CSS::Specification::Actions $actions .= new;

for (
    'spec' => {
        input => 'thin',
        ast => 'thin & <keyw>',
    },
    'spec' => {
        input => 'thin?',
        ast => '[ thin & <keyw> ]?',
    },
    'spec' => {
        input => 'thick | thin',
        ast => '[ thick | thin ] & <keyw>',
    },
    'spec' => {
        input => '35 | 7',
        ast => '[ 35 | 7 ] & <number>',
    },
    'spec' => {
        input => '35 | 7 | 42?',
        ast => '[ [ 35 | 7 ] & <number> || [ 42 & <number> ]? ]',
    },
    'spec' => {
        input => "<rule-ref>",
        ast => "<rule-ref>",
    },
    'spec' => {
        input => "<rule-ref> [ 'css21-prop-ref' <'css3-prop-ref'> ]?",
        ast => "<rule-ref> [ <expr-css21-prop-ref> <expr-css3-prop-ref> ]?",
    },
    'spec' => {
        input => "<rule-ref> [, [ 'css21-prop-ref' | <'css3-prop-ref'> ] ]*",
        ast => "<rule-ref> [ <op(',')> [ [ <expr-css21-prop-ref> || <expr-css3-prop-ref> ] ] ]*",
    },
    'spec' => {
        input => '<length>{4}',
        ast => '<length> ** 4',
    },
    'spec' => {
        input => '<length>#',
        ast => "<length>+% <op(',')>",
    },
    'spec' => {
        input => '<length>#{1,4}',
        ast => "<length> ** 1..4% <op(',')>",
    },
    # precedence tests taken from: https://developer.mozilla.org/en-US/docs/CSS/Value_definition_syntax
    'spec' => {
        input => 'bold thin && <length>',
        ast => ':my @S; [ bold & <keyw> thin & <keyw> <!{@S[0]++}> | <length> <!{@S[1]++}> ]**2',
    },
    'spec' => {
        input => 'bold || thin && <length>',
        ast => ':my @S; [ bold & <keyw> <!{@S[2]++}> | [ thin & <keyw> <!{@S[0]++}> | <length> <!{@S[1]++}> ]**2 <!{@S[3]++}> ]+',
    },
    'property-spec' => {
        input => "'content'\tnormal | none | [ <string> | <uri> | <counter> | attr(<identifier>) | open-quote | close-quote | no-open-quote | no-close-quote ]+ | inherit	normal	:before and :after pseudo-elements	no",
        ast => {:props['content'],
                :default<normal>,
                :raku('[ [ normal | none ] & <keyw> || [ [ <string> || <uri> || <counter> || <attr> || [ open\\-quote | close\\-quote | no\\-open\\-quote | no\\-close\\-quote ] & <keyw> ] ]+ || inherit & <keyw> ]'),
                :synopsis('normal | none | [ <string> | <uri> | <counter> | attr(<identifier>) | open-quote | close-quote | no-open-quote | no-close-quote ]+ | inherit'),
                :!inherit,
               },
    },
    # css1 spec with property name and '*' junk
    property-spec => {
        input => "'width' *\t<length> | <percentage> | auto	auto	all elements but non-replaced inline elements, table rows, and row groups	no",
        ast => Mu,
    },
    ) {

    my $rule := .key;
    my $expected := .value;
    my $input := $expected<input>;

    my @*PROP-NAMES = [];

    CSS::Grammar::Test::parse-tests(
        CSS::Specification, $input,
        :$rule,
        :$actions,
        :suite<spec>,
        :$expected
    )
;
    my $rule-body := $/.ast;
    $rule-body := $rule-body<raku>
        if $rule-body.isa('Hash');

    with $rule-body {
        my $anon-rule := "rule \{ $_ \}";
        lives-ok {EVAL $anon-rule}, "$rule compiles"
            or diag "invalid rule: $rule-body";
    }
}

done-testing;
