# 1. Find all the test_*.jac files in the /src/tests directory
files=$(find ./src/tests -name "test_*.jac")

# 2. Loop through each file and run jac test <file_loc>
for file in $files; do
    jac test "$file"
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo "Test failed: $file"
        exit $exit_code
    fi
done