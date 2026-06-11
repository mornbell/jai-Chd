Token_Type::string;

FUNCTION :Token_Type: "FUNCTION";
LET :Token_Type: "LET";
TRUE :Token_Type : "TRUE";
FALSE :Token_Type : "FALSE";
IF :Token_Type : "IF";
ELSE :Token_Type : "ELSE";
RETURN :Token_Type : "RETURN";

keyword::#run init(Entry(string,Token_Type).[
      .{"let",LET},
      // .{"let",LET} // if DEBUG=true,we will check duplicate keys.
      .{"fn",FUNCTION},
      .{"true",TRUE},
      .{"false",FALSE},
      .{"if",IF},
      .{"else",ELSE},
      .{"return",RETURN}]);


main::(){
    found,value:=lookup(keyword,"let");
    if found{
        print("keyword let: %\n",value);
    }
}

#import "Basic";
#import,file "../module.jai"(DEBUG=true);