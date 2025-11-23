#!/usr/bin/env perl6

use Test;

use CSS::Grammar::Test;

use CSS::Specification;
use CSS::Specification::Actions;

lives-ok {require CSS::Grammar:ver(v0.3.0..*) }, "CSS::Grammar version";

my CSS::Specification::Actions $actions .= new;

for (
    'values' => {
        input => 'thin',
        ast => :keywords['thin'],
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
                     :occurs['?', :group(:seq[:rule<prop-val-css21-prop>, :rule<prop-val-css3-prop>]) ]
                   ],
    },
    'values' => {
        input => "<rule-ref> [, [ 'css21-prop' | <'css3-prop'> ] ]*",
        ast => :seq[ :rule<rule-ref>,
                     :occurs['*',
                             :group(:seq[:op<,>, :group(:alt[:rule<prop-val-css21-prop>, :rule<prop-val-css3-prop>]) ])
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
                        :seq[ :keywords['bold'], :keywords['thin'] ]
                        :rule<length>,
                    ]
    },
    'values' => {
        input => 'bold || thin && <length>',
        ast => :combo[ :keywords['bold'],
                       :required[ :keywords['thin'], :rule<length>],
                     ]
    },
    'func-proto' => {
        input => 'attr(<identifier>)',
        ast => :proto{:func<attr>, :signature(:rule<identifier>), :synopsis('attr(<identifier>)')},
    },
    'func-proto' => {
        input => 'linear-gradient( [ <linear-gradient-syntax> ] )',
        ast => :proto{:func<linear-gradient>, :signature(:group(:rule<linear-gradient-syntax>)), :synopsis('linear-gradient( [ <linear-gradient-syntax> ] )'), }
    },
    'func-spec' => {
        input => '<linear-gradient()> = linear-gradient( [ <linear-gradient-syntax> ] )',
        ast => :func-spec{:func<linear-gradient>, :signature(:group(:rule<linear-gradient-syntax>)), :synopsis("linear-gradient( [ <linear-gradient-syntax> ] )")}
    },
   'values' => {
        input => '[ <length-percentage [0,∞]> | auto ]{1,2} | cover | contain',
        ast => :alt[:occurs[[1, 2], :group(:alt[:rule<length-percentage>, :keywords["auto"]])], :keywords["cover", "contain"]],
    },
    'values' => {
        input => '<bg-layer>#? <final-bg-layer>',
        ast => :seq[:occurs[["*", ",", :!trailing, ], :rule<bg-layer>], :rule<final-bg-layer>]

    },
    'values' => {
        input => '<bg-layer>#? , <final-bg-layer>',
        ast => :seq[:occurs[["*", ",", :trailing, ], :rule<bg-layer>], :rule<final-bg-layer>]

    },
    'property-spec' => {
        input => "'direction'	ltr | rtl | inherit	ltr	all elements, but see prose	yes",
        ast => {
            :props['direction'],
            :default<ltr>,
            :synopsis('ltr | rtl | inherit'),
            :spec(:keywords['ltr', 'rtl', 'inherit']),
            :inherit
        }
    },
    'property-spec' => {
        input => "'content'\tnormal | none | [ <string> | <uri> | <counter> | attr(<identifier>) | open-quote | close-quote | no-open-quote | no-close-quote ]+ | inherit	normal	:before and :after pseudo-elements	no",
        ast => {:props['content'],
                :default<normal>,
                :synopsis('normal | none | [ <string> | <uri> | <counter> | attr(<identifier>) | open-quote | close-quote | no-open-quote | no-close-quote ]+ | inherit'),
                :spec(:alt[:keywords["normal", "none"], :occurs['+', :group(:alt[:rule("string"), :rule("uri"), :rule("counter"), :func("attr"), :keywords["open-quote", "close-quote", "no-open-quote", "no-close-quote"]])], :keywords["inherit"]]),
                :!inherit,
               },
    },
    func-spec => {
        input => q{<calc()> = calc( <calc-sum> )},
        ast => :func-spec{:func<calc>, :signature(:rule("calc-sum")), :synopsis("calc( <calc-sum> )")},
    },
    rule-spec => {
        input => q{<calc-sum> = <calc-product> [ [ '+' | '-' ] <calc-product> ]*},
        ast => {:rule<calc-sum>, :spec(:seq[:rule<calc-product>, :occurs["*", :group(:seq[:group(:alt[:op("+"), :op("-")]), :rule<calc-product>])]]), :synopsis("<calc-product> [ [ '+' | '-' ] <calc-product> ]*")},
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
