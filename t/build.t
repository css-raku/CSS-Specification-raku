use Test;
use CSS::Grammar::Test;
use CSS::Grammar::CSS21;
use CSS::Specification::Build;
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
my $grammar-name = $base-name ~ '::Grammar';
my $actions-name = $base-name ~ '::Actions';
my @role-id = @base-id.Slip, 'Interface';

my $input-path = $*SPEC.catfile('examples', 'css21-aural.txt');
my @summary = CSS::Specification::Build::summary( :$input-path );
is +@summary, 25, 'number of summary items';
is-deeply [@summary.grep({ .<box> })], [{:box, :!inherit, :name<border-color>, :edges["border-top-color", "border-right-color", "border-bottom-color", "border-left-color"], :synopsis("[ <color> | transparent ]\{1,4}")},], 'summary item';

capture({
    CSS::Specification::Build::generate( 'grammar', $grammar-name, :$input-path );
}, 't/lib/Test/CSS/Aural/Spec/Grammar.rakumod');
lives-ok {require ::($grammar-name)}, "$grammar-name compilation";

capture({
    CSS::Specification::Build::generate( 'actions', $actions-name, :$input-path );
}, 't/lib/Test/CSS/Aural/Spec/Actions.rakumod');
lives-ok {require ::($actions-name)}, "$actions-name compilation";

my $role-name = @role-id.join: '::';

capture({
    CSS::Specification::Build::generate( 'interface', $role-name, :$input-path );
}, 't/lib/Test/CSS/Aural/Spec/Interface.rakumod');
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
