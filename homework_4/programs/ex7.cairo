%lang starknet
from starkware.cairo.common.bitwise import bitwise_and, bitwise_xor
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE

// Using binary operations return:
// - 1 when pattern of bits is 01010101 from LSB up to MSB 1, but accounts for trailing zeros
// - 0 otherwise

// 000000101010101 PASS
// 010101010101011 FAIL

func pattern{bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    n: felt, idx: felt, exp: felt, broken_chain: felt
) -> (true: felt) {
    alloc_locals;
    let (local arr_len: felt, local arr: felt*) = number_to_bits_array(n);
    let bool = is_nice(arr_len, arr);
    %{
        print(f"""
        NUMBER: {ids.n},
        BINARY: {[memory[ids.arr + i] for i in range(ids.arr_len)]}
        """)
    %}
    return (true=bool);
}

func number_to_bits_array{bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    n: felt
) -> (arr_len: felt, arr: felt*) {
    alloc_locals;
    let (q, r) = unsigned_div_rem(n, 2);
    if (q != 0) {
        let (arr_len, arr) = number_to_bits_array(q);
        assert arr[arr_len] = r;
        return (arr_len + 1, arr);
    } else {
        let arr: felt* = alloc();
        assert arr[0] = r;
        return (1, arr);
    }
}

func is_nice{range_check_ptr}(
    arr_len: felt, arr: felt*
) -> felt {
    // arr_len is 0 or 1
    if (arr_len * (arr_len - 1) == 0) {
        return (TRUE);
    }

    if (arr[0] + arr[1] != 1) {
        return (FALSE);
    }

    return is_nice(arr_len - 1, arr + 1);
}
