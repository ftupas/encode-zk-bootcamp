%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_le,
    uint256_unsigned_div_rem,
    uint256_sub,
    uint256_eq,
)
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import unsigned_div_rem, assert_le_felt
from starkware.cairo.common.math import (
    assert_not_zero,
    assert_not_equal,
    assert_nn,
    assert_le,
    assert_lt,
    assert_in_range,
)
from homework_6.contracts.erc20.ERC20_base import (
    ERC20_name,
    ERC20_symbol,
    ERC20_totalSupply,
    ERC20_decimals,
    ERC20_balanceOf,
    ERC20_allowance,
    ERC20_mint,
    ERC20_initializer,
    ERC20_transfer,
    ERC20_burn,
)

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt, symbol: felt, initial_supply: Uint256, recipient: felt
) {
    ERC20_initializer(name, symbol, initial_supply, recipient);
    admin.write(recipient);
    return ();
}

// Storage
//#########################################################################################

@storage_var
func admin() -> (admin_address: felt) {
}

@storage_var
func requested_from_faucet(address: felt) -> (amount: Uint256) {
}

@storage_var
func whitelist(address: felt) -> (is_whitelisted: felt) {
}

// View functions
//#########################################################################################

@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
    let (name) = ERC20_name();
    return (name,);
}

@view
func get_admin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    admin_address: felt
) {
    let (admin_address) = admin.read();
    return (admin_address,);
}
@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (symbol: felt) {
    let (symbol) = ERC20_symbol();
    return (symbol,);
}

@view
func totalSupply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    totalSupply: Uint256
) {
    let (totalSupply: Uint256) = ERC20_totalSupply();
    return (totalSupply,);
}

@view
func decimals{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    decimals: felt
) {
    let (decimals) = ERC20_decimals();
    return (decimals,);
}

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) -> (
    balance: Uint256
) {
    let (balance: Uint256) = ERC20_balanceOf(account);
    return (balance,);
}

@view
func allowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, spender: felt
) -> (remaining: Uint256) {
    let (remaining: Uint256) = ERC20_allowance(owner, spender);
    return (remaining,);
}

// Externals
//###############################################################################################

@external
func transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    recipient: felt, amount: Uint256
) -> (success: felt) {
    // Check if amount is even
    let (q: Uint256, r: Uint256) = uint256_unsigned_div_rem(amount, Uint256(2,0));
    with_attr error_message("Transfer amount must be even") {
        let (is_eq) = uint256_eq(r, Uint256(0,0));
        assert is_eq = TRUE;
    }
    ERC20_transfer(recipient, amount);
    return (1,);
}

@external
func faucet{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(amount: Uint256) -> (
    success: felt
) {
    // Get caller address
    let (caller) = get_caller_address();

    // Get historical requested amount from faucet
    let (requested_amount: Uint256) = requested_from_faucet.read(caller);

    // Compute remaining request balance
    let balance: Uint256 = uint256_sub(Uint256(10000, 0), requested_amount);

    // Check request amount is <= balance
    with_attr error_message("Exceed allowed request limit") {
        let (is_le) = uint256_le(amount, balance);
        assert is_le = TRUE;
    }

    // Mint and increment requested amount
    ERC20_mint(caller, amount);
    requested_from_faucet.write(caller, amount);
    return (1,);
}

@external
func burn{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(amount: Uint256) -> (
    success: felt
) {
    alloc_locals;
    // Get caller address
    let (caller) = get_caller_address();

    // Calculate haircut amount and transfer to admin
    let (amount_haircut: Uint256, _) = uint256_unsigned_div_rem(amount, Uint256(10,0));
    let (admin) = get_admin();
    ERC20_transfer(admin, amount_haircut);

    // Calculate amount to burn and burn
    let (amount_burn: Uint256) = uint256_sub(amount, amount_haircut);
    ERC20_burn(caller, amount_burn);

    return (1,);
}

@external
func request_whitelist{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    level_granted: felt
) {
    // Get caller address
    let (caller) = get_caller_address();

    // Set whitelist
    whitelist.write(caller, TRUE);
    return (level_granted=1);
}

@external
func check_whitelist{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt
) -> (allowed_v: felt) {
    let (is_whitelisted) = whitelist.read(account);
    return (allowed_v=is_whitelisted);
}

@external
func exclusive_faucet{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    amount: Uint256
) -> (success: felt) {
    // Get caller address
    let (caller) = get_caller_address();

    // Check if whitelisted
    let (allowed) = check_whitelist(caller);
    with_attr error_message("Not whitelisted") {
        assert allowed = TRUE;
    }

    // Mint amount to caller
    ERC20_mint(caller, amount);
    return (success=1);
}
