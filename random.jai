#module_parameters(DEBUG:=false);
#scope_export;
// XoShiro256++ impl
Rng::struct{
    s:[4]u32;
}

init::(state:u64)->Rng{
    s:[4]u32;
    PHI : u64 : 0x9e3779b97f4a7c15;
    for *i:s {
        // SplitMix64
        state += PHI;
        z := state;
        z = (z ^ (z >> 30)) * 0xbf58476d1ce4e5b9;
        z = (z ^ (z >> 27)) * 0x94d049bb133111eb;
        z = z ^ (z >> 31);
        i.* = cast,trunc(u32) z;
    }
    return .{s};
}


random::(using rng:*Rng)->u64{
	result := rotate_left(cast(u64) (s[0] + s[3]), 23) + cast(u64) s[0];
	t := s[1] << 17;

	s[2] ^= s[0];
	s[3] ^= s[1];
	s[1] ^= s[2];
	s[0] ^= s[3];

	s[2] ^= t;
	s[3] = cast(u32) rotate_left(cast(u64) s[3], 45);

	return result;
}

#scope_module;
rotate_left::(x:u64,n:u8)->u64 #expand{
    return (x<<(64-n)|x>>n);
}

#import "Basic";