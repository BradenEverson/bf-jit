//! Preprocessor for collapsing repeated tokens

const OpKind = enum {
    inc,
    dec,
    left,
    right,
    while_start,
    while_end,
    print,
    read,
};
