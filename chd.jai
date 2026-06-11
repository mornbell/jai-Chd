#scope_module;
Chd::struct(N:s64){
    hash_key:u64; // random hash key used by siphash
    // continues bucket data
    buffer:[N] struct{
        h0:u32;
        h1:u32;
        key_index:s64;
    };
    BUCKET_COUNT::#run bucket_count(N);
    buckets:[BUCKET_COUNT] struct{
        index:s64; // original index (buckets will be sorted by len)
        start:s64;
        len:s64;
    };
    seeds:[BUCKET_COUNT]u64;
    hashed_key_index:[N]s64; // ith key's index
}

// perfect hash function params
Hash_State::struct(N:s64){
    hash_key:u64;
    seeds:[#run bucket_count(N)]u64;
    hashed_key_index:[N]s64;
}

build::(using chd:*Chd(N),keys:[$N]$K)->Hash_State(N)
{
    #if DEBUG check_duplicate(keys);
    while true{
        hash_key=random();
        split_into_buckets(chd,keys);
        quick_sort(buckets,(a,b)=>b.len-a.len);
        if displace(chd){
            return .{ hash_key,seeds, hashed_key_index};
        }
        memset(chd,0,size_of(Chd(N)));
    }
    return .{};
}

bucket_count::(n:s64)->s64 #expand{
    return (n+DEFAULT_LAMBDA-1)/DEFAULT_LAMBDA;
}

Hash::struct{
    g:u32;
    h0:u32;
    h1:u32;
}

hash::(x:$X,k:u64)->Hash{
    hasher:SipHash=init(0,k);
    h:=hash(*hasher,x);
    return .{
              g=cast(u32,h.low>>32),
              h0=cast,trunc(u32,h.low),
              h1=cast,trunc(u32,h.high),
            };
}

#scope_file;

check_duplicate::(keys:[$N]$K){
    for i:0..N-1 for j:i+1..N-1{
        if keys[i]==keys[j] {
            print("Duplicate key '%' found at index % and %.\n",keys[i],i,j);
            exit(1);
        }
    }
}

split_into_buckets::(using chd:*Chd(N),keys:[$N]$K){
    hashes:[N]Hash;
    for key,index:keys{
        hashes[index]=hash(key,hash_key);
    }

    // caculate bucket length, so we can caculate bucket[i].start=sum(bucket[0].len+...bucket[i-1].len)
    counter:[BUCKET_COUNT]s64;
    for hash:hashes{
        counter[hash.g % buckets.count]+=1;
    }
    // caculate bucket.start
    for index:0..BUCKET_COUNT-1{
        if index==0 continue;
        buckets[index].start=counter[index-1]+buckets[index-1].start;
        buckets[index].index=index;
    }
    // fill bucket from bucket.start
    for hash,index: hashes{
        bucket:=*buckets[hash.g % buckets.count];
        buffer[bucket.start+bucket.len]=.{hash.h0,hash.h1,index};
        bucket.len+=1;
    }
}

// before we have splited entries into different buckets,
// here we search for d0,d1,make position=(h1+h0*d0+d1)%n unique from all entries.
// h0,h1 are hashes we caculated before, d0,d1 are numbers we search (one by one).
displace::(using chd:*Chd($N))->bool{
    this_bucket_hashed_key_index:[N]s64;
    occupied:[N]u64;
    memset(occupied.data,0xff,size_of(u64)*N);
    memset(hashed_key_index.data,0xff,size_of(s64)*N);

    for bucket:buckets{
        for d0:0..N-1 for d1:0..N-1{
            memset(this_bucket_hashed_key_index.data,0xff,size_of(s64)*this_bucket_hashed_key_index.count);

            pilot:=cast(u64,d0*N+d1);
            for key,index:array_view(buffer,bucket.start,bucket.start+bucket.len){
                using key;
                position:=(h1+h0*d0+d1)%N;
                if hashed_key_index[position]!=EMPTY_SLOT||occupied[position]==pilot continue d1;

                occupied[position]=pilot;
                this_bucket_hashed_key_index[position]=key_index;
            }
            // merge this bucket result
            for key_index,index:this_bucket_hashed_key_index{
                if key_index==EMPTY_SLOT continue;
                hashed_key_index[index]=key_index;
            }
            seeds[bucket.index]=pilot;
            continue bucket;
        }
        // failed to find perfect hash function
        return false;
    }
    return true;
}

// TODO
compress::(chd:*Chd){
   // 计算最大的sigma的bit位数n,使用n-bit存储，共占用n*bucket_count bit.
}


EMPTY_SLOT:s64:0xffff_ffff_ffff_ffff;
DEFAULT_LAMBDA: s64 : 3; // average bucket size

cnt:u64=0;
random::()->u64{
    cnt+=1;
    return cnt;
}

#import "Sort";
#import "Basic";
#import,file "siphash.jai";