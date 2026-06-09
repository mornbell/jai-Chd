#run test();

BUILD_DIRECTORY::"build/";
TEST_ENTRYPOINT::"tests.jai";

test::(){
    make_directory_if_it_does_not_exist(BUILD_DIRECTORY);

    workspace:=compiler_create_workspace();
    options:=get_build_options();
    options.output_path=BUILD_DIRECTORY;
    options.output_executable_name="test";
    options.output_type=.EXECUTABLE;
    set_build_options(options,workspace);
    set_build_options_dc(.{do_output=false});
    add_build_file(TEST_ENTRYPOINT,workspace);
}

#import "Basic";
#import "File";
#import "Compiler";