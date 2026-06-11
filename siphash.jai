#module_parameters(C:=1,D:=3);
#scope_export
SipHash::struct{
  k0:u64;
  k1:u64;
  state:State;
  length:s64;
  tail:u64;
  ntail:s64;
}

init::(k0:u64,k1:u64)->SipHash{
    h:SipHash=.{
        k0=k0, k1=k1,
        length=0,tail=0,ntail=0,
    };
    reset(*h);
    return h;
}

init::(keys:[16]u8)->SipHash{
  k0:=load_le(array_view(keys,0,8));
  k1:=load_le(array_view(keys,8,16));
  return init(k0,k1);
}

reset::(using h:*SipHash){
    using state;
    v0 = 0x736f6d6570736575 ^ k0;
    v1 = 0x646f72616e646f6d ^ k1;
    v2 = 0x6c7967656e657261 ^ k0;
    v3 = 0x7465646279746573 ^ k1;
    length=0;
    tail=0;
    ntail=0;
}

hash::(h:*SipHash,x:$X)->U128
#modify{
    info := cast (*Type_Info) X;
	return info.type == .INTEGER;
}
{
    write_integer(h, X ,x);
    return finish(h);
}

hash::(h:*SipHash,x:string)->U128
{
    write_str(h,x);
    return finish(h);
}

hash::(h:*SipHash,x:[]u8)->U128
{
    write(h,x);
    return finish(h);
}

write::(using h:*SipHash,msg:[]u8){
    using state;
    length+=msg.count;
    index:=0;
    if ntail!=0{
       tail|=tail<<(64-ntail)|load_le(array_view(msg,0,64-ntail));
       if msg.count<64-ntail{
           ntail+=msg.count;
           return;
       }
       index+=64-ntail;
    }
    ntail=length%8;
    end:=length-ntail;
    while index<end{
      defer index+=8;
      m:=load_le(array_view(msg,index,index+8));
      v3^=m;
      c_rounds(*state,2);
      v0^=m;
    }
    tail=load_le(array_view(msg,index));
}

finish::(using h:*SipHash)->U128{
    using state;
    tail|=cast(u64,length)<<56;
    v3^=tail;
    c_rounds(*state,C);
    v0^=tail;

    v2^=0xff;
    d_rounds(*state,D);
    return .{high=v0^v1,low=v2^v3};
}

write_integer::(h:*SipHash,$T:Type,i:T){
    bytes:[size_of(T)]u8;
    memcpy(bytes.data,*i,size_of(T));
    write(h,bytes);
}

write_u8::#bake_arguments write_integer(T=u8);
write_s8::#bake_arguments write_integer(T=s8);
write_u16::#bake_arguments write_integer(T=u16);
write_s16::#bake_arguments write_integer(T=s16);
write_u32::#bake_arguments write_integer(T=u32);
write_s32::#bake_arguments write_integer(T=s32);
write_u64::#bake_arguments write_integer(T=u64);
write_s64::#bake_arguments write_integer(T=s64);
write_int::#bake_arguments write_integer(T=int);

write_str::(h:*SipHash,s:string){
    write(h,cast([]u8,s));
}


#scope_file;

State::struct{
  v0:u64;
  v1:u64;
  v2:u64;
  v3:u64;
}

c_rounds::(state:*State,N:s64) #expand{
    for 0..N-1{
      sipround(state);
    }
}

d_rounds::(state:*State,N:s64) #expand{
    for 0..N-1{
      sipround(state);
    }
}

sipround::(using state:*State) #expand{
  v0+=v1; v1=rotate_left(v1,13); v1^=v0; v0=rotate_left(v0,32);
  v2+=v3; v3=rotate_left(v3,16); v3^=v2;
  v0+=v3; v3=rotate_left(v3,21); v3^=v0;
  v2+=v1; v1=rotate_left(v1,17); v1^=v2; v2=rotate_left(v2,32);
}

rotate_left::(x:u64,n:u8) -> u64 #expand{
  return (x<<n) | (x>> (64-n));
}

load_le::(bytes:[]u8)->u64 #expand{
  result:u64=0;
  for i:0..7{
    byte:u64=ifx i<bytes.count then cast(u64,bytes[i]) else 0;
    result|=(byte<<(8*i));
  }
  return result;
}

#import "Basic";
