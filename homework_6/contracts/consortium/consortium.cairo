%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp, storage_write
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le, is_not_zero, is_nn
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.registers import get_label_location

// Constants
const TRUE                  = 1;
const FALSE                 = 0;
const MAX_LEN               = 31;
const KEY_PROPOSALS_TITLE   = 0x113bf765313ec200520145b9cb555854db78eea68ef285fd588822b34e2ae56;
const KEY_PROPOSALS_LINK    = 0xfc275758ae4511b59c92331aa9375e6229e82679d82fe5ec2720ca15af3cff;
const KEY_PROPOSALS_ANSWERS = 0x3da0f9f36ecd9250efb7680bf1547f891cf94e7a434bafb8441bbb45440a49b;


// Structs
//#########################################################################################

struct Consortium {
    chairperson: felt,
    proposal_count: felt,
}

struct Member {
    votes: felt,
    prop: felt,
    ans: felt,
}

struct Answer {
    text: felt,
    votes: felt,
}

struct Proposal {
    type: felt,  // whether new answers can be added
    win_idx: felt,  // index of preffered option
    ans_idx: felt,
    deadline: felt,
    over: felt,
}

// remove in the final asnwerless
struct Winner {
    highest: felt,
    idx: felt,
}

// Storage
//#########################################################################################

@storage_var
func consortium_idx() -> (idx: felt) {
}

@storage_var
func consortiums(consortium_idx: felt) -> (consortium: Consortium) {
}

@storage_var
func members(consortium_idx: felt, member_addr: felt) -> (memb: Member) {
}

@storage_var
func proposals(consortium_idx: felt, proposal_idx: felt) -> (proposal: Proposal) {
}

@storage_var
func proposals_idx(consortium_idx: felt) -> (idx: felt) {
}

@storage_var
func proposals_title(consortium_idx: felt, proposal_idx: felt, string_idx: felt) -> (
    substring: felt
) {
}

@storage_var
func proposals_link(consortium_idx: felt, proposal_idx: felt, string_idx: felt) -> (
    substring: felt
) {
}

@storage_var
func proposals_answers(consortium_idx: felt, proposal_idx: felt, answer_idx: felt) -> (
    answers: Answer
) {
}

@storage_var
func voted(consortium_idx: felt, proposal_idx: felt, member_addr: felt) -> (true: felt) {
}

@storage_var
func answered(consortium_idx: felt, proposal_idx: felt, member_addr: felt) -> (true: felt) {
}

// External functions
//#########################################################################################

@external
func create_consortium{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    // Get caller address and make them the chairperson for the consortium
    let (caller: felt) = get_caller_address();
    tempvar consortium: Consortium* = new Consortium(
        chairperson=caller,
        proposal_count=0,
    );
    let (consortium_idx_: felt) = consortium_idx.read();

    // Write consortium to storage and increment count
    consortiums.write(
        consortium_idx=consortium_idx_,
        value=[consortium],
    );
    consortium_idx.write(value=consortium_idx_+1);

    // Create member and write to storage
    tempvar member: Member* = new Member(
        votes=100,
        prop=1,
        ans=1,
    );
    members.write(
        consortium_idx=consortium_idx_,
        member_addr=caller,
        value=[member],
    );

    return ();
}

