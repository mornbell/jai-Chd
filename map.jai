#scope_export

Entry::struct(K:Type,V:Type){
    key:K;
    value:V;
}

Map::struct(N:int,K:Type,V:Type){
    hash_key:u64;
    sigmas:[#run bucket_count(N,DEFAULT_LAMBDA)]u64;
    entries:[N]Entry(K,V);
}

init::(entries:[$N]Entry($K,$V))->Map(N,K,V)
{
    chd:Chd(N);
    memset(chd.hashed_entry_index.data,0xff,size_of(int)*N);
    state:=build(*chd,entries);
    map:Map(N,K,V);
    map.hash_key=state.hash_key;
    map.sigmas=state.sigmas;
    for index,i:state.hashed_entry_index{
        map.entries[i] = entries[index];
    }
    return map;
}

lookup::(using map:Map($N,$K,$V),key:K)->V{
    h:=hash(slice(key.data,0,key.count),hash_key);
    using h;
    pilot:=sigmas[g%sigmas.count];
    d0:=pilot/N;
    d1:=pilot%N;
    position:=(h1+h0*d0+d1)%N;
    return entries[position].value;
}


#scope_module

Hash::struct{
    g:u32;
    h0:u32;
    h1:u32;
}

hash::(bytes:[]u8,key:u64)->Hash{
    return .{cast(u32,bytes[0]+key),cast(u32,bytes[0]+key),cast(u32,bytes[0]+key+1)};
}


// 把entries按照 hash值分组，最好情况下不存在hash冲突，最坏情况下只有一个分组
split_into_buckets::(using chd:*Chd(N),entries:[$N]Entry){
    hashes:[N]Hash;
    for entry,index:entries{
        hashes[index]=hash(slice(entry.key.data,0,entry.key.count),hash_key);
    }
    counter:[BUCKET_COUNT]int;
    for hash:hashes{
        counter[hash.g % buckets.count]+=1;
    }
    for index:0..BUCKET_COUNT-1{
        if index==0 continue;
        buckets[index].start=counter[index-1]+buckets[index-1].start;
        buckets[index].index=index;
    }
    for hash,index: hashes{
        bucket:=*buckets[hash.g % buckets.count];
        buffer[bucket.start+bucket.len]=.{hash.h0,hash.h1,index};
        bucket.len+=1;
    }
}

displace::(using chd:*Chd($N))->bool{
    this_bucket_hashed_entry_index:[N]int;
    occupied:[N]u64;
    memset(occupied.data,0xff,size_of(u64)*N);
    for bucket:buckets{
        for d0:0..N-1{
            for  d1:0..N-1{
                memset(this_bucket_hashed_entry_index.data,0xff,size_of(int)*this_bucket_hashed_entry_index.count);
                pilot:=cast(u64,d0*N+d1);
                for key,index:slice(buffer.data,bucket.start,bucket.start+bucket.len){
                    using key;
                    position:=(h1+h0*d0+d1)%N;
                    if hashed_entry_index[position]!=EMPTY_SLOT||occupied[position]==pilot continue d1;
                    occupied[position]=pilot;
                    this_bucket_hashed_entry_index[position]=entry_index;
                }
                // 解决了这个bucket的hash冲突
                for entry_index,index:this_bucket_hashed_entry_index{
                    // map[index]=entries[entry_index];
                    if entry_index==EMPTY_SLOT continue;
                    hashed_entry_index[index]=entry_index;
                }
                // 计算出的完美哈希函数的参数
                sigmas[bucket.index]=pilot;
                continue bucket;
            }
        }
        return false;
    }
    return true;
}

compress::(){

}

bucket_count::(n:int,lambda:int)->int #expand{
    return (n+lambda-1)/lambda;
}


cnt:u64=0;

Hash_State::struct(N:int){
    hash_key:u64;
    sigmas:[#run bucket_count(N,DEFAULT_LAMBDA)]u64;
    hashed_entry_index:[N]int;
}

random::()->u64{
    cnt+=1;
    return cnt;
}

build::(using chd:*Chd(N),entries:[$N]Entry)->Hash_State(N)
{
    while true{
        hash_key=random();
        split_into_buckets(chd,entries);
        quick_sort(buckets,(a,b)=>a.len-b.len);
        if displace(chd){
            return .{ hash_key,sigmas, hashed_entry_index};
        }
        memset(chd,0,size_of(Chd(N)));
    }
}

Chd::struct(N:int){
    hash_key:u64; // 随机数,单次爆破失败的时候重置所有hash值
    // 所有buckets存放的数据连续存储，值为hash计算的结果
    buffer:[N] struct{
        h0:u32;
        h1:u32;
        entry_index:int;
    };
    BUCKET_COUNT:int:#run bucket_count(N,DEFAULT_LAMBDA);
    // 记录每个buckets在buffer中的位置信息
    buckets:[BUCKET_COUNT] struct{
        index:int;
        start:int;
        len:int;
    };
    // 计算每个buckets的完美哈希函数需要的值
    sigmas:[BUCKET_COUNT]u64;
    hashed_entry_index:[N]int;
}

slice :: (ptr:*$T,start:int,end:int)->[]T{
    result:[]T;
    result.data=ptr+start;
    result.count=end-start;
    return result;
}


EMPTY_SLOT:int:0xffff_ffff_ffff_ffff;
DEFAULT_LAMBDA: int : 3;

#import "Sort";
#import "Basic";
#import,dir "hash";
#import "Compiler";