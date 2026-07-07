#!/usr/bin/env perl6

use Test;

use CSS::Grammar::Test;

use CSS::Specification;
use CSS::Specification::Actions;

lives-ok {require CSS::Grammar:ver(v0.3.0..*) }, "CSS::Grammar version";

for (
    'values' => {
        input => 'thin',
        ast => :keyw<thin>,
    },
    'values' => {
        input => 'thin?',
        ast => :occurs['?', :keyw<thin>],
    },
    'values' => {
        input => 'thick | thin',
        ast => :keywords<thick thin>,
    },
    'values' => {
        input => '35 | 7',
        ast =>  :numbers[35, 7],
    },
    'values' => {
        input => '35 | 7 | 42?',
        ast => :alt[ :numbers[35, 7], :occurs['?', :num(42)] ]
    },
    'values' => {
        input => "<rule-ref>",
        ast => :rule<rule-ref>,
    },
    'values' => {
        input => "<rule-ref> [ 'css21-prop' <'css3-prop'> ]?",
        ast => :seq[ :rule<rule-ref>,
                     :occurs['?', :group(:seq[:rule<css-val-css21-prop>, :rule<css-val-css3-prop>]) ]
                   ],
    },
    'values' => {
        input => "<rule-ref> [, [ 'css21-prop' | <'css3-prop'> ] ]*",
        ast => :seq[ :rule<rule-ref>,
                     :occurs['*',
                             :group(:seq[:op<,>, :group(:alt[:rule<css-val-css21-prop>, :rule<css-val-css3-prop>]) ])
                            ],
                   ]
    },
    'values' => {
        input => '<length>{4}',
        ast => :occurs[ [4,4], :rule<length> ],
    },
    'values' => {
        input => '<length>#',
        ast => :occurs[ ',', :rule<length> ],
    },
    'values' => {
        input => '<length>#{1,4}',
        ast => :occurs[ [1,4,','], :rule<length> ],
    },
    # precedence tests taken from: https://developer.mozilla.org/en-US/docs/CSS/Value_definition_syntax
    'values' => {
        input => 'bold thin && <length>',
        ast => :required[
                        :seq[ :keyw<bold>, :keyw<thin> ]
                        :rule<length>,
                    ]
    },
    'values' => {
        input => 'bold || thin && <length>',
        ast => :combo[ :keyw<bold>,
                       :required[ :keyw<thin>, :rule<length>],
                     ]
    },
    'values' => {
        input => 'example( first? , second? , third? )',
        ast => :func<example>,
    },
    term => {
        input => '[<length> | auto]#{4,4}',
        ast => :occurs[[4,4, ','], :group{ :alt[ :rule<length>, :keyw<auto> ] } ],
    },
    'func-proto' => {
        input => 'attr(<identifier>)',
        ast => :proto{:func<attr>, :signature{ :args[:rule<identifier>] }, :synopsis('attr(<identifier>)')},
    },
    'func-proto' => {
        input => 'linear-gradient( [ <linear-gradient-syntax> ] )',
        ast => :proto{:func<linear-gradient>, :signature{ :args[:group(:rule<linear-gradient-syntax>)] }, :synopsis('linear-gradient( [ <linear-gradient-syntax> ] )'), },
        
    },
    'func-spec' => {
        input => '<linear-gradient()> = linear-gradient( [ <linear-gradient-syntax> ] )',
        ast => :func-spec{:func<linear-gradient>, :signature{ :args[:group(:rule<linear-gradient-syntax>)] }, :synopsis("linear-gradient( [ <linear-gradient-syntax> ] )")},
        child-rules => %( :linear-gradient["linear-gradient-syntax"] );
    },
   'values' => {
        input => '[ <length-percentage [0,∞]> | auto ]{1,2} | cover | contain',
        ast => :alt[:occurs[[1, 2], :group(:alt[:rule<length-percentage>, :keyw<auto>])], :keywords["cover", "contain"]],
    },
    'values' => {
        input => '<bg-layer>#? <final-bg-layer>',
        ast => :seq[:occurs[["*", ",", :!trailing, ], :rule<bg-layer>], :rule<final-bg-layer>]

    },
    'values' => {
        input => '<bg-layer>#? , <final-bg-layer>',
        ast => :seq[:occurs[["*", ",", :trailing, ], :rule<bg-layer>], :rule<final-bg-layer>]

    },
    'prop-spec' => {
        input => "'direction'	ltr | rtl | inherit	ltr	all elements, but see prose	yes",
        ast => :prop-spec{
            :props['direction'],
            :default<ltr>,
            :synopsis('ltr | rtl | inherit'),
            :spec(:keywords['ltr', 'rtl', 'inherit']),
            :inherit
        },
    },
    'prop-spec' => {
        input => "'content'\tnormal | none | [ <string> | <uri> | <counter> | attr(<identifier>) | open-quote | close-quote | no-open-quote | no-close-quote ]+ | inherit	normal	:before and :after pseudo-elements	no",
        ast => :prop-spec{:props['content'],
                :default<normal>,
                :synopsis('normal | none | [ <string> | <uri> | <counter> | attr(<identifier>) | open-quote | close-quote | no-open-quote | no-close-quote ]+ | inherit'),
                :spec(:alt[:keywords["normal", "none"], :occurs['+', :group(:alt[:rule("string"), :rule("uri"), :rule("counter"), :func("attr"), :keywords["open-quote", "close-quote", "no-open-quote", "no-close-quote"]])], :keyw<inherit>]),
                :!inherit,
               },
        child-rules => %(:css-val-content["string", "uri", "counter", "identifier"]),
    },
    func-spec => {
        input => q{<calc()> = calc( <calc-sum> )},
        ast => :func-spec{:func<calc>, :signature{:args[:rule("calc-sum")]}, :synopsis("calc( <calc-sum> )")},
    },
    func-spec => {
        input => '<example()> = example( first , second? , third? )',
        ast => :func-spec{
            :func<example>,
            :signature{:args[:keyw<first>, :optional[ :keyw<second>, :keyw<third>]]},
            :synopsis("example( first , second? , third? )"),
        }
    },
    func-spec => {
        input => '<icc-color()> = icc-color(<name> [,<number>]{2}?)',
        ast => :func-spec{
            :func<icc-color>,
            :signature{:seq[:rule<name>, :occurs['?', :occurs[[2,2], :group(:seq[:op<,>, :rule<number>])]]]},
            :synopsis('icc-color(<name> [,<number>]{2}?)'),
        },
        child-rules => %(:icc-color["name", "number"]),
    },

    rule-spec => {
        input => q{<calc-sum> = <calc-product> [ [ '+' | '-' ] <calc-product> ]*},
        ast => :rule-spec{:rule<calc-sum>, :spec(:seq[:rule<calc-product>, :occurs["*", :group(:seq[:group(:alt[:op("+"), :op("-")]), :rule<calc-product>])]]), :synopsis("<calc-product> [ [ '+' | '-' ] <calc-product> ]*")},
        child-rules => %(:calc-sum["calc-product", "calc-product"]),
    },
    # css1 spec with property name and '*' junk
    prop-spec => {
        input => "'width' *\t<length> | <percentage> | auto	auto	all elements but non-replaced inline elements, table rows, and row groups	no",
        ast => Mu,
    },
    prop-spec => {
        input => q{'border'	[ 'border-width' || 'border-style' || 'border-color' ] | inherit	see individual properties	 	no	 	visual},
        ast => Mu,
        child-rules => %(:css-val-border["css-val-border-width", "css-val-border-style", "css-val-border-color"]),
    },
    ) {

    my $rule     := .key;
    my $expected := .value;
    my $input    := $expected<input>;
    subtest "$rule: $input", {

        my CSS::Specification::Actions $actions .= new;

        my @*DECL-NAMES = [];

        CSS::Grammar::Test::parse-tests(
            CSS::Specification, $input,
            :$rule,
            :$actions,
            :suite<spec>,
            :$expected
        );

        if $expected<child-rules> -> $child-rules {
            is-deeply $actions.child-rules, $child-rules, 'child-rules';
        }
    }
}

done-testing;
