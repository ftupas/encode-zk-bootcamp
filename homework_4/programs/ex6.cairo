from starkware.cairo.common.bitwise import bitwise_and, bitwise_xor
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin

// Implement a function that sums even numbers from the provided array
func sum_even{bitwise_ptr: BitwiseBuiltin*}(arr_len: felt, arr: felt*, run: felt, idx: felt) -> (
    sum: felt
) {
    alloc_locals;
    if (arr_len == run) {
        return (sum=0);
    }

    let value = arr[idx];
    let (local mod_2 : felt) = bitwise_and(value, 1);
    let (sum) = sum_even(arr_len, arr, run+1, idx+1);
    if (mod_2 == 0) {
        return (sum=sum+arr[idx]);
    }

    return (sum=sum);
}
