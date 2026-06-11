#module_parameters(DEBUG:=false);
#scope_export

Entry::struct(K:Type,V:Type){
    key:K;
    value:V;
}

Map::struct(N:s64,K:Type,V:Type){
    hash_key:u64;
    seeds:[#run bucket_count(N)]u64;
    entries:[N]Entry(K,V);
}

init::(entries:[$N]Entry($K,$V))->Map(N,K,V)
{
    chd:Chd(N);
    keys:[N]K;
    for entry,index:entries keys[index]=entry.key;
    state:=build(*chd,keys);

    map:Map(N,K,V);
    map.hash_key=state.hash_key;
    map.seeds=state.seeds;
    for index,i:state.hashed_key_index{
        map.entries[i] = entries[index];
    }
    return map;
}

lookup::(using map:Map($N,$K,$V),key:K)->found:bool,value:V{
    h:=hash(key,hash_key);
    using h;
    pilot:=seeds[g%seeds.count];
    d0:=pilot/N;
    d1:=pilot%N;
    position:=(h1+h0*d0+d1)%N;
    entry:=entries[position];
    if entry.key!=key {
        dummy:V=---;
        return false,dummy;
    }
    return true,entry.value;
}

#scope_module
#load "chd.jai";