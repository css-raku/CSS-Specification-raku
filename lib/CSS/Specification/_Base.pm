use v6;

grammar CSS::Specification::_Base {

    proto rule proforma {*}

    token val( $*EXPR, $*USAGE='', $boxed=False ) {
        [$<boxed>=<?{$boxed}>]? [ <proforma> || <rx={$*EXPR}>|| <usage($*USAGE)> ]
    }

    token seen($opt) {
        <?{@*SEEN[$opt]++}>
    }

    token usage($*USAGE) {
        <any-args>
    }

}