@external
func add_proposal{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    consortium_idx: felt,
    title_len: felt,
    title: felt*,
    link_len: felt,
    link: felt*,
    ans_len: felt,
    ans: felt*,
    type: felt,
    deadline: felt,
) {
    alloc_locals;
    // Get caller address and assert it is a member with right to add proposals
    let (caller: felt) = get_caller_address();
    let (consortium: Consortium) = consortiums.read(consortium_idx=consortium_idx);
    let (member: Member) = members.read(
        consortium_idx=consortium_idx,
        member_addr=caller,
    );
    with_attr error_message("Only members with right rights can add proposals") {
        assert TRUE = member.prop;
    }

    // Add proposal to storage and increment count
    let (local proposal_idx_: felt) = proposals_idx.read(consortium_idx=consortium_idx);
    let proposal: Proposal = Proposal(
        type=type,
        win_idx=0,
        ans_idx=ans_len,
        deadline=deadline,
        over=FALSE,
    );
    proposals.write(
        consortium_idx=consortium_idx,
        proposal_idx=proposal_idx_,
        value=proposal
    );
    proposals_idx.write(
        consortium_idx=consortium_idx,
        value=proposal_idx_+1
    );

    // Write proposal title, link, and answers
    load_selector(
        string_len=title_len,
        string=title,
        slot_idx=0,
        proposal_idx=proposal_idx_,
        consortium_idx=consortium_idx,
        selector=KEY_PROPOSALS_TITLE,
        offset=MAX_LEN
    );

    load_selector(
        string_len=link_len,
        string=link,
        slot_idx=0,
        proposal_idx=proposal_idx_,
        consortium_idx=consortium_idx,
        selector=KEY_PROPOSALS_LINK,
        offset=MAX_LEN
    );

    load_selector(
        string_len=ans_len,
        string=ans,
        slot_idx=0,
        proposal_idx=proposal_idx_,
        consortium_idx=consortium_idx,
        selector=KEY_PROPOSALS_ANSWERS,
        offset=1
    );

    return ();
}

@external
func add_member{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    consortium_idx: felt, member_addr: felt, prop: felt, ans: felt, votes: felt
) {
    // Get caller address and assert it is the chairperson of the consortium
    let (caller: felt) = get_caller_address();
    let (consortium: Consortium) = consortiums.read(consortium_idx=consortium_idx);
    with_attr error_message("Only Chairperson can add new member") {
        assert caller = consortium.chairperson;
    }

    // Add new member
    let member: Member = Member(
        votes=votes,
        prop=prop,
        ans=ans,
    );
    members.write(
        consortium_idx=consortium_idx,
        member_addr=member_addr,
        value=member,
    );

    return ();
}

@external
func add_answer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    consortium_idx: felt, proposal_idx: felt, string_len: felt, string: felt*
) {
    alloc_locals;
    // Check if caller is a permitted member
    let (local caller: felt) = get_caller_address();
    let (member: Member) = members.read(
        consortium_idx=consortium_idx,
        member_addr=caller,
    );
    with_attr error_message("Member must be permitted to add answer") {
        assert member.ans = TRUE;
    }

    // Check if proposal allows additions
    let (proposal: Proposal) = proposals.read(
        consortium_idx=consortium_idx,
        proposal_idx=proposal_idx
    );
    with_attr error_message("Proposal has to allow additions of answers") {
        assert proposal.type = 1;
    }

    // One answer can only be added per member
    let (answered_: felt) = answered.read(
        consortium_idx=consortium_idx,
        proposal_idx=proposal_idx,
        member_addr=caller
    );
    with_attr error_message("Exceeded number of allowed answer additions") {
        assert answered_ = FALSE;
    }

    // Add answer and record  by member
    load_selector(
        string_len=string_len,
        string=string,
        slot_idx=proposal.ans_idx,
        proposal_idx=proposal_idx,
        consortium_idx=consortium_idx,
        selector=KEY_PROPOSALS_ANSWERS,
        offset=1
    );
    answered.write(
        consortium_idx=consortium_idx,
        proposal_idx=proposal_idx,
        member_addr=caller,
        value=TRUE
    );

    // Update proposal record
    tempvar new_proposal: Proposal* = new Proposal(
        type=proposal.type,
        win_idx=proposal.win_idx,
        ans_idx=proposal.ans_idx+1,
        deadline=proposal.deadline,
        over=proposal.over,
    );
    proposals.write(
        consortium_idx=consortium_idx,
        proposal_idx=proposal_idx,
        value=[new_proposal],
    );

    return ();
}

