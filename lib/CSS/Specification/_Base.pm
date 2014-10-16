use v6;

grammar CSS::Specification::_Base {

    proto rule proforma {*}

    token val( $*EXPR, $doc='', $boxed=False ) {
        [$<boxed>=<?{$boxed}>]? [ <proforma> || <rx={$*EXPR}>|| <usage($doc)> ]
    }

    token seen($opt) {
        <?{@*SEEN[$opt]++}>
    }

    token usage($doc) {
        :my $*USAGE;
        <any-args> {$*USAGE = ~$doc}
    }

}
