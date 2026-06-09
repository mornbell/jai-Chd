#import,file "module.jai";

map::#run init( Entry(string,int).[
                    .{"a",1},
                    .{"b",2},
                    .{"c",3},
                    .{"d",4},
                    .{"e",5},
                    .{"f",6},
                    .{"g",7},
                    .{"h",8},
                    .{"j",9},
                    .{"k",0},
                    .{"1",256},
                ]);

main::(){
    print("map:{sigma:%,entries:%}\n%\n",map.sigmas,map.entries,type_of(map));
    print("lookup 'a':%\n",lookup(map,"a"));
}

#import "Basic";