@external
func vote_answer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    consortium_idx: felt, proposal_idx: felt, answer_idx: felt
) {
    // Check if caller voted already
    let (caller: felt) = get_caller_address();
    let (voted_: felt) = voted.read(
        consortium_idx=consortium_idx,
        proposal_idx=proposal_idx,
        member_addr=caller
    );
    with_attr error_message("Exceeded number of allowed votes") {
        assert voted_ = FALSE;
    }

    // Record votes accordingly depending on Member.votes
    let (member: Member) = members.read(
        consortium_idx=consortium_idx,
        member_addr=caller,
    );

    let (answer: Answer) = proposals_answers.read(
        consortium_idx=consortium_idx,
        proposal_idx=proposal_idx,
        answer_idx=answer_idx,
    );
    let new_answer: Answer = Answer(
        text=answer.text,
        votes=answer.votes+member.votes,
    );

    proposals_answers.write(
        consortium_idx=consortium_idx,
        proposal_idx=proposal_idx,
        answer_idx=answer_idx,
        value=new_answer
    );

    // Increment voting
    voted.write(
        consortium_idx=consortium_idx,
        proposal_idx=proposal_idx,
        member_addr=caller,
        value=TRUE
    );

    return ();
}

@external
func tally{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    consortium_idx: felt, proposal_idx: felt
) -> (win_idx: felt) {

    let (proposal: Proposal) = proposals.read(
        consortium_idx=consortium_idx,
        proposal_idx=proposal_idx
    );

    // If before deadline, only Chairperson can call this
    let (caller: felt) = get_caller_address();
    let (consortium: Consortium) = consortiums.read(consortium_idx=consortium_idx);
    let (current_timesamp: felt) = get_block_timestamp();
    let is_before_deadline: felt = is_le(current_timesamp, proposal.deadline);

    if (is_before_deadline == TRUE) {
        with_attr error_message("Only Chairperson can tally before deadline has passed") {
            assert caller = consortium.chairperson;
        }
    }

    let (winner_idx: felt) = find_highest(
        consortium_idx=consortium_idx,
        proposal_idx=proposal_idx,
        highest=0,
        idx=0,
        countdown=proposal.ans_idx,
    );
    return (winner_idx,);
}


// Internal functions
//#########################################################################################


func find_highest{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    consortium_idx: felt, proposal_idx: felt, highest: felt, idx: felt, countdown: felt
) -> (idx: felt) {

    if (countdown == 0) {
        return (highest,);
    }

    // Compare the votes of the two Answers by index
    let (answer_1: Answer) = proposals_answers.read(
        consortium_idx=consortium_idx,
        proposal_idx=proposal_idx,
        answer_idx=highest,
    );

    let (answer_2: Answer) = proposals_answers.read(
        consortium_idx=consortium_idx,
        proposal_idx=proposal_idx,
        answer_idx=idx,
    );

    // If votes for answer_1 is less than answer_2, highest = current idx
    let is_1_le_2: felt = is_le(answer_1.votes, answer_2.votes);
    if (is_1_le_2 == TRUE) {
        tempvar highest = idx;
    } else {
        tempvar highest = highest;
    }
    return find_highest(
        consortium_idx=consortium_idx,
        proposal_idx=proposal_idx,
        highest=highest,
        idx=idx+1,
        countdown=countdown-1,
    );
}

// Loads it based on length, internall calls only
func load_selector{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    string_len: felt,
    string: felt*,
    slot_idx: felt,
    proposal_idx: felt,
    consortium_idx: felt,
    selector: felt,
    offset: felt,
) {

    let (q: felt, r: felt) = unsigned_div_rem(string_len, offset);
    let r_is_not_zero: felt = is_not_zero(r);

    if (q == 0 and r == 0) {
        return ();
    }

    let (hash_1: felt) = hash2{hash_ptr=pedersen_ptr}(selector, consortium_idx);
    let (hash_2: felt) = hash2{hash_ptr=pedersen_ptr}(hash_1, proposal_idx);
    let (key: felt) = hash2{hash_ptr=pedersen_ptr}(hash_2, slot_idx);

    storage_write(
        address=key,
        value=[string]
    );

    // If there's remainder, offset becomes r
    if (r_is_not_zero == TRUE) {
        tempvar offset = r;
    } else {
        tempvar offset = offset;
    }

    load_selector(
        string_len=string_len-offset,
        string=string+offset,
        slot_idx=slot_idx+1,
        proposal_idx=proposal_idx,
        consortium_idx=consortium_idx,
        selector=selector,
        offset=offset
    );

    return ();
}
