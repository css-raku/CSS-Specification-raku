use Test;
use CSS::Grammar::Test;
use CSS::Grammar::CSS21;
use CSS::Specification::Compiler;
use lib 't';
use experimental :rakuast;

my @base-id = qw<Test CSS Aural Spec>;
my @actions-id = @base-id.Slip, 'Actions';
my @role-id = @base-id.Slip, 'Interface';
my @grammar-id = @base-id.Slip, 'Grammar';

my $input-path = $*SPEC.catfile('examples', 'css21-aural.txt');

my CSS::Specification::Compiler $compiler .= new;
$compiler.load-defs($input-path);

sub name(RakuAST::Package $p, $j) {
    $p.name.parts>>.name.join: $j
}

is +$compiler.defs, 24, 'number of summary items';

my RakuAST::Package $grammar = $compiler.build-grammar(@grammar-id);
"t/lib/{$grammar.&name('/')}.rakumod".IO.spurt: $grammar.DEPARSE
.subst(/";\n;"/, ';', :g); # work-around for https://github.com/rakudo/rakudo/issues/5991

my RakuAST::Package $actions-pkg = $compiler.build-actions(@actions-id);
"t/lib/{$actions-pkg.&name('/')}.rakumod".IO.spurt: $actions-pkg.DEPARSE;

my $role-name = @role-id.join: '::';
my RakuAST::Package $interface-pkg = $compiler.build-role(@role-id);
"t/lib/{$interface-pkg.&name('/')}.rakumod".IO.spurt: $interface-pkg.DEPARSE;
lives-ok {require ::($role-name)}, "$role-name compilation";

dies-ok {require ::("Test::CSS::Aural::BadGrammar")}, 'grammar composition, unimplemented interface - dies';

my $aural-class;
lives-ok {$aural-class = (require ::("Test::CSS::Aural::Grammar"))}, 'grammar composition - lives';
isa-ok $aural-class, CSS::Grammar::CSS21;

my $actions;
lives-ok {$actions = (require ::("Test::CSS::Aural::Actions")).new}, 'class composition - lives';
ok $actions.defined, '::("Test::CSS::Aural::Actions").new';

for ('.aural-test { stress: 42; speech-rate: fast; volume: inherit; voice-family: female; }' =>
     ast => :stylesheet[
                     :ruleset{
                         :selectors[ :selector[ :simple-selector[ :class<aural-test> ] ] ],
                         :declarations[
                                  :property{ :ident<stress>, :expr[ :num(42) ] },
                                  :property{ :ident<speech-rate>, :expr[ :keyw<fast> ] },
                                  :property{ :ident<volume>, :expr[ :keyw<inherit> ] },
                                  :property{ :ident<voice-family>, :expr[ :keyw<female> ] },
                              ],
                     }
                 ],
     '.boxed-test { border-color: #aaa }' =>
     ast => :stylesheet[
                    :ruleset{
                        :selectors[ :selector[ :simple-selector[ :class<boxed-test> ] ]],
                        :declarations[ :property{
                            :ident<border-color>,
                            :expr[ :rgb[ :num(170), :num(170), :num(170) ]]}],
                    }
                  ],
     ) {
    my ($input, $expected) = .kv;

    &CSS::Grammar::Test::parse-tests($aural-class, $input, 
                                     :$actions, :$expected);
}
done-testing;
