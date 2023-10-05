#!/usr/bin/env perl6

use Test;
use CSS::Grammar::Test;

use CSS::Specification;
use CSS::Specification::Compiler;
use CSS::Specification::Compiler::Actions;

lives-ok {require CSS::Grammar:ver(v0.3.0..*) }, "CSS::Grammar version";

for (
    'spec' => {
        input => 'thin',
        ast   => :keywords['thin'],
        deparse => '[thin & <keyw>]',
    },
    'spec' => {
        input => 'thin?',
        ast   => :occurs['?', :keyw<thin>],
        deparse => '[thin& <keyw>]?',
    },
    'spec' => {
        input => 'thick | thin',
        ast => :keywords[ 'thick', 'thin' ],
        deparse => '[[thick | thin ]& <keyw>]',
    },
    'spec' => {
        input => '35 | 7',
        ast => :numbers[ 35, 7 ],
        deparse => '[[35 | 7 ]& <number>]',
    },
    'spec' => {
        input => '35 | 7 | 42?',
        ast => :alt[:numbers[35, 7], :occurs["?", :num(42)]],
        deparse => '[[35 | 7 ]& <number>]| [42& <number>]?',
    },
    'spec' => {
        input => "<rule-ref>",
        ast => :rule<rule-ref>,
        deparse => "<rule-ref>",
        rule-refs => ['rule-ref'],
    },
    'spec' => {
        input => "'css21-prop-ref'",
        ast => :rule<expr-css21-prop-ref>,
        deparse => "<expr-css21-prop-ref>",
        rule-refs => ['expr-css21-prop-ref'],
    },
    'spec' => {
        input => "<rule-ref> [ 'css21-prop-ref' <'css3-prop-ref'> ]?",
        ast => :seq[:rule<rule-ref>, :occurs["?", :group( :seq[:rule<expr-css21-prop-ref>, :rule<expr-css3-prop-ref> ]) ] ],
        deparse => "<rule-ref>[<expr-css21-prop-ref><expr-css3-prop-ref>]?",
        rule-refs => ["expr-css21-prop-ref", "expr-css3-prop-ref", "rule-ref"],
    },
    'spec' => {
        input => "<rule-ref> [, [ 'css21-prop-ref' | <'css3-prop-ref'> ] ]*",
        ast => :seq[ :rule<rule-ref>, :occurs["*", :group( :seq[:op<,>, :group(:alt[:rule<expr-css21-prop-ref>, :rule<expr-css3-prop-ref>])])]],
        deparse => '<rule-ref>[<op(",")>[<expr-css21-prop-ref>| <expr-css3-prop-ref>]]*',
        rule-refs => ["expr-css21-prop-ref", "expr-css3-prop-ref", "rule-ref"],
    },
    'spec' => {
        input => '<length>{4}',
        ast => :occurs[['seq',4,4], :rule<length>],
        deparse => '<length>** 4',
        rule-refs => ['length'],
    },
    'spec' => {
        input => '<length>#',
        ast => :occurs['list', :rule<length>],
        deparse => '<length>+% <op(",")>',
        rule-refs => ['length'],
    },
    'spec' => {
        input => '<length>#{1,4}',
        ast => :occurs[['list', 1, 4], :rule<length>],
        deparse => '<length>** 1..4% <op(",")>',
        rule-refs => ['length'],
    },
    'spec' => {
        input => 'attr(<identifier>)',
        ast => :rule<attr>,
        deparse => '<attr>',
        rule-refs => ['attr', 'identifier'],
    },
    'property-spec' => {
        input => "'direction'	ltr | rtl | inherit	ltr	all elements, but see prose	yes",
        ast => {
            :props['direction'],
            :default<ltr>,
            :spec(:keywords["ltr", "rtl", "inherit"]),
            :synopsis("ltr | rtl | inherit"),
            :inherit
        },
    },
##    # precedence tests taken from: https://developer.mozilla.org/en-US/docs/CSS/Value_definition_syntax
    'spec' => {
        input => 'bold thin && <length>',
        ast => :required[:seq[:keywords["bold"], :keywords["thin"]], :rule("length")],
        deparse => '[:my @S; [bold & <keyw>][thin & <keyw>]<!@S[0]++>| <length><!@S[1]++>]** 2',
        rule-refs => ['length'],
    },
    'spec' => {
        input => 'bold || thin && <length>',
        ast => :combo[:keywords["bold"], :required[:keywords["thin"], :rule("length")]],
        deparse => '[:my @S; [bold & <keyw>]<!@S[0]++>| [:my @S; [thin & <keyw>]<!@S[0]++>| <length><!@S[1]++>]** 2<!@S[1]++>]+',
        rule-refs => ['length'],
    },
##    'property-spec' => {input => "'content'\tnormal | none | [ <string> | <uri> | <counter> | attr(<identifier>) | open-quote | close-quote | no-open-quote | no-close-quote ]+ | inherit	normal	:before and :after pseudo-elements	no",
##                        ast => {:props['content'],
##                                :default<normal>,
##                                :raku('[ [ normal | none ] & <keyw> || [ [ <string> || <uri> || <counter> || <attr> || [ open\\-quote | close\\-quote | no\\-open\\-quote | no\\-close\\-quote ] & <keyw> ] ]+ || inherit & <keyw> ]'),
##                                :synopsis('normal | none | [ <string> | <uri> | <counter> | attr(<identifier>) | open-quote | close-quote | no-open-quote | no-close-quote ]+ | inherit'),
##                                :!inherit,
##                        },
##    },
##    # css1 spec with property name and '*' junk
##    property-spec => {input => "'width' *\t<length> | <percentage> | auto	auto	all elements but non-replaced inline elements, table rows, and row groups	no",
##                      ast => Mu,
##    },
    ) {

    my $rule := .key;
    my $expected := .value;
    my $input := $expected<input>;
    my $deparse := $expected<deparse>;
    my $rule-refs := $expected<rule-refs>;

    my @*PROP-NAMES = [];

    my CSS::Specification::Compiler::Actions $actions .= new;

    my $parse = CSS::Grammar::Test::parse-tests(
        CSS::Specification, $input,
        :$rule,
        :$actions,
        :suite<spec>,
        :$expected
    );

    with $deparse {
        my $AST = CSS::Specification::Compiler::compile(|$parse.ast);
        is $AST.DEPARSE, $_, 'deparse';
    }

    my @refs = $actions.rule-refs.keys.sort.Array;
    if @refs || $rule-refs {
        is-deeply @refs, $rule-refs, "rule-refs";
    }
}

done-testing;