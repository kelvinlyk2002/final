{
    { }
    function abi_decode_tuple_t_bytes4(headStart, dataEnd) -> value0
    {
        if slt(sub(dataEnd, headStart), 32) { revert(0, 0) }
        let value := calldataload(headStart)
        if iszero(eq(value, and(value, shl(224, 0xffffffff)))) { revert(0, 0) }
        value0 := value
    }
    function abi_encode_tuple_t_bool__to_t_bool__fromStack_reversed(headStart, value0) -> tail
    {
        tail := add(headStart, 32)
        mstore(headStart, iszero(iszero(value0)))
    }
    function abi_decode_tuple_t_uint256(headStart, dataEnd) -> value0
    {
        if slt(sub(dataEnd, headStart), 32) { revert(0, 0) }
        value0 := calldataload(headStart)
    }
    function abi_encode_tuple_t_contract$_IERC20_$3592__to_t_address__fromStack_reversed(headStart, value0) -> tail
    {
        tail := add(headStart, 32)
        mstore(headStart, and(value0, sub(shl(160, 1), 1)))
    }
    function abi_encode_tuple_t_uint256__to_t_uint256__fromStack_reversed(headStart, value0) -> tail
    {
        tail := add(headStart, 32)
        mstore(headStart, value0)
    }
    function validator_revert_address(value)
    {
        if iszero(eq(value, and(value, sub(shl(160, 1), 1)))) { revert(0, 0) }
    }
    function abi_decode_tuple_t_addresst_contract$_IERC20_$3592(headStart, dataEnd) -> value0, value1
    {
        if slt(sub(dataEnd, headStart), 64) { revert(0, 0) }
        let value := calldataload(headStart)
        validator_revert_address(value)
        value0 := value
        let value_1 := calldataload(add(headStart, 32))
        validator_revert_address(value_1)
        value1 := value_1
    }
    function abi_decode_uint8(offset) -> value
    {
        value := calldataload(offset)
        if iszero(eq(value, and(value, 0xff))) { revert(0, 0) }
    }
    function abi_decode_tuple_t_uint8t_contract$_IERC20_$3592t_uint8t_uint256(headStart, dataEnd) -> value0, value1, value2, value3
    {
        if slt(sub(dataEnd, headStart), 128) { revert(0, 0) }
        value0 := abi_decode_uint8(headStart)
        let value := calldataload(add(headStart, 32))
        validator_revert_address(value)
        value1 := value
        value2 := abi_decode_uint8(add(headStart, 64))
        value3 := calldataload(add(headStart, 96))
    }
    function abi_decode_tuple_t_uint8(headStart, dataEnd) -> value0
    {
        if slt(sub(dataEnd, headStart), 32) { revert(0, 0) }
        value0 := abi_decode_uint8(headStart)
    }
    function panic_error_0x21()
    {
        mstore(0, shl(224, 0x4e487b71))
        mstore(4, 0x21)
        revert(0, 0x24)
    }
    function abi_encode_tuple_t_enum$_Proposal_$951__to_t_uint8__fromStack_reversed(headStart, value0) -> tail
    {
        tail := add(headStart, 32)
        if iszero(lt(value0, 4))
        {
            mstore(0, shl(224, 0x4e487b71))
            mstore(4, 0x21)
            revert(0, 0x24)
        }
        mstore(headStart, value0)
    }
    function abi_decode_tuple_t_contract$_IERC20_$3592t_uint256(headStart, dataEnd) -> value0, value1
    {
        if slt(sub(dataEnd, headStart), 64) { revert(0, 0) }
        let value := calldataload(headStart)
        validator_revert_address(value)
        value0 := value
        value1 := calldataload(add(headStart, 32))
    }
    function abi_decode_tuple_t_uint256t_uint256(headStart, dataEnd) -> value0, value1
    {
        if slt(sub(dataEnd, headStart), 64) { revert(0, 0) }
        value0 := calldataload(headStart)
        value1 := calldataload(add(headStart, 32))
    }
    function panic_error_0x41()
    {
        mstore(0, shl(224, 0x4e487b71))
        mstore(4, 0x41)
        revert(0, 0x24)
    }
    function allocate_memory(size) -> memPtr
    {
        memPtr := mload(64)
        let newFreePtr := add(memPtr, and(add(size, 31), not(31)))
        if or(gt(newFreePtr, 0xffffffffffffffff), lt(newFreePtr, memPtr)) { panic_error_0x41() }
        mstore(64, newFreePtr)
    }
    function abi_decode_array_uint256_dyn(offset, end) -> array
    {
        if iszero(slt(add(offset, 0x1f), end)) { revert(0, 0) }
        let _1 := calldataload(offset)
        let _2 := 0x20
        if gt(_1, 0xffffffffffffffff) { panic_error_0x41() }
        let _3 := shl(5, _1)
        let dst := allocate_memory(add(_3, _2))
        let dst_1 := dst
        mstore(dst, _1)
        dst := add(dst, _2)
        let srcEnd := add(add(offset, _3), _2)
        if gt(srcEnd, end) { revert(0, 0) }
        let src := add(offset, _2)
        for { } lt(src, srcEnd) { src := add(src, _2) }
        {
            mstore(dst, calldataload(src))
            dst := add(dst, _2)
        }
        array := dst_1
    }
    function abi_decode_bytes(offset, end) -> array
    {
        if iszero(slt(add(offset, 0x1f), end)) { revert(0, 0) }
        let _1 := calldataload(offset)
        if gt(_1, 0xffffffffffffffff) { panic_error_0x41() }
        let array_1 := allocate_memory(add(and(add(_1, 0x1f), not(31)), 0x20))
        mstore(array_1, _1)
        if gt(add(add(offset, _1), 0x20), end) { revert(0, 0) }
        calldatacopy(add(array_1, 0x20), add(offset, 0x20), _1)
        mstore(add(add(array_1, _1), 0x20), 0)
        array := array_1
    }
    function abi_decode_tuple_t_addresst_addresst_array$_t_uint256_$dyn_memory_ptrt_array$_t_uint256_$dyn_memory_ptrt_bytes_memory_ptr(headStart, dataEnd) -> value0, value1, value2, value3, value4
    {
        if slt(sub(dataEnd, headStart), 160) { revert(0, 0) }
        let value := calldataload(headStart)
        validator_revert_address(value)
        value0 := value
        let value_1 := calldataload(add(headStart, 32))
        validator_revert_address(value_1)
        value1 := value_1
        let offset := calldataload(add(headStart, 64))
        let _1 := 0xffffffffffffffff
        if gt(offset, _1) { revert(0, 0) }
        value2 := abi_decode_array_uint256_dyn(add(headStart, offset), dataEnd)
        let offset_1 := calldataload(add(headStart, 96))
        if gt(offset_1, _1) { revert(0, 0) }
        value3 := abi_decode_array_uint256_dyn(add(headStart, offset_1), dataEnd)
        let offset_2 := calldataload(add(headStart, 128))
        if gt(offset_2, _1) { revert(0, 0) }
        value4 := abi_decode_bytes(add(headStart, offset_2), dataEnd)
    }
    function abi_encode_tuple_t_bytes4__to_t_bytes4__fromStack_reversed(headStart, value0) -> tail
    {
        tail := add(headStart, 32)
        mstore(headStart, and(value0, shl(224, 0xffffffff)))
    }
    function validator_revert_bool(value)
    {
        if iszero(eq(value, iszero(iszero(value)))) { revert(0, 0) }
    }
    function abi_decode_tuple_t_uint256t_bool(headStart, dataEnd) -> value0, value1
    {
        if slt(sub(dataEnd, headStart), 64) { revert(0, 0) }
        value0 := calldataload(headStart)
        let value := calldataload(add(headStart, 32))
        validator_revert_bool(value)
        value1 := value
    }
    function abi_decode_tuple_t_contract$_IERC20_$3592(headStart, dataEnd) -> value0
    {
        if slt(sub(dataEnd, headStart), 32) { revert(0, 0) }
        let value := calldataload(headStart)
        validator_revert_address(value)
        value0 := value
    }
    function abi_decode_tuple_t_addresst_addresst_uint256t_uint256t_bytes_memory_ptr(headStart, dataEnd) -> value0, value1, value2, value3, value4
    {
        if slt(sub(dataEnd, headStart), 160) { revert(0, 0) }
        let value := calldataload(headStart)
        validator_revert_address(value)
        value0 := value
        let value_1 := calldataload(add(headStart, 32))
        validator_revert_address(value_1)
        value1 := value_1
        value2 := calldataload(add(headStart, 64))
        value3 := calldataload(add(headStart, 96))
        let offset := calldataload(add(headStart, 128))
        if gt(offset, 0xffffffffffffffff) { revert(0, 0) }
        value4 := abi_decode_bytes(add(headStart, offset), dataEnd)
    }
    function abi_decode_tuple_t_bool_fromMemory(headStart, dataEnd) -> value0
    {
        if slt(sub(dataEnd, headStart), 32) { revert(0, 0) }
        let value := mload(headStart)
        validator_revert_bool(value)
        value0 := value
    }
    function abi_encode_tuple_t_stringliteral_be63b6e370b641d29f88c43ec6881fb4f1eff3f1055e507b482f4920ca492ca6__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 36)
        mstore(add(headStart, 64), "Withdrawn project cannot be acti")
        mstore(add(headStart, 96), "oned")
        tail := add(headStart, 128)
    }
    function abi_encode_tuple_t_stringliteral_680af0424162ea7747c5b293fd6e59912d1a62a34c782ded5af14cb8702758dd__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 25)
        mstore(add(headStart, 64), "Quorum will never be met.")
        tail := add(headStart, 96)
    }
    function abi_encode_tuple_t_stringliteral_c49c9cfb2e2f63b55753aae0bec9309f6fbe5ffe5aa7cdd4852ee6ba1b2ae889__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 30)
        mstore(add(headStart, 64), "Quorum should be at least 25%.")
        tail := add(headStart, 96)
    }
    function panic_error_0x11()
    {
        mstore(0, shl(224, 0x4e487b71))
        mstore(4, 0x11)
        revert(0, 0x24)
    }
    function checked_add_t_uint256(x, y) -> sum
    {
        if gt(x, not(y)) { panic_error_0x11() }
        sum := add(x, y)
    }
    function abi_encode_tuple_t_stringliteral_92fcc5eb2c23b0a980496314ad76d71e35f247f6301b0331db508a2a8dd9895d__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 45)
        mstore(add(headStart, 64), "Deadline must be after votingPer")
        mstore(add(headStart, 96), "iod from now.")
        tail := add(headStart, 128)
    }
    function abi_encode_tuple_t_stringliteral_237428d4f5d82938688afa0e07ef4d430a38e2a93508b2be13e416169c736772__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 55)
        mstore(add(headStart, 64), "Deadline must be after withdrawa")
        mstore(add(headStart, 96), "lVotingPeriod from now.")
        tail := add(headStart, 128)
    }
    function increment_t_uint256(value) -> ret
    {
        if eq(value, not(0)) { panic_error_0x11() }
        ret := add(value, 1)
    }
    function abi_encode_tuple_t_stringliteral_c9580fd05844cb84bf0a747c48ec42a21f1dca0bc044d3619707fb319eddae0d__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 18)
        mstore(add(headStart, 64), "Index out of range")
        tail := add(headStart, 96)
    }
    function abi_decode_tuple_t_address_fromMemory(headStart, dataEnd) -> value0
    {
        if slt(sub(dataEnd, headStart), 32) { revert(0, 0) }
        let value := mload(headStart)
        validator_revert_address(value)
        value0 := value
    }
    function abi_encode_tuple_t_stringliteral_7d9603875acafb20becf58e0c0c27b83bb58be3ffd36ddbd1847013f5a75f1d3__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 18)
        mstore(add(headStart, 64), "project owner only")
        tail := add(headStart, 96)
    }
    function abi_encode_tuple_t_stringliteral_0f84189fdb7342e8822ce5f3735fffd6509c52a31ee9ff45e46201383278650b__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 25)
        mstore(add(headStart, 64), "Proposal already in place")
        tail := add(headStart, 96)
    }
    function abi_encode_tuple_t_address__to_t_address__fromStack_reversed(headStart, value0) -> tail
    {
        tail := add(headStart, 32)
        mstore(headStart, and(value0, sub(shl(160, 1), 1)))
    }
    function abi_decode_tuple_t_uint256_fromMemory(headStart, dataEnd) -> value0
    {
        if slt(sub(dataEnd, headStart), 32) { revert(0, 0) }
        value0 := mload(headStart)
    }
    function abi_encode_tuple_t_stringliteral_7cab488401d35bd34ecbac53270fbe1cc196f9eff16dc77b4abe83c007cd5c6a__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 42)
        mstore(add(headStart, 64), "Cannot approve more than current")
        mstore(add(headStart, 96), " ownership")
        tail := add(headStart, 128)
    }
    function panic_error_0x01()
    {
        mstore(0, shl(224, 0x4e487b71))
        mstore(4, 0x01)
        revert(0, 0x24)
    }
    function abi_encode_tuple_t_stringliteral_02a905d9571df3a5187f2d737fd1dd2de1441abb5e92f24e7e5c5379e73689b9__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 23)
        mstore(add(headStart, 64), "called by contract only")
        tail := add(headStart, 96)
    }
    function abi_encode_tuple_t_address_t_uint256__to_t_address_t_uint256__fromStack_reversed(headStart, value1, value0) -> tail
    {
        tail := add(headStart, 64)
        mstore(headStart, and(value0, sub(shl(160, 1), 1)))
        mstore(add(headStart, 32), value1)
    }
    function abi_encode_tuple_t_stringliteral_53793addd8a13e19b6587c9dbffc78dd71b668c5509ca843ae85c25bc7c7617e__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 11)
        mstore(add(headStart, 64), "Holder only")
        tail := add(headStart, 96)
    }
    function abi_encode_tuple_t_address_t_address_t_uint256_t_uint256_t_stringliteral_c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470__to_t_address_t_address_t_uint256_t_uint256_t_bytes_memory_ptr__fromStack_reversed(headStart, value3, value2, value1, value0) -> tail
    {
        let _1 := sub(shl(160, 1), 1)
        mstore(headStart, and(value0, _1))
        mstore(add(headStart, 32), and(value1, _1))
        mstore(add(headStart, 64), value2)
        mstore(add(headStart, 96), value3)
        mstore(add(headStart, 128), 160)
        mstore(add(headStart, 160), 0)
        tail := add(headStart, 192)
    }
    function abi_encode_tuple_t_stringliteral_a2d65bda670d6dd34eb756c8895604acb9c57fba4de0969881d4326f6b09e42a__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 11)
        mstore(add(headStart, 64), "Voter only.")
        tail := add(headStart, 96)
    }
    function abi_encode_tuple_t_stringliteral_404f6d93aebb17e3f582e99a961a401021bdc6bc8b3cca523b868a680ffa375b__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 18)
        mstore(add(headStart, 64), "Address had voted.")
        tail := add(headStart, 96)
    }
    function abi_encode_tuple_t_stringliteral_7092ff085b156b1040182d4d4b71e13cdae563daf42fbc141b520afd7a806c5c__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 25)
        mstore(add(headStart, 64), "Voting deadline has past.")
        tail := add(headStart, 96)
    }
    function abi_encode_tuple_t_stringliteral_a62f6da66d4db11deb4ec0410d354605ab6be8f0d384bdeabfa317ba382a476f__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 34)
        mstore(add(headStart, 64), "No proposal or allowance exhaust")
        mstore(add(headStart, 96), "ed")
        tail := add(headStart, 128)
    }
    function checked_sub_t_uint256(x, y) -> diff
    {
        if lt(x, y) { panic_error_0x11() }
        diff := sub(x, y)
    }
    function abi_encode_tuple_t_stringliteral_1cdddc2eb2a11593b17eb298d4e980736653e41c38c3561e507b11388db645a1__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 28)
        mstore(add(headStart, 64), "Voting period has not passed")
        tail := add(headStart, 96)
    }
    function abi_encode_tuple_t_stringliteral_1ba89bab6051a9c441f527f86c9cf063db3b5b260438eba979c3f878e8a17fdd__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 17)
        mstore(add(headStart, 64), "overauthorisation")
        tail := add(headStart, 96)
    }
    function abi_encode_tuple_t_stringliteral_fb19fbc601f016eaf175535b7c8112a7f2139ba269cade5cec8634b7a1342e30__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 36)
        mstore(add(headStart, 64), "Objection proposal is not execut")
        mstore(add(headStart, 96), "able")
        tail := add(headStart, 128)
    }
    function abi_encode_tuple_t_stringliteral_9fba5fb215e5085c909164c599eddf184c1eabdf8c971416fa67ed195ebfa9f5__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 28)
        mstore(add(headStart, 64), "Voting deadline hasn't past.")
        tail := add(headStart, 96)
    }
    function abi_encode_tuple_t_stringliteral_834b361c4b65469130223f0838b45b0625daf4aa2c3a9a0694b59ad2731abe57__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 16)
        mstore(add(headStart, 64), "Majority not met")
        tail := add(headStart, 96)
    }
    function checked_mul_t_uint256(x, y) -> product
    {
        if and(iszero(iszero(x)), gt(y, div(not(0), x))) { panic_error_0x11() }
        product := mul(x, y)
    }
    function checked_div_t_uint256(x, y) -> r
    {
        if iszero(y)
        {
            mstore(0, shl(224, 0x4e487b71))
            mstore(4, 0x12)
            revert(0, 0x24)
        }
        r := div(x, y)
    }
    function abi_encode_tuple_t_stringliteral_d78a5e09b43090ece9d7751a98669a1e713adf6c10539483e6aa8d373264b69f__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 14)
        mstore(add(headStart, 64), "Quorum not met")
        tail := add(headStart, 96)
    }
    function abi_encode_tuple_t_stringliteral_5015a21e61d3c0b2fb122535c0277418803b5d3ed94df9eca1ec63dd5b32f1db__to_t_string_memory_ptr__fromStack_reversed(headStart) -> tail
    {
        mstore(headStart, 32)
        mstore(add(headStart, 32), 22)
        mstore(add(headStart, 64), "Error in proposal type")
        tail := add(headStart, 96)
    }
}