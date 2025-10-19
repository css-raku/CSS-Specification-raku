use Test;
use CSS::Grammar::Test;
use CSS::Grammar::CSS21;
use CSS::Specification::Build;
use CSS::Specification::Compiler;
use lib 't';
use experimental :rakuast;

sub capture($code, $output-path) {
    my $*OUT = open $output-path, :w;
    $code();
    $*OUT.close;
    $output-path;
}

my @base-id = qw<Test CSS Aural Spec>;
my $base-name = @base-id.join: '::';
my @actions-id = @base-id.Slip, 'Actions';
my $actions-name = @actions-id.join: '::';
my @role-id = @base-id.Slip, 'Interface';
my @grammar-id = @base-id.Slip, 'Grammar';
my $grammar-name = @grammar-id.join: '::';

my $input-path = $*SPEC.catfile('examples', 'css21-aural.txt');

my CSS::Specification::Compiler $compiler .= new;
$compiler.load-defs($input-path);

my @summary = CSS::Specification::Build::summary( :$input-path );
is +@summary, 25, 'number of summary items';
is-deeply [@summary.grep({ .<box> })], [{:box, :!inherit, :name<border-color>, :edges["border-top-color", "border-right-color", "border-bottom-color", "border-left-color"], :synopsis("[ <color> | transparent ]\{1,4}")},], 'summary item';

capture({
    CSS::Specification::Build::generate( 'grammar', $grammar-name, :$input-path );
}, 't/lib/Test/CSS/Aural/Spec/Grammar.rakumod');
lives-ok {require ::($grammar-name)}, "$grammar-name compilation";

my RakuAST::StatementList $grammar = $compiler.build-grammar(@grammar-id);

't/lib/Test/CSS/Aural/Spec/GrammarAST.rakumod'.IO.spurt: $grammar.DEPARSE;

capture({
    CSS::Specification::Build::generate( 'actions', $actions-name, :$input-path );
}, 't/lib/Test/CSS/Aural/Spec/Actions.rakumod');
lives-ok {require ::($actions-name)}, "$actions-name compilation";

my RakuAST::Package $actions-pkg = $compiler.build-actions(@actions-id);

't/lib/Test/CSS/Aural/Spec/ActionsAST.rakumod'.IO.spurt: $actions-pkg.DEPARSE;

my $role-name = @role-id.join: '::';
my RakuAST::Package $interface-pkg = $compiler.build-role(@role-id);
't/lib/Test/CSS/Aural/Spec/Interface.rakumod'.IO.spurt: $interface-pkg.DEPARSE;
lives-ok {require ::($role-name)}, "$role-name compilation";

dies-ok {require ::("Test::CSS::Aural::BadGrammar")}, 'grammar composition, unimplemented interface - dies';

my $aural-class;
lives-ok {$aural-class = (require ::("Test::CSS::Aural::Grammar"))}, 'grammar composition - lives';
isa-ok $aural-class, CSS::Grammar::CSS21;

my $actions;
lives-ok {$actions = (require ::("Test::CSS::Aural::Actions")).new}, 'class composition - lives';
ok $actions.defined, '::("Test::CSS::Aural::Actions").new';

for ('.aural-test { stress: 42; speech-rate: fast; volume: inherit; voice-family: female; }' =>
     {ast => { :stylesheet[
               :ruleset{
                   :selectors[ :selector[ :simple-selector[ :class<aural-test> ] ] ],
                   :declarations[
                       :property{ :ident<stress>, :expr[{ :num(42) }] },
                       :property{ :ident<speech-rate>, :expr[{ :keyw<fast> }] },
                       :property{ :ident<volume>, :expr[{ :keyw<inherit> }] },
                       :property{ :ident<voice-family>, :expr[{ :keyw<female> }] },
                       ],
                    }
                   ]}
      },
     '.boxed-test { border-color: #aaa }' =>
     {ast => { :stylesheet[
                    :ruleset{
                        :selectors[ :selector[ :simple-selector[{:class<boxed-test>}] ]],
                        :declarations[ :property{
                            :ident<border-color>,
                            :expr[{ :rgb[ :num(170), :num(170), :num(170) ]}]}],
                    }
                   ]}
     },
    ) {
    my ($input, $expected) = .kv;

    &CSS::Grammar::Test::parse-tests($aural-class, $input, 
                                     :$actions, :$expected);
}
done-testing;
