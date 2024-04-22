unit module CSS::Specification::Compiler::RakuAST;

use experimental :rakuast;

our proto sub compile (|c) is export(:compile) {
    {*}
}

multi sub compile(:@props!, :$default, :$spec, Str :$synopsis) {
    die "todo: {@props}" unless @props == 1;
    my $prop = @props.head;
    my $name = id($prop);
    my RakuAST::Regex $body = compile($spec);
    $body = RakuAST::Regex::Sequence.new(
        RakuAST::Regex::InternalModifier::IgnoreCase.new(
            modifier => "i"
        ),
        RakuAST::Regex::WithWhitespace.new($body),
    );

    my Str $leading = $_ ~ "\n" with $synopsis;

    RakuAST::StatementList.new(
        RakuAST::Statement::Expression.new(
            expression =>
            RakuAST::RuleDeclaration.new(
                :$name,
                :$body,
            ).declarator-docs(
                :$leading
            )
        )
    );
}

multi sub compile(:@occurs! ($quant!, *%term)) {
    my RakuAST::Regex $atom = compile(|%term);
    my RakuAST::Regex $separator = compile(:op<,>)
        if $quant.tail ~~ ',';

    my RakuAST::Regex::Quantifier $quantifier = do given $quant {
        when '?' {
            RakuAST::Regex::Quantifier::ZeroOrOne.new
        }
        when '*' {
            RakuAST::Regex::Quantifier::ZeroOrMore.new
        }
        when '+'|',' {
            RakuAST::Regex::Quantifier::OneOrMore.new
        }
        when Array {
            my $min  = .[0];
            my $max  = .[1];
            RakuAST::Regex::Quantifier::Range.new: :$min, :$max;
        }
        default { die "unknown quant: $quant" }
    }
    RakuAST::Regex::QuantifiedAtom.new: :$atom, :$quantifier, :$separator;
}

sub id(Str:D $id) is export {  RakuAST::Name.from-identifier($id) }

sub look-ahead(RakuAST::Regex::Assertion $assertion, Bool :$negated = False, Bool :$capturing = False) is export {
    RakuAST::Regex::Assertion::Lookahead.new(
        :$assertion, :$negated
    );
}

proto sub assertions(|) is export {*}
multi sub assertion(Str:D $id, Bool :$capturing = True, RakuAST::ArgList :$args!) {
    my $name := $id.&id;
    RakuAST::Regex::Assertion::Named::Args.new(
        :$name, :$capturing, :$args,
    );
}

multi sub assertion(Str:D $id, Bool :$capturing = True) {
    my $name := $id.&id;
    RakuAST::Regex::Assertion::Named.new(
        :$name, :$capturing,
    );
}

proto sub arg(|) is export {*}
multi sub arg(Str:D $arg) {
    RakuAST::ArgList.new: RakuAST::StrLiteral.new($arg);
}

multi sub arg(Int:D $arg) {
    RakuAST::ArgList.new: RakuAST::IntLiteral.new($arg);
}

sub ws(RakuAST::Regex $r) is export { RakuAST::Regex::WithWhitespace.new($r) }

sub lit(Str:D $s) is export { RakuAST::Regex::Literal.new($s) }

sub group(RakuAST::Regex $r) is export  { RakuAST::Regex::Group.new: $r }

sub alt(@choices) is export {
    RakuAST::Regex::Alternation.new: |@choices;
}

sub seq(@seq) is export  { RakuAST::Regex::Sequence.new: |@seq }

sub conjunct(RakuAST::Regex $r1, RakuAST::Regex $r2) is export {
    RakuAST::Regex::Conjunction.new($r1, $r2).&group;
}

sub literal(Str:D() $_) is export { .&lit.&ws }

sub lexical(Str:D $sym) is export {
    RakuAST::Var::Lexical.new($sym)
}

sub param(Str:D $name) is export {
    RakuAST::Parameter.new(
        target => RakuAST::ParameterTarget::Var.new(:$name)
    )
}

sub array-index($expression) is export {
    RakuAST::Postcircumfix::ArrayIndex.new(
        index => RakuAST::SemiList.new(
            RakuAST::Statement::Expression.new(
                :$expression
            )
        )
    )
}

sub call(Str:D $id, :@args) is export {
    my $name = $id.&id;
    my %etc;
    %etc<args> = RakuAST::ArgList.new(|@args)
        if @args;
    RakuAST::Call::Method.new: :$name, |%etc;
}

sub seen(Int:D $id) is export {
    my $postfix = $id.&arg.&array-index;
    my $operand = '@S'.&lexical;
    my RakuAST::Block $block .= new(
        body => RakuAST::Blockoid.new(
            RakuAST::StatementList.new(
                RakuAST::Statement::Expression.new(
                    expression => RakuAST::ApplyPostfix.new(
                        operand => RakuAST::ApplyPostfix.new(
                            :$operand, :$postfix
                        ),
                        postfix => RakuAST::Postfix.new(operator => "++")
                    )
                )
            )
        )
    );
    RakuAST::Regex::Assertion::PredicateBlock.new(
        :$block, :negated,
    )
 }

multi sub compile(Str:D :$keyw!) {
    conjunct $keyw.&lit, 'keyw'.&assertion;
}

multi sub compile(Str:D() :$num!) {
    conjunct $num.&lit, 'number'.&assertion;
}

sub _choice(@lits, RakuAST::Regex $term2) {
    my $term1 = @lits == 1 ?? @lits[0] !! @lits.&alt.&group;
    conjunct($term1, $term2);
}

multi sub compile(Str:D :$rule) {
    $rule.&assertion;
}

multi sub compile(:@keywords!) {
    _choice @keywords.map(&literal), 'keyw'.&assertion;
}

multi sub compile(:@numbers!) {
    _choice @numbers.map(&literal), 'number'.&assertion;
}

multi sub compile(Str:D :$op!) {
    my $args = ','.&arg;
    'op'.&assertion(:$args);
}

multi sub compile(:@alt!)   { alt @alt.map(&compile).map(&ws) }
multi sub compile(:@seq!)   { seq @seq.map(&compile).map(&ws) }
multi sub compile(:$group!) { group compile($group) }

my constant Seen-Decl = RakuAST::Regex::Statement.new(
    RakuAST::Statement::Expression.new(
        expression => RakuAST::VarDeclaration::Simple.new(
            sigil       => "\@",
            desigilname => RakuAST::Name.from-identifier("S")
        )
    )
);

multi sub compile(:required(@combo)!) {
    compile(:@combo, :required);
}

multi sub compile(:@combo!, Bool :$required) {
    my $id = 0;
    my $atom = alt @combo.map: {
        my $seen = seen($id++);
        my $term = compile($_);
        [$term, $seen].&seq;
    }
    $atom = [Seen-Decl, $atom].&seq.&group;
    my RakuAST::Regex::Quantifier $quantifier = $required
        ?? RakuAST::Regex::Quantifier::Range.new: :min($id), :max($id)
        !! RakuAST::Regex::Quantifier::OneOrMore.new;

    RakuAST::Regex::QuantifiedAtom.new: :$atom, :$quantifier;
}

multi sub compile($arg) { compile |$arg }

